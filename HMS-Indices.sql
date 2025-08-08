USE HealthCare_HMS;

-- Index Creation To Speed Up Common LookUps & Joins

-- Patients Table
CREATE INDEX idx_patients_last_name ON Patients (last_name);
CREATE INDEX idx_patients_phone_email ON Patients (phone_number, email);

-- Doctors Table
CREATE INDEX idx_doctors_last_name ON Doctors (last_name);
CREATE INDEX idx_doctors_specialty_id ON Doctors (specialty_id);

-- Nurses Table
CREATE INDEX idx_nurses_last_name ON Nurses (last_name);

-- Appointments Table
CREATE INDEX idx_appointments_datetime ON Appointments (appointment_datetime);
-- idx_unique_appointment (patient_id, doctor_id, appointment_datetime) already created as UNIQUE KEY

-- MedicalRecords Table
CREATE INDEX idx_medical_records_encounter_datetime ON MedicalRecords (encounter_datetime);
CREATE INDEX idx_medical_records_diagnosis_code ON MedicalRecords (diagnosis_code);

-- Prescriptions Table
CREATE INDEX idx_prescriptions_medication_id ON Prescriptions (medication_id);
CREATE INDEX idx_prescriptions_prescribed_by_doctor_id ON Prescriptions (prescribed_by_doctor_id);

-- LabResults Table
CREATE INDEX idx_lab_results_result_date ON LabResults (result_date);
CREATE INDEX idx_lab_results_test_id ON LabResults (test_id);

-- Billing Table
CREATE INDEX idx_billing_bill_date ON Billing (bill_date);
CREATE INDEX idx_billing_status ON Billing (status);

-- Payments Table
CREATE INDEX idx_payments_payment_date ON Payments (payment_date);

SELECT 'Indexes created.' AS Status;
