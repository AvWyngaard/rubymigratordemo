require 'spec_helper'
require 'migrator'
require 'tempfile'

RSpec.describe Migrator do
  let(:migrator) { Migrator.new }
  let(:test_file) { Tempfile.new(['test_patients', '.csv']) }
  
  after do
    test_file.close
    test_file.unlink
  end
  
  describe '#migrate' do
    context 'with valid data' do
      it 'successfully completes migration workflow' do
        create_test_csv(test_file.path, [valid_patient_record])
        
        result = migrator.migrate(test_file.path)
        
        expect(result[:success]).to be true
        expect(result[:s3_key]).to match(/migrations\/test_patients_\d+\.json/)
        expect(result[:stats][:records_processed]).to eq(1)
        expect(result[:stats][:records_validated]).to eq(1)
      end
      
      it 'processes multiple records' do
        records = [
          valid_patient_record,
          valid_patient_record.merge('patient_id' => 'PAT67890', 'email' => 'jane@example.com'),
          valid_patient_record.merge('patient_id' => 'PAT99999', 'email' => 'bob@example.com')
        ]
        create_test_csv(test_file.path, records)
        
        result = migrator.migrate(test_file.path)
        
        expect(result[:success]).to be true
        expect(result[:stats][:records_processed]).to eq(3)
        expect(result[:stats][:records_validated]).to eq(3)
      end
      
      it 'calculates migration duration' do
        create_test_csv(test_file.path, [valid_patient_record])
        
        result = migrator.migrate(test_file.path)
        
        expect(result[:stats][:start_time]).to be_a(Time)
        expect(result[:stats][:end_time]).to be_a(Time)
        expect(result[:stats][:end_time]).to be > result[:stats][:start_time]
      end
    end
    
    context 'with invalid data' do
      it 'fails when validation errors exist' do
        invalid_record = valid_patient_record.merge('email' => 'invalid-email')
        create_test_csv(test_file.path, [invalid_record])
        
        result = migrator.migrate(test_file.path)
        
        expect(result[:success]).to be false
        expect(result[:error]).to eq('Validation failed')
        expect(result[:stats][:records_failed]).to be > 0
      end
      
      it 'fails when source file does not exist' do
        result = migrator.migrate('/nonexistent/file.csv')
        
        expect(result[:success]).to be false
      end
    end
    
    context 'with database import option' do
      it 'imports data when option is enabled' do
        create_test_csv(test_file.path, [valid_patient_record])
        
        result = migrator.migrate(test_file.path, import_to_db: true)
        
        expect(result[:success]).to be true
      end
    end
  end
  
  describe 'migration statistics' do
    it 'tracks all relevant statistics' do
      records = [valid_patient_record, valid_patient_record.merge('patient_id' => 'PAT67890')]
      create_test_csv(test_file.path, records)
      
      result = migrator.migrate(test_file.path)
      stats = result[:stats]
      
      expect(stats).to include(
        :records_processed,
        :records_validated,
        :records_failed,
        :start_time,
        :end_time
      )
    end
  end
  
  describe 'error handling' do
    it 'handles exceptions gracefully' do
      # Create a file with permission issues
      restricted_file = '/root/restricted.csv'
      
      result = migrator.migrate(restricted_file)
      
      expect(result[:success]).to be false
      expect(result[:error]).to be_a(String)
    end
  end
end