#!/bin/bash

# Data Validation Script
# Performs pre-migration validation checks

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

if [ $# -eq 0 ]; then
    log_error "Usage: $0 <csv_file>"
    exit 1
fi

input_file=$1

if [ ! -f "$input_file" ]; then
    log_error "File not found: $input_file"
    exit 1
fi

log_info "Validating: $(basename "$input_file")"
echo "========================================"

# File checks
log_info "File size: $(wc -c < "$input_file" | awk '{print int($1/1024)"KB"}')"
log_info "Line count: $(wc -l < "$input_file")"

# CSV structure check
log_info "Checking CSV structure..."
header=$(head -1 "$input_file")
log_info "Headers found: $(echo "$header" | tr ',' '\n' | wc -l) columns"

# Run Ruby validator
log_info "Running validation rules..."
ruby -r "$PROJECT_DIR/lib/validator.rb" -e "
    require 'csv'
    
    validator = Validator.new
    records = CSV.read('$input_file', headers: true)
    errors = validator.validate_records(records)
    
    puts ''
    puts 'Validation Results:'
    puts '=' * 40
    puts \"Total records: #{records.length}\"
    puts \"Validation errors: #{errors.length}\"
    puts ''
    
    if errors.empty?
        puts '${GREEN}✓ All records valid${NC}'
        exit 0
    else
        puts '${RED}✗ Validation failed${NC}'
        puts ''
        puts 'Errors (showing first 20):'
        errors.first(20).each { |e| puts \"  - #{e}\" }
        puts ''
        puts \"Total errors: #{errors.length}\"
        exit 1
    end
"

exit $?