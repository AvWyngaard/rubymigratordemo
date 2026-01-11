require 'csv'
require 'logger'

# Validates healthcare data records
class Validator
  REQUIRED_FIELDS = %w[patient_id first_name last_name email date_of_birth].freeze
  EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
  PHONE_REGEX = /\A(\+\d{1,3}[-.\s]?)?\(?\d{3}\)?[-.\s]?\d{3}[-.\s]?\d{4}\z/
  DATE_FORMAT = /\A\d{4}-\d{2}-\d{2}\z/

  attr_reader :logger

  def initialize(options = {})
    @logger = options[:logger] || Logger.new(STDOUT)
  end

  # Validate a collection of records
  def validate_records(records)
    errors = []
    
    records.each_with_index do |record, index|
      record_errors = validate_record(record, index + 2) # +2 for header and 1-based
      errors.concat(record_errors)
    end

    errors
  end

  # Validate a single record
  def validate_record(record, row_number = nil)
    errors = []
    prefix = row_number ? "Row #{row_number}" : "Record"

    # Check required fields
    REQUIRED_FIELDS.each do |field|
      if record[field].nil? || record[field].to_s.strip.empty?
        errors << "#{prefix}: Missing required field '#{field}'"
      end
    end

    # Validate email format
    if record['email'] && !valid_email?(record['email'])
      errors << "#{prefix}: Invalid email format '#{record['email']}'"
    end

    # Validate phone number format (if present)
    if record['phone'] && !record['phone'].to_s.strip.empty? && !valid_phone?(record['phone'])
      errors << "#{prefix}: Invalid phone format '#{record['phone']}'"
    end

    # Validate date of birth
    if record['date_of_birth'] && !valid_date?(record['date_of_birth'])
      errors << "#{prefix}: Invalid date format '#{record['date_of_birth']}' (expected YYYY-MM-DD)"
    end

    # Validate age range (if DOB is valid)
    if record['date_of_birth'] && valid_date?(record['date_of_birth'])
      unless valid_age_range?(record['date_of_birth'])
        errors << "#{prefix}: Date of birth results in invalid age"
      end
    end

    # Validate patient_id format
    if record['patient_id'] && !valid_patient_id?(record['patient_id'])
      errors << "#{prefix}: Invalid patient_id format '#{record['patient_id']}'"
    end

    errors
  end

  private

  def valid_email?(email)
    email.to_s.strip.match?(EMAIL_REGEX)
  end

  def valid_phone?(phone)
    phone.to_s.strip.match?(PHONE_REGEX)
  end

  def valid_date?(date_string)
    return false unless date_string.to_s.match?(DATE_FORMAT)
    
    begin
      Date.parse(date_string)
      true
    rescue ArgumentError
      false
    end
  end

  def valid_age_range?(date_of_birth)
    begin
      dob = Date.parse(date_of_birth)
      age = ((Date.today - dob) / 365.25).to_i
      age >= 0 && age <= 120
    rescue ArgumentError
      false
    end
  end

  def valid_patient_id?(patient_id)
    # Patient ID should be alphanumeric and between 5-20 characters
    patient_id.to_s.match?(/\A[A-Z0-9]{5,20}\z/i)
  end
end