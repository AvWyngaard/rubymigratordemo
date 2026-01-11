require 'csv'
require 'json'
require 'logger'

# Adapter for handling legacy or non-standard data formats
# Demonstrates ability to work with various source systems
class LegacyAdapter
  attr_reader :logger

  def initialize(options = {})
    @logger = options[:logger] || Logger.new(STDOUT)
    @source_type = options[:source_type] || 'unknown'
  end

  # Detect and adapt legacy formats
  def adapt(source_file)
    @logger.info("Adapting legacy format: #{@source_type}")

    case @source_type
    when 'emis'
      adapt_emis_format(source_file)
    when 'systmone'
      adapt_systmone_format(source_file)
    when 'vision'
      adapt_vision_format(source_file)
    else
      adapt_generic_format(source_file)
    end
  end

  private

  # Adapt EMIS Web format
  def adapt_emis_format(source_file)
    records = []
    
    CSV.foreach(source_file, headers: true, col_sep: '|') do |row|
      records << {
        'patient_id' => row['PatientGUID'],
        'first_name' => row['Forename'],
        'last_name' => row['Surname'],
        'email' => row['EmailAddress'],
        'phone' => row['TelephoneNumber'],
        'date_of_birth' => parse_emis_date(row['DOB']),
        'nhs_number' => row['NHSNumber'],
        'address_street' => "#{row['AddressLine1']}, #{row['AddressLine2']}".strip,
        'address_city' => row['Town'],
        'address_postcode' => row['Postcode'],
        'source_system' => 'EMIS'
      }
    end

    records
  end

  # Adapt SystmOne format
  def adapt_systmone_format(source_file)
    records = []
    
    CSV.foreach(source_file, headers: true) do |row|
      records << {
        'patient_id' => row['PatientID'],
        'first_name' => row['FirstName'],
        'last_name' => row['LastName'],
        'email' => row['Email'],
        'phone' => normalize_systmone_phone(row['Phone']),
        'date_of_birth' => parse_systmone_date(row['DateOfBirth']),
        'nhs_number' => row['NHSNo'],
        'address_street' => row['Address'],
        'address_city' => row['City'],
        'address_postcode' => row['PostCode'],
        'source_system' => 'SystmOne'
      }
    end

    records
  end

  # Adapt Vision format
  def adapt_vision_format(source_file)
    records = []
    
    # Vision often uses fixed-width format
    File.readlines(source_file).each_with_index do |line, index|
      next if index == 0 # Skip header
      
      records << {
        'patient_id' => line[0, 10].strip,
        'first_name' => line[10, 20].strip,
        'last_name' => line[30, 20].strip,
        'date_of_birth' => parse_vision_date(line[50, 8]),
        'nhs_number' => line[58, 10].strip,
        'source_system' => 'Vision'
      }
    end

    records
  end

  # Generic CSV adapter
  def adapt_generic_format(source_file)
    CSV.read(source_file, headers: true)
  end

  # Date parsing helpers for different formats
  def parse_emis_date(date_str)
    # EMIS uses DD/MM/YYYY
    return nil if date_str.nil? || date_str.strip.empty?
    
    parts = date_str.split('/')
    "#{parts[2]}-#{parts[1]}-#{parts[0]}"
  rescue
    nil
  end

  def parse_systmone_date(date_str)
    # SystmOne uses DD-MM-YYYY
    return nil if date_str.nil? || date_str.strip.empty?
    
    parts = date_str.split('-')
    "#{parts[2]}-#{parts[1]}-#{parts[0]}"
  rescue
    nil
  end

  def parse_vision_date(date_str)
    # Vision uses DDMMYYYY
    return nil if date_str.nil? || date_str.strip.empty?
    
    "#{date_str[4, 4]}-#{date_str[2, 2]}-#{date_str[0, 2]}"
  rescue
    nil
  end

  def normalize_systmone_phone(phone)
    # SystmOne sometimes includes extensions
    return nil if phone.nil?
    
    phone.split('x').first.strip
  end
end