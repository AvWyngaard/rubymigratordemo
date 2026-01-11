#!/bin/bash

# Healthcare Data Migration Script
# Orchestrates the complete migration workflow

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
LOG_DIR="$PROJECT_DIR/logs"
DATA_INPUT="$PROJECT_DIR/data/input"
DATA_OUTPUT="$PROJECT_DIR/data/output"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if Ruby is installed
    if ! command -v ruby &> /dev/null; then
        log_error "Ruby is not installed. Please install Ruby 3.x"
        exit 1
    fi
    
    # Check Ruby version
    ruby_version=$(ruby -v | grep -oP '\d+\.\d+' | head -1)
    log_info "Ruby version: $ruby_version"
    
    # Check if bundler is installed
    if ! command -v bundle &> /dev/null; then
        log_warning "Bundler not found. Installing..."
        gem install bundler
    fi
    
    # Check if gems are installed
    if [ ! -f "$PROJECT_DIR/Gemfile.lock" ]; then
        log_warning "Dependencies not installed. Running bundle install..."
        cd "$PROJECT_DIR" && bundle install
    fi
    
    log_info "Prerequisites OK"
}

# Validate input file
validate_input() {
    local input_file=$1
    
    log_info "Validating input file: $(basename "$input_file")"
    
    if [ ! -f "$input_file" ]; then
        log_error "Input file not found: $input_file"
        exit 1
    fi
    
    # Check file size
    file_size=$(wc -c < "$input_file")
    log_info "File size: $((file_size / 1024)) KB"
    
    # Check if file is CSV
    if [[ ! "$input_file" =~ \.csv$ ]]; then
        log_warning "File does not have .csv extension"
    fi
    
    # Count records
    record_count=$(($(wc -l < "$input_file") - 1))
    log_info "Record count: $record_count"
}

# Run data validation
run_validation() {
    local input_file=$1
    
    log_info "Running data validation..."
    
    ruby -r "$PROJECT_DIR/lib/validator.rb" -e "
        require 'csv'
        validator = Validator.new
        records = CSV.read('$input_file', headers: true)
        errors = validator.validate_records(records)
        
        if errors.empty?
            puts '✓ Validation passed'
            exit 0
        else
            puts '✗ Validation failed:'
            errors.first(10).each { |e| puts \"  - #{e}\" }
            exit 1
        end
    "
    
    return $?
}

# Execute migration
run_migration() {
    local input_file=$1
    
    log_info "Starting migration workflow..."
    log_info "=" * 50
    
    ruby -r "$PROJECT_DIR/lib/migrator.rb" -e "
        migrator = Migrator.new
        result = migrator.migrate('$input_file', import_to_db: false)
        
        if result[:success]
            puts \"
Migration completed successfully!
S3 Key: #{result[:s3_key]}
Records processed: #{result[:stats][:records_processed]}
Records validated: #{result[:stats][:records_validated]}
Duration: #{(result[:stats][:end_time] - result[:stats][:start_time]).round(2)}s
\"
            exit 0
        else
            puts \"Migration failed: #{result[:error]}\"
            exit 1
        end
    "
}

# Create backup
create_backup() {
    local input_file=$1
    local backup_dir="$PROJECT_DIR/backups"
    
    mkdir -p "$backup_dir"
    
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$backup_dir/$(basename "$input_file" .csv)_$timestamp.csv"
    
    cp "$input_file" "$backup_file"
    log_info "Backup created: $backup_file"
}

# Main execution
main() {
    echo "========================================"
    echo "Healthcare Data Migration Tool"
    echo "========================================"
    echo ""
    
    # Check if input file provided
    if [ $# -eq 0 ]; then
        log_error "Usage: $0 <input_csv_file>"
        echo ""
        echo "Example: $0 data/input/patients.csv"
        exit 1
    fi
    
    local input_file=$1
    
    # Create log directory
    mkdir -p "$LOG_DIR"
    
    # Log file
    local log_file="$LOG_DIR/migration_$(date '+%Y%m%d_%H%M%S').log"
    
    # Execute migration steps
    {
        check_prerequisites
        validate_input "$input_file"
        create_backup "$input_file"
        
        if run_validation "$input_file"; then
            run_migration "$input_file"
        else
            log_error "Validation failed. Migration aborted."
            exit 1
        fi
    } 2>&1 | tee "$log_file"
    
    log_info "Log saved to: $log_file"
}

# Run main function
main "$@"