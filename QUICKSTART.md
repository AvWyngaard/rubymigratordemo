# Quick Start Guide

Get up and running with the data migration demo in 5 minutes.

## Prerequisites

- Ubuntu 20.04+ or macOS
- Ruby 3.0+ installed
- Git (optional)

## Installation Steps

### 1. Install Ruby (if not already installed)

**Ubuntu:**
```bash
sudo apt-get update
sudo apt-get install ruby-full build-essential
```

**macOS:**
```bash
brew install ruby
```

Verify installation:
```bash
ruby --version  # Should show 3.x
```

### 2. Install Project Dependencies

```bash
cd data-migration-demo
gem install bundler
bundle install
```

### 3. Verify Installation

```bash
# Run tests to ensure everything is working
bundle exec rspec

# You should see output like:
# Validator
#   #validate_record
#     with valid record
#       ✓ returns no errors for a complete valid record
# ...
# Finished in 0.5 seconds
# XX examples, 0 failures
```

## Running Your First Migration

### Step 1: Examine Sample Data

```bash
cat data/input/patients.csv
```

You'll see 10 sample patient records.

### Step 2: Generate test data

```bash
ruby ./lib/data_generators/simple_medical_data.rb
```

Expected output:
```
Clearing existing collections...
Creating sample medical practice data...

Creating practitioners...
Created 15 practitioners

Creating patients...
Created 100 patients

Creating appointments...
Created 200 appointments

Creating medications...
Created 150 medications

==================================================
DATABASE SEEDING COMPLETE
==================================================

Database: medical_practice_demo
Collections created:
  - practitioners: 15 documents
  - patients: 100 documents
  - appointments: 200 documents
  - medications: 150 documents

Intentional data quality issues included:
  ✓ Missing/null values (~10-20% error rate per field)
  ✓ Empty strings and whitespace-only values
  ✓ Duplicate SSNs (some patients share SSN '123-45-6789')
  ✓ Invalid dates (future dates, nulls)
  ✓ Orphaned references (appointments/medications without valid patient/practitioner)
  ✓ Formatting inconsistencies (uppercase names, extra characters)
  ✓ Invalid numeric values (negative numbers)
  ✓ Empty arrays in list fields
  ✓ Missing nested object fields

You can now test your data migration and validation logic!

To connect: mongo mongodb://localhost:27017/medical_practice_demo
```
### Step 3: Run Validation and Cleaning Script

```bash
ruby ./lib/validators/simple_data_validator.rb
```

### Step 3: Run Migration

```bash
./scripts/migrate.sh data/input/patients.csv
```

Expected output:
```
========================================
Healthcare Data Migration Tool
========================================

[INFO] Starting migration: patients.csv
...
✓ Validation passed (10 records)
✓ Transformation complete
✓ Uploaded: s3://migration-demo-bucket/migrations/patients_YYYYMMDD_HHMMSS.json
✓ Migration completed successfully!
```

### Step 4: View Results

```bash
# Check the output directory
ls -la data/output/

# View the transformed JSON
cat data/output/patients_*.json | head -50
```

## What Just Happened?

1. **Validation**: Checked all 10 patient records for:
   - Required fields present
   - Valid email formats
   - Valid phone numbers
   - Valid dates of birth
   - Proper patient ID format

2. **Transformation**: Converted CSV to structured JSON:
   - Cleaned and normalized data
   - Organized into logical sections (personal_info, contact_info, medical_info)
   - Added migration metadata

3. **Upload**: Simulated S3 upload (saved locally to data/output/)

4. **Logging**: Created migration log in logs/ directory

## Next Steps

### Create Your Own Data

```bash
# Create a new CSV file
cat > data/input/my_patients.csv << EOF
patient_id,first_name,last_name,email,phone,date_of_birth,gender,nhs_number,address_street,address_city,address_postcode,address_country
PAT999,Jane,Doe,jane.doe@example.com,07700900999,1985-03-20,F,9999999999,10 Test Road,London,SE1 1AA,UK
EOF

# Run migration on your data
./scripts/migrate.sh data/input/my_patients.csv
```

### Test Error Handling

Create an invalid file to see validation in action:

```bash
cat > data/input/invalid.csv << EOF
patient_id,first_name,last_name,email,phone,date_of_birth
,John,Smith,invalid-email,123,not-a-date
EOF

./scripts/validate_data.sh data/input/invalid.csv
```

You should see validation errors.

## Common Commands

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/validator_spec.rb

# Validate data only
./scripts/validate_data.sh data/input/patients.csv

# Full migration
./scripts/migrate.sh data/input/patients.csv

# Check logs
tail -f logs/migration_*.log
```

## Understanding the Output

### JSON Structure

```json
{
  "patient_id": "PAT001",
  "personal_info": {
    "first_name": "John",
    "last_name": "Smith",
    "date_of_birth": "1980-05-15",
    "gender": "M"
  },
  "contact_info": {
    "email": "john.smith@example.com",
    "phone": "+447700900123",
    "address": {
      "street": "123 High Street",
      "city": "London",
      "postcode": "SW1A 1AA",
      "country": "UK"
    }
  },
  "medical_info": {
    "nhs_number": "1234567890",
    "allergies": ["Penicillin"],
    "medications": ["Aspirin"]
  },
  "metadata": {
    "source_system": "Legacy",
    "migrated_at": "2025-01-10T15:30:00Z",
    "migration_batch": "BATCH_20250110_153000"
  }
}
```

## Troubleshooting

### Bundle install fails
```bash
# Try installing bundler first
gem install bundler

# Or use system bundler
sudo gem install bundler
```

### Permission denied on scripts
```bash
chmod +x scripts/*.sh
```

### Ruby version too old
```bash
# Check version
ruby --version

# Update Ruby (Ubuntu)
sudo apt-get install ruby-full

# Update Ruby (macOS)
brew upgrade ruby
```

## Need Help?

- Check the main README.md for detailed documentation
- Review TESTING.md for testing guidelines
- Examine the code in lib/ directory for implementation details

## What's Included

```
data-migration-demo/
├── README.md              # Full documentation
├── TESTING.md            # Testing guide
├── Gemfile               # Ruby dependencies
├── lib/                  # Core migration code
│   ├── migrator.rb       # Main orchestrator
│   ├── validator.rb      # Validation rules
│   ├── transformers/     # Data transformation
│   └── uploaders/        # S3 integration
├── spec/                 # RSpec tests
├── scripts/              # Bash automation
├── data/                 # Input/output data
├── config/               # Configuration
├── ansible/              # Server provisioning
└── db/                   # Database schema
```

Enjoy exploring the demo! 🚀