-- Creating HealthCare Management System Database.
-- Using Character Set to utf8mb4 for full unicode support.
-- Using collation for case-insensitive and accent-insensitive comparisons.

CREATE DATABASE IF NOT EXISTS HealthCare_HMS
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

-- Using created Database.
USE Healthcare_HMS;

-- Setting Status to verify database creation and usage.
SELECT 'Database Healthcare_HMS created and selected.' AS Status;

-- Creating Tables for the HMS database.

-- (1) Lookup Tables (Created before because of no Foreign Key constraints) 

CREATE TABLE IF NOT EXISTS MedicalSpecialities(
	specialty_id INT AUTO_INCREMENT PRIMARY KEY,
    specialty_name VARCHAR(100) NOT NULL UNIQUE COMMENT 'Name of the medical specialty (e.g., Cardiology, Pediatrics)',
    description TEXT COMMENT 'Detailed description of the specialty'
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Setting Status to verify table creation inside the database.
SELECT 'Table MedicalSpecialties created.' AS Status;

CREATE TABLE IF NOT EXISTS LabTests (
    test_id INT AUTO_INCREMENT PRIMARY KEY,
    test_name VARCHAR(150) NOT NULL UNIQUE COMMENT 'Name of the lab test (e.g., Complete Blood Count, Urinalysis)',
    description TEXT COMMENT 'Detailed description of the test',
    normal_range VARCHAR(255) COMMENT 'Typical healthy range for results (e.g., 4.5-5.5 million/uL)',
    unit VARCHAR(50) COMMENT 'Unit of measurement for the test result (e.g., mg/dL, cells/uL)'
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Setting Status to verify table creation inside the database.
SELECT 'Table LabTests created.' AS Status;

CREATE TABLE IF NOT EXISTS Medications (
    medication_id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL UNIQUE COMMENT 'Medication generic or brand name',
    strength VARCHAR(100) COMMENT 'Medication strength (e.g., 500mg, 250mg/5ml)',
    form VARCHAR(100) COMMENT 'Medication form (e.g., Tablet, Syrup, Injection)',
    unit_price DECIMAL(10, 2) COMMENT 'Cost per unit of medication',
    stock_quantity INT DEFAULT 0 COMMENT 'Current quantity in inventory',
    reorder_level INT COMMENT 'Threshold to trigger reorder for inventory',
    CHECK (unit_price >= 0),
    CHECK (stock_quantity >= 0)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Setting Status to verify table creation inside the database.
SELECT 'Table Medications created.' AS Status;

-- (2) Core Entity Tables (Created after because of dependency on lookup tables). 

CREATE TABLE IF NOT EXISTS Patients (
    patient_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE NOT NULL,
    gender ENUM('Male', 'Female', 'Other') NOT NULL,
    blood_group VARCHAR(10) COMMENT 'Patient''s blood type (e.g., A+, B-)',
    address TEXT,
    phone_number VARCHAR(20) UNIQUE COMMENT 'Primary contact number for the patient',
    email VARCHAR(255) UNIQUE COMMENT 'Patient''s email address',
    emergency_contact_name VARCHAR(200) COMMENT 'Name of emergency contact',
    emergency_contact_phone VARCHAR(20) COMMENT 'Phone number of emergency contact',
    allergies TEXT COMMENT 'Known allergies of the patient',
    medical_history_summary TEXT COMMENT 'Brief summary of significant medical history',
    registration_date DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Date patient was registered in the system',
    status ENUM('Active', 'Inactive', 'Deceased') DEFAULT 'Active' COMMENT 'Patient''s active status'
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Setting Status to verify table creation inside the database.
SELECT 'Table Patients created.' AS Status;

CREATE TABLE IF NOT EXISTS Doctors (
    doctor_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    specialty_id INT NOT NULL COMMENT 'ID referencing the MedicalSpecialties lookup table',
    license_number VARCHAR(50) NOT NULL UNIQUE COMMENT 'Doctor''s medical license number',
    phone_number VARCHAR(20) COMMENT 'Doctor''s contact number',
    email VARCHAR(255) UNIQUE COMMENT 'Doctor''s email address',
    hire_date DATE NOT NULL COMMENT 'Date the doctor was hired',
    status ENUM('Active', 'Inactive', 'On Leave') DEFAULT 'Active' COMMENT 'Doctor''s active status',
    FOREIGN KEY (specialty_id) REFERENCES MedicalSpecialities(specialty_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Setting Status to verify table creation inside the database.
SELECT 'Table Doctors created.' AS Status;

CREATE TABLE IF NOT EXISTS Nurses (
    nurse_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    license_number VARCHAR(50) NOT NULL UNIQUE COMMENT 'Nurse''s license number',
    phone_number VARCHAR(20) COMMENT 'Nurse''s contact number',
    email VARCHAR(255) UNIQUE COMMENT 'Nurse''s email address',
    hire_date DATE NOT NULL COMMENT 'Date the nurse was hired',
    status ENUM('Active', 'Inactive', 'On Leave') DEFAULT 'Active' COMMENT 'Nurse''s active status'
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Setting Status to verify table creation inside the database.
SELECT 'Table Nurses created.' AS Status;

-- (2) Transactional Tables (Created after because of dependency on core entities).

CREATE TABLE IF NOT EXISTS Appointments (
    appointment_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL COMMENT 'ID of the patient',
    doctor_id INT NOT NULL COMMENT 'ID of the doctor',
    appointment_datetime DATETIME NOT NULL COMMENT 'Date and time of the appointment',
    reason_for_visit TEXT COMMENT 'Description of the reason for the appointment',
    status ENUM('Scheduled', 'Completed', 'Canceled', 'No Show') DEFAULT 'Scheduled' COMMENT 'Current status of the appointment',
    notes TEXT COMMENT 'Any additional notes about the appointment',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT 'Timestamp when the appointment was created',
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of the last update',
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES Doctors(doctor_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    UNIQUE KEY idx_unique_appointment (patient_id, doctor_id, appointment_datetime) COMMENT 'Prevents duplicate appointments for the same patient and doctor at the exact same time'
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Setting Status to verify table creation inside the database.
SELECT 'Table Appointments created.' AS Status;

CREATE TABLE IF NOT EXISTS MedicalRecords (
    record_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL COMMENT 'ID of the patient',
    doctor_id INT NOT NULL COMMENT 'ID of the doctor who created the record',
    encounter_datetime DATETIME NOT NULL COMMENT 'Date and time of the encounter',
    symptoms TEXT COMMENT 'Patient''s reported symptoms',
    diagnosis_code VARCHAR(50) COMMENT 'Code for the primary diagnosis (e.g., ICD-10)',
    diagnosis_description TEXT COMMENT 'Description of the primary diagnosis',
    treatment_plan TEXT COMMENT 'Details of the planned treatment',
    notes TEXT COMMENT 'General clinical notes for the encounter',
    follow_up_date DATE COMMENT 'Date for next follow-up',
    record_type VARCHAR(50) NOT NULL COMMENT 'Type of encounter (e.g., Outpatient, Inpatient, Emergency)',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (doctor_id) REFERENCES Doctors(doctor_id)
        ON DELETE RESTRICT ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Setting Status to verify table creation inside the database.
SELECT 'Table MedicalRecords created.' AS Status;

CREATE TABLE IF NOT EXISTS Prescriptions (
    prescription_id INT AUTO_INCREMENT PRIMARY KEY,
    record_id INT NOT NULL COMMENT 'ID of the associated medical record/encounter',
    medication_id INT NOT NULL COMMENT 'ID of the prescribed medication',
    dosage VARCHAR(100) NOT NULL COMMENT 'Amount of medication per dose (e.g., 10mg, 2 tablets)',
    frequency VARCHAR(100) NOT NULL COMMENT 'How often the medication should be taken (e.g., Twice daily, Every 6 hours)',
    route VARCHAR(100) COMMENT 'How the medication is administered (e.g., Oral, IV)',
    start_date DATE NOT NULL COMMENT 'Date prescription begins',
    end_date DATE COMMENT 'Date prescription ends',
    quantity INT COMMENT 'Total quantity prescribed',
    instructions TEXT COMMENT 'Specific patient instructions for medication use',
    prescribed_by_doctor_id INT NOT NULL COMMENT 'ID of the prescribing doctor',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (record_id) REFERENCES MedicalRecords(record_id)
        ON DELETE CASCADE ON UPDATE CASCADE, -- If record is deleted, prescriptions also go
    FOREIGN KEY (medication_id) REFERENCES Medications(medication_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (prescribed_by_doctor_id) REFERENCES Doctors(doctor_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CHECK (quantity >= 0)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Setting Status to verify table creation inside the database.
SELECT 'Table Prescriptions created.' AS Status;

CREATE TABLE IF NOT EXISTS LabResults (
    result_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL COMMENT 'ID of the patient',
    test_id INT NOT NULL COMMENT 'ID of the lab test performed',
    record_id INT COMMENT 'ID of the associated medical record/encounter (if applicable)',
    result_value VARCHAR(255) NOT NULL COMMENT 'The numerical or textual result of the test',
    result_date DATETIME NOT NULL COMMENT 'Date the test result was obtained',
    performed_by VARCHAR(255) COMMENT 'Name or ID of the lab technician/facility',
    is_abnormal BOOLEAN DEFAULT FALSE COMMENT 'Flag if the result is outside normal range',
    notes TEXT COMMENT 'Any additional notes on the result',
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (test_id) REFERENCES LabTests(test_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    FOREIGN KEY (record_id) REFERENCES MedicalRecords(record_id)
        ON DELETE SET NULL ON UPDATE CASCADE -- If record is deleted, link is set to NULL
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Setting Status to verify table creation inside the database.
SELECT 'Table LabResults created.' AS Status;

CREATE TABLE IF NOT EXISTS Billing (
    bill_id INT AUTO_INCREMENT PRIMARY KEY,
    patient_id INT NOT NULL COMMENT 'ID of the patient',
    bill_date DATE NOT NULL COMMENT 'Date the bill was generated',
    total_amount DECIMAL(10, 2) NOT NULL COMMENT 'Total amount due on the bill',
    paid_amount DECIMAL(10, 2) DEFAULT 0.00 COMMENT 'Amount already paid towards this bill',
    due_date DATE COMMENT 'Date payment is due',
    status ENUM('Outstanding', 'Paid', 'Partially Paid', 'Canceled') DEFAULT 'Outstanding' COMMENT 'Current status of the bill',
    service_details TEXT COMMENT 'General description of services rendered on this bill',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_updated DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (patient_id) REFERENCES Patients(patient_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CHECK (total_amount >= 0),
    CHECK (paid_amount >= 0)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Setting Status to verify table creation inside the database.
SELECT 'Table Billing created.' AS Status;

CREATE TABLE IF NOT EXISTS BillItems (
    bill_item_id INT AUTO_INCREMENT PRIMARY KEY,
    bill_id INT NOT NULL COMMENT 'ID of the associated bill',
    service_type VARCHAR(100) NOT NULL COMMENT 'What kind of service (e.g., Consultation, Lab Test, Medication)',
    item_description VARCHAR(255) NOT NULL COMMENT 'Specific description of the item (e.g., Doctor Consultation, CBC Test)',
    quantity INT NOT NULL DEFAULT 1 COMMENT 'Number of units of the service/item',
    unit_price DECIMAL(10, 2) NOT NULL COMMENT 'Price per unit of the service/item',
    item_amount DECIMAL(10, 2) AS (quantity * unit_price) STORED COMMENT 'Calculated amount for this item (quantity * unit_price)', -- Stored column for efficiency
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (bill_id) REFERENCES Billing(bill_id)
        ON DELETE CASCADE ON UPDATE CASCADE, -- If bill is deleted, its items also go
    CHECK (quantity > 0),
    CHECK (unit_price >= 0)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Setting Status to verify table creation inside the database.
SELECT 'Table BillItems created.' AS Status;

CREATE TABLE IF NOT EXISTS Payments (
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    bill_id INT NOT NULL COMMENT 'ID of the bill being paid',
    payment_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT 'Date the payment was made',
    amount_paid DECIMAL(10, 2) NOT NULL COMMENT 'Amount of this specific payment',
    payment_method ENUM('Cash', 'Card', 'Bank Transfer', 'Insurance', 'Other') NOT NULL COMMENT 'How the payment was made',
    transaction_id VARCHAR(100) UNIQUE COMMENT 'External transaction ID if applicable',
    notes TEXT COMMENT 'Any payment-related notes',
    FOREIGN KEY (bill_id) REFERENCES Billing(bill_id)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    CHECK (amount_paid > 0)
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Setting Status to verify table creation inside the database.
SELECT 'Table Payments created.' AS Status;

-- (3) User Management Table (Created for database access roles).

CREATE TABLE IF NOT EXISTS Users (
    user_id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) NOT NULL UNIQUE COMMENT 'MySQL username for database access',
    password_hash VARCHAR(255) NOT NULL COMMENT 'Hashed password for the database user (use a strong hashing algorithm)',
    role VARCHAR(50) NOT NULL COMMENT 'Role within the database (e.g., admin, doctor_rw, receptionist_ro)',
    associated_doctor_id INT COMMENT 'Optional: Link to a specific doctor record if applicable',
    associated_nurse_id INT COMMENT 'Optional: Link to a specific nurse record if applicable',
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_login_at DATETIME COMMENT 'Timestamp of last database login',
    is_active BOOLEAN DEFAULT TRUE COMMENT 'Flag to enable/disable user',
    FOREIGN KEY (associated_doctor_id) REFERENCES Doctors(doctor_id)
        ON DELETE SET NULL ON UPDATE CASCADE,
    FOREIGN KEY (associated_nurse_id) REFERENCES Nurses(nurse_id)
        ON DELETE SET NULL ON UPDATE CASCADE
)ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Setting Status to verify table creation inside the database.
SELECT 'Table Users created.' AS Status;
