# MongoDB Integration Example

This file demonstrates how to add MongoDB support for migrating from NoSQL sources.

## Adding MongoDB Gem

Add to Gemfile:
```ruby
gem 'mongo', '~> 2.19'
```

## MongoDB Adapter Implementation

```ruby
# lib/adapters/mongodb_adapter.rb
require 'mongo'

class MongoDBAdapter
  def initialize(options = {})
    @connection_string = options[:connection_string] || ENV['MONGODB_URI']
    @database_name = options[:database] || 'legacy_system'
    @client = nil
  end

  def connect
    @client = Mongo::Client.new(@connection_string)
    @db = @client.use(@database_name)
  end

  def fetch_patients(query = {}, limit: nil)
    collection = @db[:patients]
    cursor = collection.find(query)
    cursor = cursor.limit(limit) if limit
    
    cursor.map { |doc| normalize_document(doc) }
  end

  def disconnect
    @client.close if @client
  end

  private

  def normalize_document(doc)
    {
      'patient_id' => doc['_id'].to_s,
      'first_name' => doc.dig('name', 'first'),
      'last_name' => doc.dig('name', 'last'),
      'email' => doc.dig('contact', 'email'),
      'phone' => doc.dig('contact', 'phone'),
      'date_of_birth' => format_date(doc['dateOfBirth']),
      'gender' => doc['gender'],
      'nhs_number' => doc['nhsNumber'],
      'address_street' => doc.dig('address', 'street'),
      'address_city' => doc.dig('address', 'city'),
      'address_postcode' => doc.dig('address', 'postcode'),
      'allergies' => doc['allergies']&.join(', '),
      'medications' => doc['medications']&.join(', ')
    }
  end

  def format_date(date)
    case date
    when String
      Date.parse(date).strftime('%Y-%m-%d')
    when Time, DateTime
      date.strftime('%Y-%m-%d')
    when BSON::DateTime
      Time.at(date.to_i).strftime('%Y-%m-%d')
    else
      nil
    end
  rescue
    nil
  end
end
```

## Usage Example

```ruby
# scripts/migrate_from_mongodb.rb
require_relative '../lib/adapters/mongodb_adapter'
require_relative '../lib/migrator'
require 'csv'

# Connect to MongoDB
adapter = MongoDBAdapter.new(
  connection_string: 'mongodb://localhost:27017',
  database: 'legacy_emis'
)

adapter.connect

# Fetch patients
patients = adapter.fetch_patients({}, limit: 1000)

# Write to temporary CSV for processing
temp_file = Tempfile.new(['mongo_export', '.csv'])
CSV.open(temp_file.path, 'w') do |csv|
  csv << patients.first.keys
  patients.each { |p| csv << p.values }
end

# Run migration
migrator = Migrator.new
result = migrator.migrate(temp_file.path)

# Cleanup
temp_file.close
temp_file.unlink
adapter.disconnect

puts "Migration completed: #{result[:success]}"
```

## RSpec Tests for MongoDB Adapter

```ruby
# spec/mongodb_adapter_spec.rb
require 'spec_helper'
require 'adapters/mongodb_adapter'

RSpec.describe MongoDBAdapter do
  let(:adapter) { MongoDBAdapter.new(connection_string: 'mongodb://localhost:27017') }
  
  describe '#normalize_document' do
    it 'converts nested MongoDB document to flat structure' do
      mongo_doc = {
        '_id' => BSON::ObjectId.new,
        'name' => { 'first' => 'John', 'last' => 'Smith' },
        'contact' => { 'email' => 'john@example.com' },
        'dateOfBirth' => Time.new(1980, 5, 15)
      }
      
      result = adapter.send(:normalize_document, mongo_doc)
      
      expect(result['first_name']).to eq('John')
      expect(result['last_name']).to eq('Smith')
      expect(result['date_of_birth']).to eq('1980-05-15')
    end
  end
end
```

## Connecting to Different MongoDB Systems

### EMIS MongoDB
```ruby
adapter = MongoDBAdapter.new(
  connection_string: 'mongodb://emis-server:27017',
  database: 'emis_practice_db'
)
```

### SystmOne MongoDB (if applicable)
```ruby
adapter = MongoDBAdapter.new(
  connection_string: 'mongodb://systmone-server:27017',
  database: 'systmone_data'
)
```

## Incremental Migration

```ruby
# Migrate only recent records
last_migration = Time.new(2024, 1, 1)
query = { 'updatedAt' => { '$gte' => last_migration } }
patients = adapter.fetch_patients(query)
```

## Error Handling

```ruby
begin
  adapter.connect
  patients = adapter.fetch_patients
rescue Mongo::Error::NoServerAvailable => e
  logger.error "MongoDB connection failed: #{e.message}"
  # Implement retry logic or fallback
rescue StandardError => e
  logger.error "Unexpected error: #{e.message}"
ensure
  adapter.disconnect
end
```