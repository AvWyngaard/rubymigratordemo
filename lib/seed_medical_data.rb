#!/usr/bin/env ruby
require 'mongo'
require 'faker'
require 'securerandom'

# Configuration
DB_NAME = 'medical_practice_demo'
MONGO_URI = ENV['MONGO_URI'] || 'mongodb://localhost:27017'

# Connect to MongoDB
client = Mongo::Client.new(MONGO_URI, database: DB_NAME)

# Clear existing collections
puts "Clearing existing collections..."
client[:patients].drop
client[:appointments].drop
client[:practitioners].drop
client[:medications].drop

puts "Creating sample medical practice data..."

# Helper method to randomly introduce errors
def maybe_error(value, error_rate = 0.15)
  return value if rand > error_rate
  
  case value
  when String
    # Random string errors
    case rand(5)
    when 0 then nil  # Missing data
    when 1 then ""   # Empty string
    when 2 then "   "  # Whitespace only
    when 3 then value.upcase  # Formatting issue
    when 4 then value + "123"  # Extra characters
    end
  when Integer
    rand(2) == 0 ? -1 : nil  # Invalid or missing number
  when Time, Date
    rand(2) == 0 ? nil : Time.new(2050, 1, 1)  # Missing or future date
  else
    nil
  end
end

# Create Practitioners
puts "\nCreating practitioners..."
practitioners = []
specialties = ['General Practice', 'Cardiology', 'Pediatrics', 'Orthopedics', 'Dermatology', 'Psychiatry']

15.times do
  practitioner = {
    practitioner_id: maybe_error(SecureRandom.uuid, 0.1),
    first_name: maybe_error(Faker::Name.first_name, 0.1),
    last_name: maybe_error(Faker::Name.last_name, 0.1),
    specialty: specialties.sample,
    license_number: maybe_error("MD-#{rand(100000..999999)}", 0.15),
    email: maybe_error(Faker::Internet.email, 0.1),
    phone: maybe_error(Faker::PhoneNumber.phone_number, 0.2),
    hire_date: maybe_error(Faker::Date.between(from: '2010-01-01', to: '2023-12-31'), 0.1),
    status: ['active', 'inactive', 'on_leave'].sample
  }
  practitioners << practitioner
end

client[:practitioners].insert_many(practitioners)
puts "Created #{practitioners.length} practitioners"

# Create Patients
puts "\nCreating patients..."
patients = []
blood_types = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-']

100.times do
  # Intentionally create some duplicate SSNs
  ssn = rand(10) < 2 ? "123-45-6789" : "#{rand(100..999)}-#{rand(10..99)}-#{rand(1000..9999)}"
  
  patient = {
    patient_id: maybe_error(SecureRandom.uuid, 0.05),
    first_name: maybe_error(Faker::Name.first_name, 0.1),
    last_name: maybe_error(Faker::Name.last_name, 0.1),
    date_of_birth: maybe_error(Faker::Date.birthday(min_age: 1, max_age: 90), 0.1),
    ssn: maybe_error(ssn, 0.15),
    email: maybe_error(Faker::Internet.email, 0.2),
    phone: maybe_error(Faker::PhoneNumber.phone_number, 0.15),
    address: {
      street: maybe_error(Faker::Address.street_address, 0.1),
      city: maybe_error(Faker::Address.city, 0.1),
      state: maybe_error(Faker::Address.state_abbr, 0.1),
      zip: maybe_error(Faker::Address.zip_code, 0.15)
    },
    blood_type: maybe_error(blood_types.sample, 0.2),
    allergies: rand(3) == 0 ? [] : Faker::Lorem.words(number: rand(1..3)),
    emergency_contact: {
      name: maybe_error(Faker::Name.name, 0.15),
      phone: maybe_error(Faker::PhoneNumber.phone_number, 0.2),
      relationship: maybe_error(['Spouse', 'Parent', 'Sibling', 'Friend'].sample, 0.1)
    },
    insurance: {
      provider: maybe_error(['Blue Cross', 'Aetna', 'Cigna', 'UnitedHealthcare', 'Medicare'].sample, 0.15),
      policy_number: maybe_error("POL-#{rand(100000..999999)}", 0.2),
      group_number: maybe_error("GRP-#{rand(1000..9999)}", 0.2)
    },
    created_at: Faker::Time.between(from: DateTime.now - 365, to: DateTime.now),
    updated_at: Faker::Time.between(from: DateTime.now - 30, to: DateTime.now)
  }
  patients << patient
end

client[:patients].insert_many(patients)
puts "Created #{patients.length} patients"

# Create Appointments
puts "\nCreating appointments..."
appointments = []
appointment_types = ['Check-up', 'Follow-up', 'Consultation', 'Procedure', 'Emergency']
statuses = ['scheduled', 'completed', 'cancelled', 'no-show']

200.times do
  # Some appointments reference non-existent patients/practitioners (orphaned records)
  patient_ref = rand(10) < 8 ? patients.sample[:patient_id] : maybe_error(SecureRandom.uuid, 0)
  practitioner_ref = rand(10) < 9 ? practitioners.sample[:practitioner_id] : maybe_error(SecureRandom.uuid, 0)
  
  appointment_date = Faker::Time.between(from: DateTime.now - 180, to: DateTime.now + 90)
  
  appointment = {
    appointment_id: maybe_error(SecureRandom.uuid, 0.05),
    patient_id: patient_ref,
    practitioner_id: practitioner_ref,
    appointment_date: maybe_error(appointment_date, 0.1),
    appointment_type: maybe_error(appointment_types.sample, 0.1),
    duration_minutes: maybe_error([15, 30, 45, 60].sample, 0.15),
    status: maybe_error(statuses.sample, 0.1),
    notes: rand(2) == 0 ? Faker::Lorem.sentence : nil,
    chief_complaint: maybe_error(Faker::Lorem.sentence, 0.2),
    diagnosis_codes: rand(3) == 0 ? [] : Array.new(rand(1..3)) { "ICD10-#{rand(100..999)}.#{rand(0..9)}" },
    created_at: Faker::Time.between(from: DateTime.now - 200, to: DateTime.now),
    updated_at: Faker::Time.between(from: DateTime.now - 30, to: DateTime.now)
  }
  appointments << appointment
end

client[:appointments].insert_many(appointments)
puts "Created #{appointments.length} appointments"

# Create Medications
puts "\nCreating medications..."
medications = []
medication_names = [
  'Lisinopril', 'Metformin', 'Atorvastatin', 'Amlodipine', 'Metoprolol',
  'Omeprazole', 'Albuterol', 'Losartan', 'Gabapentin', 'Levothyroxine'
]
dosage_forms = ['Tablet', 'Capsule', 'Injection', 'Syrup', 'Cream']

150.times do
  # Some medications reference non-existent patients (orphaned records)
  patient_ref = rand(10) < 9 ? patients.sample[:patient_id] : maybe_error(SecureRandom.uuid, 0)
  practitioner_ref = rand(10) < 9 ? practitioners.sample[:practitioner_id] : maybe_error(SecureRandom.uuid, 0)
  
  medication = {
    medication_id: maybe_error(SecureRandom.uuid, 0.05),
    patient_id: patient_ref,
    prescribed_by: practitioner_ref,
    medication_name: maybe_error(medication_names.sample, 0.1),
    dosage: maybe_error("#{rand(5..500)}mg", 0.15),
    dosage_form: maybe_error(dosage_forms.sample, 0.1),
    frequency: maybe_error(['Once daily', 'Twice daily', 'Three times daily', 'As needed'].sample, 0.15),
    start_date: maybe_error(Faker::Date.between(from: '2020-01-01', to: Date.today), 0.1),
    end_date: rand(3) == 0 ? nil : maybe_error(Faker::Date.between(from: Date.today, to: '2025-12-31'), 0.15),
    refills_remaining: maybe_error(rand(0..12), 0.2),
    instructions: maybe_error(Faker::Lorem.sentence, 0.15),
    active: [true, false].sample,
    created_at: Faker::Time.between(from: DateTime.now - 365, to: DateTime.now),
    updated_at: Faker::Time.between(from: DateTime.now - 30, to: DateTime.now)
  }
  medications << medication
end

client[:medications].insert_many(medications)
puts "Created #{medications.length} medications"

# Print summary
puts "\n" + "="*50
puts "DATABASE SEEDING COMPLETE"
puts "="*50
puts "\nDatabase: #{DB_NAME}"
puts "Collections created:"
puts "  - practitioners: #{client[:practitioners].count()} documents"
puts "  - patients: #{client[:patients].count()} documents"
puts "  - appointments: #{client[:appointments].count()} documents"
puts "  - medications: #{client[:medications].count()} documents"

puts "\nIntentional data quality issues included:"
puts "  ✓ Missing/null values (~10-20% error rate per field)"
puts "  ✓ Empty strings and whitespace-only values"
puts "  ✓ Duplicate SSNs (some patients share SSN '123-45-6789')"
puts "  ✓ Invalid dates (future dates, nulls)"
puts "  ✓ Orphaned references (appointments/medications without valid patient/practitioner)"
puts "  ✓ Formatting inconsistencies (uppercase names, extra characters)"
puts "  ✓ Invalid numeric values (negative numbers)"
puts "  ✓ Empty arrays in list fields"
puts "  ✓ Missing nested object fields"

puts "\nYou can now test your data migration and validation logic!"
puts "\nTo connect: mongo #{MONGO_URI}/#{DB_NAME}"