require 'logger'
require_relative 'validator'
require_relative 'transformers/csv_to_json'
require_relative 'uploaders/s3_uploader'

# Core migration orchestrator
class Migrator
  attr_reader :logger, :stats

  def initialize(options = {})
    @logger = options[:logger] || Logger.new(STDOUT)
    @validator = Validator.new(logger: @logger)
    @transformer = CsvToJsonTransformer.new(logger: @logger)
    @uploader = S3Uploader.new(logger: @logger)
    @stats = {
      records_processed: 0,
      records_validated: 0,
      records_failed: 0,
      start_time: nil,
      end_time: nil
    }
  end

  # Main migration workflow
  def migrate(source_file, options = {})
    @stats[:start_time] = Time.now
    log_info "Starting migration: #{File.basename(source_file)}"
    log_info '=' * 50

    begin
      # Step 1: Validate source data
      validation_result = validate_source(source_file)
      return failure_result('Validation failed') unless validation_result[:valid]

      # Step 2: Transform data
      transformed_data = transform_data(source_file, validation_result[:records])
      return failure_result('Transformation failed') if transformed_data.nil?

      # Step 3: Upload to S3
      s3_key = upload_to_s3(transformed_data, source_file)
      return failure_result('Upload failed') if s3_key.nil?

      # Step 4: Import to database (if requested)
      if options[:import_to_db]
        import_result = import_to_database(transformed_data)
        return failure_result('Database import failed') unless import_result
      end

      @stats[:end_time] = Time.now
      success_result(s3_key)

    rescue StandardError => e
      log_error "Migration failed with error: #{e.message}"
      log_error e.backtrace.join("\n")
      failure_result(e.message)
    end
  end

  private

  def validate_source(source_file)
    log_info 'Validating source file...'
    
    unless File.exist?(source_file)
      log_error "Source file not found: #{source_file}"
      return { valid: false }
    end

    records = CSV.read(source_file, headers: true)
    @stats[:records_processed] = records.length

    validation_errors = @validator.validate_records(records)

    if validation_errors.empty?
      @stats[:records_validated] = records.length
      log_success "Validation passed (#{records.length} records)"
      { valid: true, records: records }
    else
      @stats[:records_failed] = validation_errors.length
      log_error "Validation failed with #{validation_errors.length} errors:"
      validation_errors.first(5).each { |err| log_error "  - #{err}" }
      { valid: false, errors: validation_errors }
    end
  end

  def transform_data(source_file, records)
    log_info 'Transforming CSV to JSON...'
    transformed = @transformer.transform(records)
    
    if transformed
      log_success 'Transformation complete'
    else
      log_error 'Transformation failed'
    end
    
    transformed
  end

  def upload_to_s3(data, source_file)
    log_info 'Uploading to S3...'
    
    timestamp = Time.now.strftime('%Y%m%d_%H%M%S')
    base_name = File.basename(source_file, '.*')
    s3_key = "migrations/#{base_name}_#{timestamp}.json"
    
    result = @uploader.upload(data, s3_key)
    
    if result[:success]
      log_success "Uploaded: #{result[:url]}"
      s3_key
    else
      log_error "Upload failed: #{result[:error]}"
      nil
    end
  end

  def import_to_database(data)
    log_info 'Importing to database...'
    # Database import logic would go here
    # For demo purposes, simulating success
    log_success "Imported #{data.length} records"
    true
  end

  def success_result(s3_key)
    duration = @stats[:end_time] - @stats[:start_time]
    log_success "Migration completed successfully in #{duration.round(2)}s!"
    
    {
      success: true,
      s3_key: s3_key,
      stats: @stats
    }
  end

  def failure_result(message)
    @stats[:end_time] = Time.now
    {
      success: false,
      error: message,
      stats: @stats
    }
  end

  def log_info(message)
    @logger.info("[#{timestamp}] #{message}")
  end

  def log_success(message)
    @logger.info("[#{timestamp}] ✓ #{message}")
  end

  def log_error(message)
    @logger.error("[#{timestamp}] ✗ #{message}")
  end

  def timestamp
    Time.now.strftime('%Y-%m-%d %H:%M:%S')
  end
end