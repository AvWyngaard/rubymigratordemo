# Healthcare Data Migration Demo (Heavily Crutched with Claude)

A demonstration project showcasing data migration capabilities using Ruby, PostgreSQL, AWS S3, and modern testing practices.

## Overview

This project simulates a healthcare data migration workflow similar to migrating patient and appointment data from legacy systems to a modern platform. It demonstrates:

- Data extraction from CSV files (simulating legacy system exports)
- Data validation and cleaning using Ruby
- Transformation from CSV to JSON format
- PostgreSQL database interactions
- AWS S3 integration for data storage
- Comprehensive testing with RSpec
- Ansible provisioning setup

## Tech Stack

- **Ruby 3.x** - Core migration scripting
- **PostgreSQL** - Target database
- **AWS S3** - Secure data storage
- **RSpec** - Testing framework
- **Ansible** - Infrastructure provisioning
- **Bash** - Shell scripting and automation

## Project Structure

```
data-migration-demo/
├── README.md
├── Gemfile
├── lib/
│   ├── migrator.rb           # Core migration engine
│   ├── validator.rb          # Data validation logic
│   ├── transformers/
│   │   ├── csv_to_json.rb   # CSV to JSON transformer
│   │   └── legacy_adapter.rb # Adapter for legacy formats
│   └── uploaders/
│       └── s3_uploader.rb    # AWS S3 integration
├── spec/
│   ├── spec_helper.rb
│   ├── migrator_spec.rb
│   └── validator_spec.rb
├── data/
│   ├── input/                # Source CSV files
│   └── output/               # Converted JSON files
├── config/
│   └── database.yml
├── scripts/
│   ├── migrate.sh            # Main migration runner
│   └── validate_data.sh      # Pre-migration validation
└── ansible/
    └── provision.yml         # Server provisioning
```

## Setup Instructions

### 1. Install Dependencies

```bash
# Install Ruby (if not already installed)
# On Ubuntu:
sudo apt-get update
sudo apt-get install ruby-full

# Install Bundler
gem install bundler

# Install project dependencies
bundle install
```

### 2. Database Setup

```bash
# Install PostgreSQL
sudo apt-get install postgresql postgresql-contrib

# Create database and user
sudo -u postgres psql
CREATE DATABASE migration_demo;
CREATE USER migrator WITH PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE migration_demo TO migrator;
\q

# Run schema setup
psql -U migrator -d migration_demo -f db/schema.sql
```

### 3. AWS Configuration

```bash
# Configure AWS credentials
aws configure
# Or set environment variables:
export AWS_ACCESS_KEY_ID=your_key
export AWS_SECRET_ACCESS_KEY=your_secret
export AWS_REGION=us-east-1
export S3_BUCKET=migration-demo-bucket
```

### 4. Run Tests

```bash
bundle exec rspec
```

### 5. Execute Migration

```bash
# Validate source data
./scripts/validate_data.sh data/input/patients.csv

# Run migration
./scripts/migrate.sh data/input/patients.csv
```

## Demo Workflow

This demo simulates migrating patient data from a legacy CSV system:

1. **Data Reception** - CSV files placed in `data/input/`
2. **Validation** - Check data integrity, required fields, formats
3. **Transformation** - Convert CSV to JSON with data cleaning
4. **Upload** - Store validated JSON to S3
5. **Import** - Load data into PostgreSQL database
6. **Verification** - Run post-migration checks

## Key Features Demonstrated

- **Robust Validation**: Email format, phone numbers, date ranges, required fields
- **Data Cleaning**: Trim whitespace, normalize formats, handle nulls
- **Error Handling**: Graceful failures with detailed logging
- **Testing**: Comprehensive RSpec test coverage
- **S3 Integration**: Secure file uploads with metadata
- **Database Operations**: Safe inserts with transaction support
- **Script Automation**: Bash scripts for repeatable processes

## Sample Migration Run

```bash
$ ./scripts/migrate.sh data/input/patients.csv

Starting migration: patients.csv
================================
[2025-01-10 15:30:00] Validating source file...
[2025-01-10 15:30:01] ✓ Validation passed (150 records)
[2025-01-10 15:30:01] Transforming CSV to JSON...
[2025-01-10 15:30:02] ✓ Transformation complete
[2025-01-10 15:30:02] Uploading to S3...
[2025-01-10 15:30:04] ✓ Uploaded: s3://bucket/patients_20250110_153002.json
[2025-01-10 15:30:04] Importing to database...
[2025-01-10 15:30:06] ✓ Imported 150 records
[2025-01-10 15:30:06] Migration completed successfully!
```

## Next Steps

- Add MongoDB source adapter for NoSQL migrations
- Implement incremental migration support
- Add data anonymization capabilities
- Create migration rollback functionality
- Build monitoring dashboard

## Contact

For questions or improvements, please reach out!