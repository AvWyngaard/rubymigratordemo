# Testing Guide

This guide covers how to run and write tests for the data migration project.

## Running Tests

### Run All Tests

```bash
bundle exec rspec
```

### Run Specific Test File

```bash
bundle exec rspec spec/validator_spec.rb
bundle exec rspec spec/migrator_spec.rb
bundle exec rspec spec/transformer_spec.rb
```

### Run Specific Test

```bash
bundle exec rspec spec/validator_spec.rb:10  # Line number
```

### Run with Different Formats

```bash
# Documentation format (detailed)
bundle exec rspec --format documentation

# Progress format (dots)
bundle exec rspec --format progress

# HTML output
bundle exec rspec --format html --out rspec_results.html
```

## Test Coverage

### Current Test Coverage

- **Validator**: Tests for all validation rules including:
  - Required field validation
  - Email format validation
  - Phone number format validation
  - Date format and range validation
  - Patient ID format validation
  
- **Migrator**: Tests for:
  - Complete migration workflow
  - Error handling
  - Statistics tracking
  - File validation
  
- **Transformer**: Tests for:
  - CSV to JSON transformation
  - Data cleaning and normalization
  - List parsing
  - Metadata generation

## Writing New Tests

### Test Structure

```ruby
require 'spec_helper'
require 'your_class'

RSpec.describe YourClass do
  let(:instance) { YourClass.new }
  
  describe '#method_name' do
    context 'when condition A' do
      it 'does something specific' do
        result = instance.method_name(params)
        expect(result).to eq(expected_value)
      end
    end
    
    context 'when condition B' do
      it 'handles edge case' do
        # Test code
      end
    end
  end
end
```

### Best Practices

1. **Use descriptive test names**: Tests should clearly state what they're testing
2. **One assertion per test**: Keep tests focused
3. **Use contexts**: Group related tests with `context` blocks
4. **Use let**: Define reusable test data with `let` or `let!`
5. **Test edge cases**: Include tests for nil, empty, and invalid inputs
6. **Mock external dependencies**: Don't make actual S3 calls or database connections in unit tests

### Example: Adding a New Validator Test

```ruby
describe '#validate_phone' do
  it 'accepts international format' do
    record = valid_patient_record.merge('phone' => '+44 20 7123 4567')
    errors = validator.validate_record(record)
    expect(errors).to be_empty
  end
  
  it 'rejects invalid international format' do
    record = valid_patient_record.merge('phone' => '+999 invalid')
    errors = validator.validate_record(record, 1)
    expect(errors).to include(/Invalid phone format/)
  end
end
```

## Integration Testing

### Manual Integration Test

```bash
# Create test data
cat > data/input/test_integration.csv << EOF
patient_id,first_name,last_name,email,date_of_birth
TEST001,Test,User,test@example.com,1990-01-01
EOF

# Run migration
./scripts/migrate.sh data/input/test_integration.csv

# Verify output
ls -la data/output/
cat data/output/test_integration_*.json
```

## Continuous Integration

### GitHub Actions Example

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v2
    
    - name: Set up Ruby
      uses: ruby/setup-ruby@v1
      with:
        ruby-version: 3.2
        bundler-cache: true
    
    - name: Run tests
      run: bundle exec rspec
    
    - name: Run rubocop
      run: bundle exec rubocop
```

## Performance Testing

### Benchmark Large Files

```bash
# Generate large test file
ruby -e "
require 'csv'
CSV.open('data/input/large_test.csv', 'w') do |csv|
  csv << ['patient_id', 'first_name', 'last_name', 'email', 'date_of_birth']
  10000.times do |i|
    csv << [\"PAT#{i.to_s.rjust(6, '0')}\", 'First', 'Last', \"user#{i}@example.com\", '1990-01-01']
  end
end
"

# Time the migration
time ./scripts/migrate.sh data/input/large_test.csv
```

## Test Data Generators

### Using Faker (if needed)

```ruby
require 'faker'

def generate_test_patient
  {
    'patient_id' => Faker::Alphanumeric.alpha(number: 10).upcase,
    'first_name' => Faker::Name.first_name,
    'last_name' => Faker::Name.last_name,
    'email' => Faker::Internet.email,
    'phone' => Faker::PhoneNumber.cell_phone,
    'date_of_birth' => Faker::Date.birthday(min_age: 18, max_age: 90).strftime('%Y-%m-%d')
  }
end
```

## Debugging Tests

### Using Pry

Add `gem 'pry'` to Gemfile, then in your test:

```ruby
it 'debugs something' do
  require 'pry'
  binding.pry  # Execution will pause here
  # You can inspect variables, call methods, etc.
end
```

### Verbose Output

```bash
bundle exec rspec --format documentation --backtrace
```

## Common Issues

### Issue: Tests failing with "Database not found"
**Solution**: Create test database: `createdb migration_demo_test`

### Issue: S3 upload tests failing
**Solution**: These are mocked by default. Ensure S3Uploader uses simulation in test env

### Issue: CSV parsing errors
**Solution**: Check file encoding and line endings (use Unix LF, not Windows CRLF)