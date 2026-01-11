require 'spec_helper'
require 'validator'

RSpec.describe Validator do
  let(:validator) { Validator.new }
  
  describe '#validate_record' do
    context 'with valid record' do
      it 'returns no errors for a complete valid record' do
        record = valid_patient_record
        errors = validator.validate_record(record)
        
        expect(errors).to be_empty
      end
    end
    
    context 'with missing required fields' do
      it 'returns error for missing patient_id' do
        record = valid_patient_record.merge('patient_id' => '')
        errors = validator.validate_record(record, 1)
        
        expect(errors).to include(/Missing required field 'patient_id'/)
      end
      
      it 'returns error for missing first_name' do
        record = valid_patient_record.merge('first_name' => nil)
        errors = validator.validate_record(record, 1)
        
        expect(errors).to include(/Missing required field 'first_name'/)
      end
      
      it 'returns error for missing email' do
        record = valid_patient_record.merge('email' => '   ')
        errors = validator.validate_record(record, 1)
        
        expect(errors).to include(/Missing required field 'email'/)
      end
    end
    
    context 'with invalid email format' do
      it 'returns error for invalid email' do
        record = valid_patient_record.merge('email' => 'not-an-email')
        errors = validator.validate_record(record, 1)
        
        expect(errors).to include(/Invalid email format/)
      end
      
      it 'accepts valid email formats' do
        valid_emails = [
          'user@example.com',
          'user.name@example.co.uk',
          'user+tag@example.com'
        ]
        
        valid_emails.each do |email|
          record = valid_patient_record.merge('email' => email)
          errors = validator.validate_record(record)
          
          expect(errors).to be_empty, "Expected #{email} to be valid"
        end
      end
    end
    
    context 'with invalid phone format' do
      it 'returns error for invalid phone' do
        record = valid_patient_record.merge('phone' => '123')
        errors = validator.validate_record(record, 1)
        
        expect(errors).to include(/Invalid phone format/)
      end
      
      it 'accepts valid UK phone formats' do
        valid_phones = [
          '07700900123',
          '+44 7700 900123',
          '(0770) 090-0123',
          '0207 123 4567'
        ]
        
        valid_phones.each do |phone|
          record = valid_patient_record.merge('phone' => phone)
          errors = validator.validate_record(record)
          
          expect(errors).to be_empty, "Expected #{phone} to be valid"
        end
      end
    end
    
    context 'with invalid date format' do
      it 'returns error for wrong date format' do
        record = valid_patient_record.merge('date_of_birth' => '15/05/1980')
        errors = validator.validate_record(record, 1)
        
        expect(errors).to include(/Invalid date format/)
      end
      
      it 'returns error for invalid date' do
        record = valid_patient_record.merge('date_of_birth' => '2024-13-45')
        errors = validator.validate_record(record, 1)
        
        expect(errors).to include(/Invalid date format/)
      end
    end
    
    context 'with invalid age range' do
      it 'returns error for future date of birth' do
        record = valid_patient_record.merge('date_of_birth' => '2030-01-01')
        errors = validator.validate_record(record, 1)
        
        expect(errors).to include(/invalid age/)
      end
      
      it 'returns error for age over 120' do
        record = valid_patient_record.merge('date_of_birth' => '1850-01-01')
        errors = validator.validate_record(record, 1)
        
        expect(errors).to include(/invalid age/)
      end
    end
    
    context 'with invalid patient_id format' do
      it 'returns error for short patient_id' do
        record = valid_patient_record.merge('patient_id' => 'ABC')
        errors = validator.validate_record(record, 1)
        
        expect(errors).to include(/Invalid patient_id format/)
      end
      
      it 'returns error for patient_id with special characters' do
        record = valid_patient_record.merge('patient_id' => 'PAT-12345')
        errors = validator.validate_record(record, 1)
        
        expect(errors).to include(/Invalid patient_id format/)
      end
    end
  end
  
  describe '#validate_records' do
    it 'validates multiple records and collects all errors' do
      records = [
        valid_patient_record,
        valid_patient_record.merge('email' => 'invalid'),
        valid_patient_record.merge('patient_id' => '')
      ]
      
      csv_records = CSV::Table.new(records.map { |r| CSV::Row.new(r.keys, r.values) })
      errors = validator.validate_records(csv_records)
      
      expect(errors.length).to eq(2)
      expect(errors[0]).to include('Row 3')
      expect(errors[1]).to include('Row 4')
    end
    
    it 'returns empty array for all valid records' do
      records = [
        valid_patient_record,
        valid_patient_record.merge('patient_id' => 'PAT67890'),
        valid_patient_record.merge('patient_id' => 'PAT11111')
      ]
      
      csv_records = CSV::Table.new(records.map { |r| CSV::Row.new(r.keys, r.values) })
      errors = validator.validate_records(csv_records)
      
      expect(errors).to be_empty
    end
  end
end