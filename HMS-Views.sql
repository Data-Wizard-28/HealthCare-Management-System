Use HealthCare_HMS;

SELECT 'Starting creation of Views...' AS Status;

-- View: ActivePatients
-- Description: Shows a simplified list of currently active patients.
CREATE OR REPLACE VIEW ActivePatients AS
SELECT
    patient_id,
    first_name,
    last_name,
    date_of_birth,
    gender,
    phone_number,
    email,
    registration_date
FROM
    Patients
WHERE
    status = 'Active';

SELECT 'View ActivePatients created.' AS Status;

-- View: DoctorScheduleToday
-- Description: Shows today's appointments for all active doctors.
CREATE OR REPLACE VIEW DoctorScheduleToday AS
SELECT
    A.appointment_id,
    A.appointment_datetime,
    A.reason_for_visit,
    A.status AS appointment_status,
    P.first_name AS patient_first_name,
    P.last_name AS patient_last_name,
    P.phone_number AS patient_phone,
    D.first_name AS doctor_first_name,
    D.last_name AS doctor_last_name,
    MS.specialty_name
FROM
    Appointments A
JOIN
    Patients P ON A.patient_id = P.patient_id
JOIN
    Doctors D ON A.doctor_id = D.doctor_id
JOIN
    MedicalSpecialities MS ON D.specialty_id = MS.specialty_id
WHERE
    DATE(A.appointment_datetime) = CURDATE()
ORDER BY
    D.last_name, A.appointment_datetime;

SELECT 'View DoctorScheduleToday created.' AS Status;

-- View: MedicationStockAlerts
-- Description: Lists medications with current stock below their reorder level.
CREATE OR REPLACE VIEW MedicationStockAlerts AS
SELECT
    medication_id,
    name,
    strength,
    form,
    stock_quantity,
    reorder_level,
    (reorder_level - stock_quantity) AS needed_for_reorder
FROM
    Medications
WHERE
    stock_quantity < reorder_level
ORDER BY
    needed_for_reorder DESC;

SELECT 'View MedicationStockAlerts created.' AS Status;

-- Role-Specific Views

-- View: ReceptionistPatientInfo
-- Description: Provides receptionists with essential patient info for check-in/scheduling.
-- Excludes sensitive medical history.
CREATE OR REPLACE VIEW ReceptionistPatientInfo AS
SELECT
    patient_id,
    first_name,
    last_name,
    date_of_birth,
    phone_number,
    email,
    address,
    status
FROM
    Patients;

SELECT 'View ReceptionistPatientInfo created.' AS Status;

-- View: DoctorPatientMedicalSummary
-- Description: Provides doctors with a summary view of patient medical history.
-- Can be joined with other tables for more detail if needed.
CREATE OR REPLACE VIEW DoctorPatientMedicalSummary AS
SELECT
    P.patient_id,
    P.first_name,
    P.last_name,
    P.date_of_birth,
    P.gender,
    P.blood_group,
    P.allergies,
    P.medical_history_summary,
    (SELECT COUNT(*) FROM MedicalRecords MR WHERE MR.patient_id = P.patient_id) AS total_encounters,
    (SELECT MAX(MR.encounter_datetime) FROM MedicalRecords MR WHERE MR.patient_id = P.patient_id) AS last_encounter_date
FROM
    Patients P;

SELECT 'View DoctorPatientMedicalSummary created.' AS Status;

-- View: CurrentOutstandingBills
-- Description: Shows all outstanding or partially paid bills with patient details.
CREATE OR REPLACE VIEW CurrentOutstandingBills AS
SELECT
    B.bill_id,
    P.patient_id,
    P.first_name AS patient_first_name,
    P.last_name AS patient_last_name,
    B.bill_date,
    B.total_amount,
    B.paid_amount,
    (B.total_amount - B.paid_amount) AS amount_due,
    B.due_date,
    B.status,
    B.service_details
FROM
    Billing B
JOIN
    Patients P ON B.patient_id = P.patient_id
WHERE
    B.status IN ('Outstanding', 'Partially Paid')
ORDER BY
    B.due_date ASC, B.bill_date DESC;

SELECT 'View CurrentOutstandingBills created.' AS Status;

-- Aggregation/Reporting Views

-- View: MonthlyRevenueSummary
-- Description: Aggregates total revenue from paid bills by month and year.
CREATE OR REPLACE VIEW MonthlyRevenueSummary AS
SELECT
    YEAR(bill_date) AS bill_year,
    MONTH(bill_date) AS bill_month,
    DATE_FORMAT(bill_date, '%Y-%m') AS bill_year_month,
    SUM(total_amount) AS total_billed_amount,
    SUM(paid_amount) AS total_paid_amount,
    SUM(total_amount) - SUM(paid_amount) AS total_outstanding_amount
FROM
    Billing
GROUP BY
    bill_year, bill_month
ORDER BY
    bill_year, bill_month;

SELECT 'View MonthlyRevenueSummary created.' AS Status;

-- View: DoctorActivitySummary
-- Description: Summarizes activities (appointments, records) for each doctor.
CREATE OR REPLACE VIEW DoctorActivitySummary AS
SELECT
    D.doctor_id,
    D.first_name,
    D.last_name,
    MS.specialty_name,
    COUNT(DISTINCT A.appointment_id) AS total_appointments,
    COUNT(DISTINCT MR.record_id) AS total_medical_records,
    COUNT(DISTINCT P.prescription_id) AS total_prescriptions_issued
FROM
    Doctors D
JOIN
    MedicalSpecialities MS ON D.specialty_id = MS.specialty_id
LEFT JOIN
    Appointments A ON D.doctor_id = A.doctor_id
LEFT JOIN
    MedicalRecords MR ON D.doctor_id = MR.doctor_id
LEFT JOIN
    Prescriptions P ON D.doctor_id = P.prescribed_by_doctor_id
GROUP BY
    D.doctor_id, D.first_name, D.last_name, MS.specialty_name
ORDER BY
    total_appointments DESC, total_medical_records DESC;

SELECT 'View DoctorActivitySummary created.' AS Status;

-- View: PatientDemographicsByGender
-- Description: Provides a count of patients by gender.
CREATE OR REPLACE VIEW PatientDemographicsByGender AS
SELECT
    gender,
    COUNT(patient_id) AS patient_count
FROM
    Patients
GROUP BY
    gender
ORDER BY
    patient_count DESC;

SELECT 'View PatientDemographicsByGender created.' AS Status;

SELECT 'Finished creation of Views.' AS Status;
