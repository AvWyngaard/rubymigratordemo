require 'spec_helper'
require 'transformers/csv_to_json'

RSpec.describe CsvToJsonTransformer do
  let(:transformer) { CsvToJsonTransformer.new }
  
  describe '#transform_record' do
    it 'transforms CSV record to structured JSON' do
      record = valid_patient_record
      result = transformer.transform_record(record)
      
      expect(result).to be_a(Hash)
      expect(result).to have_key(:patient_id)
      expect(result).to have_key(:personal_info)
      expect(result).to have_key(:contact_info)
      expect(result).to have_key(:medical_info)
      expect(result).to have_key(:metadata)
    end
    
    it 'structures personal information correctly' do
      record = valid_patient_record
      result = transformer.transform_record(record)
      
      expect(result[:personal_info][:first_name]).to eq('John')
      expect(result[:personal_info][:last_name]).to eq('Smith')
      expect(result[:personal_info][:date_of_birth]).to eq('1980-05-15')
    end
    
    it 'structures contact information correctly' do
      record = valid_patient_record
      result = transformer.transform_record(record)
      
      expect(result[:contact_info][:email]).to eq('john.smith@example.com')
      expect(result[:contact_info][:address][:city]).to eq('London')
      expect(result[:contact_info][:address][:postcode]).to eq('SW1A 1AA')
    end
    
    it 'adds migration metadata' do
      record = valid_patient_record
      result = transformer.transform_record(record)
      
      expect(result[:metadata][:migrated_at]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
      expect(result[:metadata][:migration_batch]).to match(/BATCH_\d{8}_\d{6}/)
    end
  end
  
  describe 'data cleaning' do
    it 'trims whitespace from strings' do
      record = valid_patient_record.merge('first_name' => '  John  ')
      result = transformer.transform_record(record)
      
      expect(result[:personal_info][:first_name]).to eq('John')
    end
    
    it 'converts email to lowercase' do
      record = valid_patient_record.merge('email' => 'John.Smith@EXAMPLE.COM')
      result = transformer.transform_record(record)
      
      expect(result[:contact_info][:email]).to eq('john.smith@example.com')
    end
    
    it 'normalizes phone numbers' do
      record = valid_patient_record.merge('phone' => '07700 900 123')
      result = transformer.transform_record(record)
      
      expect(result[:contact_info][:phone]).to eq('+447700900123')
    end
    
    it 'handles nil values correctly' do
      record = valid_patient_record.merge('phone' => nil)
      result = transformer.transform_record(record)
      
      expect(result[:contact_info][:phone]).to be_nil
    end
    
    it 'handles empty strings as nil' do
      record = valid_patient_record.merge('phone' => '   ')
      result = transformer.transform_record(record)
      
      expect(result[:contact_info][:phone]).to be_nil
    end
  end
  
  describe 'list parsing' do
    it 'parses comma-separated allergies' do
      record = valid_patient_record.merge('allergies' => 'Penicillin, Peanuts, Shellfish')
      result = transformer.transform_record(record)
      
      expect(result[:medical_info][:allergies]).to eq(['Penicillin', 'Peanuts', 'Shellfish'])
    end
    
    it 'handles empty lists' do
      record = valid_patient_record.merge('allergies' => '')
      result = transformer.transform_record(record)
      
      expect(result[:medical_info][:allergies]).to eq([])
    end
    
    it 'parses comma-separated medications' do
      record = valid_patient_record.merge('medications' => 'Aspirin, Ibuprofen')
      result = transformer.transform_record(record)
      
      expect(result[:medical_info][:medications]).to eq(['Aspirin', 'Ibuprofen'])
    end
  end
  
  describe '#transform' do
    it 'transforms array of CSV records' do
      records = [
        valid_patient_record,
        valid_patient_record.merge('patient_id' => 'PAT67890')
      ]
      
      csv_records = CSV::Table.new(records.map { |r| CSV::Row.new(r.keys, r.values) })
      result = transformer.transform(csv_records)
      
      expect(result).to be_an(Array)
      expect(result.length).to eq(2)
      expect(result[0][:patient_id]).to eq('PAT12345')
      expect(result[1][:patient_id]).to eq('PAT67890')
    end
    
    it 'handles transformation errors gracefully' do
      # Simulating a scenario that might cause errors
      invalid_records = nil
      result = transformer.transform(invalid_records)
      
      expect(result).to be_nil
    end
  end
end