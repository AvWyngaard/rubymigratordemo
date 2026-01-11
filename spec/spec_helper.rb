require 'csv'
require 'json'
require 'fileutils'

# Add lib directory to load path
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

RSpec.configure do |config|
  # Use the documentation formatter for detailed output
  config.formatter = :documentation
  
  # Use color in output
  config.color = true
  
  # Run specs in random order to surface order dependencies
  config.order = :random
  
  # Fail fast option
  config.fail_fast = false
  
  # Shared context for test data
  config.before(:suite) do
    # Create test data directories
    FileUtils.mkdir_p('data/input')
    FileUtils.mkdir_p('data/output')
  end
  
  # Clean up after tests
  config.after(:suite) do
    # Optional: clean up test files
  end
end

# Helper method to create test CSV file
def create_test_csv(filename, records)
  CSV.open(filename, 'w') do |csv|
    csv << records.first.keys if records.any?
    records.each do |record|
      csv << record.values
    end
  end
end

# Sample valid patient record
def valid_patient_record
  {
    'patient_id' => 'PAT12345',
    'first_name' => 'John',
    'last_name' => 'Smith',
    'email' => 'john.smith@example.com',
    'phone' => '07700900123',
    'date_of_birth' => '1980-05-15',
    'gender' => 'M',
    'nhs_number' => '1234567890',
    'address_street' => '123 High Street',
    'address_city' => 'London',
    'address_postcode' => 'SW1A 1AA',
    'address_country' => 'UK',
    'allergies' => 'Penicillin, Peanuts',
    'medications' => 'Aspirin'
  }
end

# Sample invalid patient record
def invalid_patient_record
  {
    'patient_id' => '',
    'first_name' => 'Jane',
    'last_name' => '',
    'email' => 'invalid-email',
    'phone' => '123',
    'date_of_birth' => '15-05-1990',
    'gender' => 'F'
  }
end