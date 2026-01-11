-- Database Schema for Healthcare Data Migration
-- PostgreSQL 15+

-- Patients table
CREATE TABLE IF NOT EXISTS patients (
    id SERIAL PRIMARY KEY,
    patient_id VARCHAR(20) UNIQUE NOT NULL,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender CHAR(1),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Contact information table
CREATE TABLE IF NOT EXISTS patient_contacts (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    email VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address_street TEXT,
    address_city VARCHAR(100),
    address_postcode VARCHAR(10),
    address_country VARCHAR(2) DEFAULT 'UK',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Medical information table
CREATE TABLE IF NOT EXISTS patient_medical_info (
    id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES patients(id) ON DELETE CASCADE,
    nhs_number VARCHAR(10),
    allergies TEXT[],
    medications TEXT[],
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Migration metadata table
CREATE TABLE IF NOT EXISTS migration_batches (
    id SERIAL PRIMARY KEY,
    batch_id VARCHAR(50) UNIQUE NOT NULL,
    source_system VARCHAR(50),
    source_file VARCHAR(255),
    records_count INTEGER,
    started_at TIMESTAMP,
    completed_at TIMESTAMP,
    status VARCHAR(20),
    s3_key VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Migration errors table
CREATE TABLE IF NOT EXISTS migration_errors (
    id SERIAL PRIMARY KEY,
    batch_id INTEGER REFERENCES migration_batches(id),
    error_type VARCHAR(50),
    error_message TEXT,
    record_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_patients_patient_id ON patients(patient_id);
CREATE INDEX IF NOT EXISTS idx_patients_dob ON patients(date_of_birth);
CREATE INDEX IF NOT EXISTS idx_contacts_email ON patient_contacts(email);
CREATE INDEX IF NOT EXISTS idx_medical_nhs ON patient_medical_info(nhs_number);
CREATE INDEX IF NOT EXISTS idx_batches_status ON migration_batches(status);
CREATE INDEX IF NOT EXISTS idx_batches_created ON migration_batches(created_at);

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for updated_at
CREATE TRIGGER update_patients_updated_at BEFORE UPDATE ON patients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_contacts_updated_at BEFORE UPDATE ON patient_contacts
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_medical_updated_at BEFORE UPDATE ON patient_medical_info
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- View for complete patient information
CREATE OR REPLACE VIEW vw_patient_complete AS
SELECT 
    p.id,
    p.patient_id,
    p.first_name,
    p.last_name,
    p.date_of_birth,
    p.gender,
    pc.email,
    pc.phone,
    pc.address_street,
    pc.address_city,
    pc.address_postcode,
    pc.address_country,
    pmi.nhs_number,
    pmi.allergies,
    pmi.medications,
    p.created_at,
    p.updated_at
FROM patients p
LEFT JOIN patient_contacts pc ON p.id = pc.patient_id
LEFT JOIN patient_medical_info pmi ON p.id = pmi.patient_id;

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO migrator;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO migrator;
GRANT SELECT ON vw_patient_complete TO migrator;