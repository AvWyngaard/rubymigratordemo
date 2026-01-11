require 'csv'
require 'json'
require 'logger'

# Transforms CSV data to structured JSON format
class CsvToJsonTransformer
  attr_reader :logger

  def initialize(options = {})
    @logger = options[:logger] || Logger.new(STDOUT)
  end

  # Transform CSV records to JSON array
  def transform(records)
    begin
      transformed = records.map do |record|
        transform_record(record)
      end

      transformed.compact # Remove any nil records
    rescue StandardError => e
      @logger.error("Transformation error: #{e.message}")
      nil
    end
  end

  # Transform a single record with data cleaning
  def transform_record(record)
    {
      patient_id: clean_string(record['patient_id']),
      personal_info: {
        first_name: clean_string(record['first_name']),
        last_name: clean_string(record['last_name']),
        date_of_birth: clean_string(record['date_of_birth']),
        gender: clean_string(record['gender'])
      },
      contact_info: {
        email: clean_email(record['email']),
        phone: clean_phone(record['phone']),
        address: {
          street: clean_string(record['address_street']),
          city: clean_string(record['address_city']),
          postcode: clean_string(record['address_postcode']),
          country: clean_string(record['address_country']) || 'UK'
        }
      },
      medical_info: {
        nhs_number: clean_string(record['nhs_number']),
        allergies: parse_list(record['allergies']),
        medications: parse_list(record['medications'])
      },
      metadata: {
        source_system: clean_string(record['source_system']) || 'legacy',
        migrated_at: Time.now.iso8601,
        migration_batch: generate_batch_id
      }
    }
  end

  private

  # Clean string fields: trim, handle nulls
  def clean_string(value)
    return nil if value.nil? || value.to_s.strip.empty?
    value.to_s.strip
  end

  # Clean and normalize email
  def clean_email(email)
    return nil if email.nil? || email.to_s.strip.empty?
    email.to_s.strip.downcase
  end

  # Clean and normalize phone number
  def clean_phone(phone)
    return nil if phone.nil? || phone.to_s.strip.empty?
    
    # Remove common formatting characters
    cleaned = phone.to_s.gsub(/[\s\-\(\)\.]/, '')
    
    # Add UK country code if not present
    cleaned = "+44#{cleaned}" if cleaned.match?(/\A0\d{10}\z/)
    
    cleaned
  end

  # Parse comma-separated lists
  def parse_list(value)
    return [] if value.nil? || value.to_s.strip.empty?
    
    value.to_s.split(',').map(&:strip).reject(&:empty?)
  end

  # Generate unique batch ID
  def generate_batch_id
    "BATCH_#{Time.now.strftime('%Y%m%d_%H%M%S')}"
  end
end