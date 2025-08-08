USE HealthCare_HMS;

SELECT 'Starting Initial Data Population (Seed Data)...' AS Status;

-- Populating Lookup Tables First

-- MedicalSpecialities
INSERT INTO MedicalSpecialities (specialty_name, description) VALUES
('General Practice', 'Primary healthcare and common ailments.'),
('Cardiology', 'Heart and circulatory system disorders.'),
('Pediatrics', 'Healthcare for infants, children, and adolescents.'),
('Dermatology', 'Skin, hair, and nail conditions.'),
('Orthopedics', 'Musculoskeletal system injuries and diseases.');

SELECT 'MedicalSpecialities populated.' AS Status;

-- LabTests
INSERT INTO LabTests (test_name, description, normal_range, unit) VALUES
('Complete Blood Count (CBC)', 'Measures red blood cells, white blood cells, and platelets.', 'WBC: 4.5-11.0 K/uL, RBC: 4.5-5.5 M/uL', 'K/uL, M/uL'),
('Urinalysis', 'Analyzes urine for various components.', 'Clear, yellow, no protein/glucose', 'Qualitative'),
('Blood Glucose (Fasting)', 'Measures glucose levels after an overnight fast.', '70-99', 'mg/dL'),
('Lipid Panel', 'Measures cholesterol and triglycerides.', 'Total: <200, LDL: <100', 'mg/dL');

SELECT 'LabTests populated.' AS Status;

-- Medications
INSERT INTO Medications (name, strength, form, unit_price, stock_quantity, reorder_level) VALUES
('Paracetamol', '500mg', 'Tablet', 0.15, 1000, 200),
('Amoxicillin', '250mg/5ml', 'Syrup', 5.50, 250, 50),
('Lisinopril', '10mg', 'Tablet', 0.25, 750, 150),
('Atorvastatin', '20mg', 'Tablet', 0.40, 600, 120),
('Insulin Glargine', '100 units/ml', 'Injection', 25.00, 100, 20);

SELECT 'Medications populated.' AS Status;

--  Populating Core Entity Tables

-- Patients
INSERT INTO Patients (first_name, last_name, date_of_birth, gender, blood_group, address, phone_number, email, emergency_contact_name, emergency_contact_phone, allergies, medical_history_summary) VALUES
('John', 'Doe', '1980-03-10', 'Male', 'A+', '123 Oak Ave, Cityville, State', '555-101-2020', 'john.doe@example.com', 'Jane Doe', '555-101-2021', 'None', 'Healthy, no significant history.'),
('Jane', 'Smith', '1992-07-25', 'Female', 'B-', '456 Pine St, Townsville, State', '555-202-3030', 'jane.smith@example.com', 'Robert Smith', '555-202-3031', 'Penicillin', 'Childhood asthma, occasional migraines.'),
('Alice', 'Johnson', '1975-01-15', 'Female', 'O-', '789 Maple Rd, Villagetown, State', '555-303-4040', 'alice.j@example.com', 'David Johnson', '555-303-4041', 'Shellfish', 'Type 2 Diabetes, Hypertension.'),
('Robert', 'Brown', '1965-11-01', 'Male', 'AB+', '101 Cedar Ln, Hamlet, State', '555-404-5050', 'robert.b@example.com', 'Sarah Brown', '555-404-5051', 'Sulfa drugs', 'History of heart attack.'),
('Emily', 'Davis', '2010-04-20', 'Female', 'A-', '202 Birch Ct, Suburbia, State', '555-505-6060', 'emily.d@example.com', 'Michael Davis', '555-505-6061', 'Dust mites', 'Seasonal allergies, frequent ear infections.');

SELECT 'Patients populated.' AS Status;

-- Doctors
INSERT INTO Doctors (first_name, last_name, specialty_id, license_number, phone_number, email, hire_date, status) VALUES
('Dr. Alex', 'Chen', (SELECT specialty_id FROM MedicalSpecialities WHERE specialty_name = 'General Practice'), 'MD1001', '555-606-7070', 'alex.chen@example.com', '2018-03-01', 'Active'),
('Dr. Brenda', 'Diaz', (SELECT specialty_id FROM MedicalSpecialities WHERE specialty_name = 'Cardiology'), 'MD1002', '555-707-8080', 'brenda.diaz@example.com', '2015-06-15', 'Active'),
('Dr. Charlie', 'Evans', (SELECT specialty_id FROM MedicalSpecialities WHERE specialty_name = 'Pediatrics'), 'MD1003', '555-808-9090', 'charlie.e@example.com', '2020-01-10', 'Active'),
('Dr. Diana', 'Foster', (SELECT specialty_id FROM MedicalSpecialities WHERE specialty_name = 'Dermatology'), 'MD1004', '555-909-1010', 'diana.f@example.com', '2019-09-20', 'Active');

SELECT 'Doctors populated.' AS Status;

-- Nurses
INSERT INTO Nurses (first_name, last_name, license_number, phone_number, email, hire_date, status) VALUES
('Nurse Grace', 'Hill', 'RN2001', '555-111-3333', 'grace.h@example.com', '2017-02-01', 'Active'),
('Nurse Henry', 'Ivy', 'RN2002', '555-222-4444', 'henry.i@example.com', '2021-07-01', 'Active');

SELECT 'Nurses populated.' AS Status;

-- Users (for database access simulation)
-- Using SHA2 for basic hashing. In a real system, passwords would be hashed client-side with stronger algorithms.
INSERT INTO Users (username, password_hash, role, associated_doctor_id, associated_nurse_id, is_active) VALUES
('admin_db', SHA2('AdminPass123', 256), 'admin', NULL, NULL, TRUE),
('dralex.chen', SHA2('DocPass456', 256), 'doctor_rw', (SELECT doctor_id FROM Doctors WHERE last_name = 'Chen'), NULL, TRUE),
('janerecept', SHA2('RecPass789', 256), 'receptionist_ro', NULL, NULL, TRUE);

SELECT 'Users populated.' AS Status;

-- Populating Transactional Tables

-- Appointments (using CALL to trigger procedures)
-- Using specific dates to populate
CALL ScheduleAppointment(
    (SELECT patient_id FROM Patients WHERE last_name = 'Doe'),
    (SELECT doctor_id FROM Doctors WHERE last_name = 'Chen'),
    '2025-08-01 09:00:00',
    'Follow-up for seasonal allergies'
);
CALL ScheduleAppointment(
    (SELECT patient_id FROM Patients WHERE last_name = 'Smith'),
    (SELECT doctor_id FROM Doctors WHERE last_name = 'Diaz'),
    '2025-08-01 10:00:00',
    'Cardiac check-up'
);
CALL ScheduleAppointment(
    (SELECT patient_id FROM Patients WHERE last_name = 'Johnson'),
    (SELECT doctor_id FROM Doctors WHERE last_name = 'Chen'),
    '2025-08-02 11:00:00',
    'Diabetes management'
);
CALL ScheduleAppointment(
    (SELECT patient_id FROM Patients WHERE last_name = 'Davis'),
    (SELECT doctor_id FROM Doctors WHERE last_name = 'Evans'),
    '2025-09-25 14:00:00',
    'Routine pediatric check-up'
);

SELECT 'Appointments populated.' AS Status;

-- MedicalRecords (Encounters)
-- Capture the record_id for subsequent Prescriptions and LabResults
SET @rec_id_doe_allergy = 0;
CALL RecordMedicalEncounter(
    (SELECT patient_id FROM Patients WHERE last_name = 'Doe'),
    (SELECT doctor_id FROM Doctors WHERE last_name = 'Chen'),
    '2025-08-01 09:30:00', -- This date corresponds to the appointment
    'Sneezing, runny nose, itchy eyes.', 'J30.9',
    'Allergic rhinitis, unspecified.', 'Antihistamine, avoid allergens.',
    'Patient advised on environmental controls.', NULL, 'Outpatient'
);
SET @rec_id_doe_allergy = LAST_INSERT_ID();

SET @rec_id_smith_cardiac = 0;
CALL RecordMedicalEncounter(
    (SELECT patient_id FROM Patients WHERE last_name = 'Smith'),
    (SELECT doctor_id FROM Doctors WHERE last_name = 'Diaz'),
    '2025-08-01 10:30:00', -- This date corresponds to the appointment
    'No specific symptoms, routine check-up.', 'Z00.0',
    'Routine examination of adult.', 'Continue current regimen.',
    'Patient in good health.', NULL, 'Outpatient'
);
SET @rec_id_smith_cardiac = LAST_INSERT_ID();

SET @rec_id_davis_pediatric = 0;
CALL RecordMedicalEncounter(
    (SELECT patient_id FROM Patients WHERE last_name = 'Davis'),
    (SELECT doctor_id FROM Doctors WHERE last_name = 'Evans'),
    '2025-07-25 14:30:00',
    'Mild cough and congestion. Ears clear.', 'J06.9',
    'Acute upper respiratory infection, unspecified.', 'Rest, fluids.',
    'Parents advised to monitor.', NULL, 'Outpatient'
);
SET @rec_id_davis_pediatric = LAST_INSERT_ID();

SELECT 'MedicalRecords populated.' AS Status;

-- Prescriptions (using CALL, which updates Medications stock via trigger)
CALL PrescribeMedication(
    @rec_id_doe_allergy,
    (SELECT medication_id FROM Medications WHERE name = 'Paracetamol'),
    '500mg', 'Twice daily', 'Oral', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 7 DAY), 14,
    'Take with water.', (SELECT doctor_id FROM Doctors WHERE last_name = 'Chen')
);
CALL PrescribeMedication(
    @rec_id_smith_cardiac,
    (SELECT medication_id FROM Medications WHERE name = 'Lisinopril'),
    '10mg', 'Once daily', 'Oral', CURDATE(), DATE_ADD(CURDATE(), INTERVAL 30 DAY), 30,
    'Take in the morning.', (SELECT doctor_id FROM Doctors WHERE last_name = 'Diaz')
);

SELECT 'Prescriptions populated.' AS Status;

-- LabResults (using CALL)
CALL RecordLabResult(
    (SELECT patient_id FROM Patients WHERE last_name = 'Doe'),
    (SELECT test_id FROM LabTests WHERE test_name = 'Complete Blood Count (CBC)'),
    @rec_id_doe_allergy,
    'WBC: 8.5 K/uL, RBC: 4.8 M/uL', '2025-08-01 08:00:00', 'City Lab', FALSE, 'Normal results.'
);
CALL RecordLabResult(
    (SELECT patient_id FROM Patients WHERE last_name = 'Johnson'),
    (SELECT test_id FROM LabTests WHERE test_name = 'Blood Glucose (Fasting)'),
    NULL, -- Not tied to a specific encounter record at time of test
    '125 mg/dL', '2025-07-29 07:00:00', 'Regional Lab', TRUE, 'Elevated glucose. Follow-up recommended.'
);

SELECT 'LabResults populated.' AS Status;

-- Billing (using CALL, which uses triggers to update total_amount)
SET @bill_id_john = 0;
CALL CreateNewBill(
    (SELECT patient_id FROM Patients WHERE last_name = 'Doe'),
    '2025-08-01',
    '2025-08-31',
    'General consultation and CBC.',
    '[{"desc": "Consultation (Dr. Chen)", "qty": 1, "price": 80.00}, {"desc": "CBC Lab Test", "qty": 1, "price": 45.00}]',
    @bill_id_john
);
SELECT @bill_id_john AS CreatedBillForJohnDoe;

SET @bill_id_jane = 0;
CALL CreateNewBill(
    (SELECT patient_id FROM Patients WHERE last_name = 'Smith'),
    '2025-08-01',
    '2025-08-31',
    'Cardiology check-up.',
    '[{"desc": "Cardiology Consultation (Dr. Diaz)", "qty": 1, "price": 120.00}, {"desc": "ECG", "qty": 1, "price": 60.00}]',
    @bill_id_jane
);
SELECT @bill_id_jane AS CreatedBillForJaneSmith;

SET @bill_id_alice = 0;
CALL CreateNewBill(
    (SELECT patient_id FROM Patients WHERE last_name = 'Johnson'),
    '2025-07-30',
    '2025-08-30',
    'Diabetes follow-up and blood work.',
    '[{"desc": "Consultation (Dr. Chen)", "qty": 1, "price": 80.00}, {"desc": "Fasting Blood Glucose Test", "qty": 1, "price": 30.00}]',
    @bill_id_alice
);
SELECT @bill_id_alice AS CreatedBillForAliceJohnson;

SELECT 'Billing and BillItems populated.' AS Status;

-- Payments (using CALL, which updates Billing status via trigger)
-- Pay John Doe's bill in full
SET @amount_to_pay = (SELECT total_amount FROM Billing WHERE bill_id = @bill_id_john);
CALL RecordPayment(
    @bill_id_john,
    @amount_to_pay,
    'Card',
    'TXN_JD_0801_FULL'
);

-- Pay Jane Smith's bill partially
CALL RecordPayment(
    @bill_id_jane,
    75.00, -- Partial payment
    'Cash',
    'TXN_JS_0801_PART1'
);

SELECT 'Payments populated.' AS Status;

SELECT 'Initial Data Population (Seed Data) completed.' AS Status;

SELECT 'Verifying data counts...' AS Status;
SELECT 'Patients', COUNT(*) FROM Patients;
SELECT 'Doctors', COUNT(*) FROM Doctors;
SELECT 'MedicalSpecialities', COUNT(*) FROM MedicalSpecialities;
SELECT 'Appointments', COUNT(*) FROM Appointments;
SELECT 'MedicalRecords', COUNT(*) FROM MedicalRecords;
SELECT 'Prescriptions', COUNT(*) FROM Prescriptions;
SELECT 'Medications', COUNT(*) FROM Medications;
SELECT 'LabTests', COUNT(*) FROM LabTests;
SELECT 'LabResults', COUNT(*) FROM LabResults;
SELECT 'Billing', COUNT(*) FROM Billing;
SELECT 'BillItems', COUNT(*) FROM BillItems;
SELECT 'Payments', COUNT(*) FROM Payments;
SELECT 'Users', COUNT(*) FROM Users;
SELECT 'AuditLog', COUNT(*) FROM AuditLog;

SELECT 'Verifying calculated bill totals and statuses...' AS Status;
SELECT bill_id, patient_id, total_amount, paid_amount, status FROM Billing;

SELECT 'Verifying medication stock after prescriptions...' AS Status;
SELECT name, stock_quantity, reorder_level FROM Medications;

