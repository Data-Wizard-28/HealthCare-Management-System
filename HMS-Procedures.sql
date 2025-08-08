USE HealthCare_HMS;

SELECT 'Starting creation of Stored Procedures and Functions...' AS Status;

-- Stored Procedure: Add a New Patient
-- Description: Inserts a new patient record into the Patients table.

DELIMITER //
CREATE PROCEDURE AddNewPatient(
    IN p_first_name VARCHAR(100),
    IN p_last_name VARCHAR(100),
    IN p_date_of_birth DATE,
    IN p_gender ENUM('Male', 'Female', 'Other'),
    IN p_blood_group VARCHAR(10),
    IN p_address TEXT,
    IN p_phone_number VARCHAR(20),
    IN p_email VARCHAR(255),
    IN p_emergency_contact_name VARCHAR(200),
    IN p_emergency_contact_phone VARCHAR(20),
    IN p_allergies TEXT,
    IN p_medical_history_summary TEXT
)
BEGIN
    INSERT INTO Patients (
        first_name, last_name, date_of_birth, gender, blood_group, address,
        phone_number, email, emergency_contact_name, emergency_contact_phone,
        allergies, medical_history_summary
    ) VALUES (
        p_first_name, p_last_name, p_date_of_birth, p_gender, p_blood_group, p_address,
        p_phone_number, p_email, p_emergency_contact_name, p_emergency_contact_phone,
        p_allergies, p_medical_history_summary
    );
    SELECT LAST_INSERT_ID() AS new_patient_id; -- Return the ID of the newly inserted patient
END //
DELIMITER ;

SELECT 'Stored Procedure AddNewPatient created.' AS Status;

-- Stored Procedure: Schedule an Appointment
-- Description: Schedules a new appointment for a patient with a doctor.

DELIMITER //
CREATE PROCEDURE ScheduleAppointment(
    IN p_patient_id INT,
    IN p_doctor_id INT,
    IN p_appointment_datetime DATETIME,
    IN p_reason_for_visit TEXT
)
BEGIN
    INSERT INTO Appointments (
        patient_id, doctor_id, appointment_datetime, reason_for_visit
    ) VALUES (
        p_patient_id, p_doctor_id, p_appointment_datetime, p_reason_for_visit
    );
    SELECT LAST_INSERT_ID() AS new_appointment_id;
END //
DELIMITER ;

SELECT 'Stored Procedure ScheduleAppointment created.' AS Status;

-- Stored Procedure: Record Medical Encounter
-- Description: Creates a new medical record for a patient's encounter.

DELIMITER //
CREATE PROCEDURE RecordMedicalEncounter(
    IN p_patient_id INT,
    IN p_doctor_id INT,
    IN p_encounter_datetime DATETIME,
    IN p_symptoms TEXT,
    IN p_diagnosis_code VARCHAR(50),
    IN p_diagnosis_description TEXT,
    IN p_treatment_plan TEXT,
    IN p_notes TEXT,
    IN p_follow_up_date DATE,
    IN p_record_type VARCHAR(50)
)
BEGIN
    INSERT INTO MedicalRecords (
        patient_id, doctor_id, encounter_datetime, symptoms, diagnosis_code,
        diagnosis_description, treatment_plan, notes, follow_up_date, record_type
    ) VALUES (
        p_patient_id, p_doctor_id, p_encounter_datetime, p_symptoms, p_diagnosis_code,
        p_diagnosis_description, p_treatment_plan, p_notes, p_follow_up_date, p_record_type
    );
    SELECT LAST_INSERT_ID() AS new_record_id;
END //
DELIMITER ;

SELECT 'Stored Procedure RecordMedicalEncounter created.' AS Status;

-- Stored Procedure: Prescribe Medication
-- Description: Adds a new prescription to a patient's medical record.

DELIMITER //
CREATE PROCEDURE PrescribeMedication(
    IN p_record_id INT,
    IN p_medication_id INT,
    IN p_dosage VARCHAR(100),
    IN p_frequency VARCHAR(100),
    IN p_route VARCHAR(100),
    IN p_start_date DATE,
    IN p_end_date DATE,
    IN p_quantity INT,
    IN p_instructions TEXT,
    IN p_prescribed_by_doctor_id INT
)
BEGIN
    INSERT INTO Prescriptions (
        record_id, medication_id, dosage, frequency, route, start_date,
        end_date, quantity, instructions, prescribed_by_doctor_id
    ) VALUES (
        p_record_id, p_medication_id, p_dosage, p_frequency, p_route, p_start_date,
        p_end_date, p_quantity, p_instructions, p_prescribed_by_doctor_id
    );
    SELECT LAST_INSERT_ID() AS new_prescription_id;
END //
DELIMITER ;

SELECT 'Stored Procedure PrescribeMedication created.' AS Status;

-- Stored Procedure: RecordLabResult
-- Description: Records a lab test result for a patient.

DELIMITER //
CREATE PROCEDURE RecordLabResult(
    IN p_patient_id INT,
    IN p_test_id INT,
    IN p_record_id INT, -- Can be NULL if not tied to a specific encounter
    IN p_result_value VARCHAR(255),
    IN p_result_date DATETIME,
    IN p_performed_by VARCHAR(255),
    IN p_is_abnormal BOOLEAN,
    IN p_notes TEXT
)
BEGIN
    INSERT INTO LabResults (
        patient_id, test_id, record_id, result_value, result_date,
        performed_by, is_abnormal, notes
    ) VALUES (
        p_patient_id, p_test_id, p_record_id, p_result_value, p_result_date,
        p_performed_by, p_is_abnormal, p_notes
    );
    SELECT LAST_INSERT_ID() AS new_lab_result_id;
END //
DELIMITER ;

SELECT 'Stored Procedure RecordLabResult created.' AS Status;

-- Stored Procedure: CreateNewBill
-- Description: Creates a new bill for a patient and optionally adds initial bill items.
-- This procedure demonstrates a transaction.

DELIMITER //
CREATE PROCEDURE CreateNewBill(
    IN p_patient_id INT,
    IN p_bill_date DATE,
    IN p_due_date DATE,
    IN p_service_details TEXT,
    IN p_item_descriptions JSON, -- Expects a JSON array of objects: [{"desc": "...", "qty": N, "price": M.NN}]
    OUT o_bill_id INT
)
BEGIN
    DECLARE total_bill_amount DECIMAL(10, 2) DEFAULT 0.00;
    DECLARE item_count INT;
    DECLARE i INT DEFAULT 0;
    DECLARE current_desc VARCHAR(255);
    DECLARE current_qty INT;
    DECLARE current_price DECIMAL(10, 2);
    
    -- Declare a handler for SQLEXCEPTIONS (any SQL error)
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Rollback if any error occurs
        ROLLBACK;
        -- Indicate failure by setting o_bill_id to NULL
        SET o_bill_id = NULL;
        -- Re-raise the error or signal a custom message
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error creating bill or bill items.';
    END;

    -- Start Transaction for atomicity
    START TRANSACTION;

    -- 1. Insert into Billing table
    INSERT INTO Billing (patient_id, bill_date, total_amount, due_date, service_details)
    VALUES (p_patient_id, p_bill_date, 0.00, p_due_date, p_service_details);

    SET o_bill_id = LAST_INSERT_ID(); -- Get the ID of the new bill

    -- 2. Loop through bill items if provided
    IF p_item_descriptions IS NOT NULL THEN
        SET item_count = JSON_LENGTH(p_item_descriptions);
        WHILE i < item_count DO
            SET current_desc = JSON_UNQUOTE(JSON_EXTRACT(p_item_descriptions, CONCAT('$[', i, '].desc')));
            SET current_qty = JSON_UNQUOTE(JSON_EXTRACT(p_item_descriptions, CONCAT('$[', i, '].qty')));
            SET current_price = JSON_UNQUOTE(JSON_EXTRACT(p_item_descriptions, CONCAT('$[', i, '].price')));

            INSERT INTO BillItems (bill_id, service_type, item_description, quantity, unit_price)
            VALUES (o_bill_id, 'Service', current_desc, current_qty, current_price);

            SET total_bill_amount = total_bill_amount + (current_qty * current_price);
            SET i = i + 1;
        END WHILE;
    END IF;

    -- 3. Update the total_amount in the Billing table
    UPDATE Billing
    SET total_amount = total_bill_amount
    WHERE bill_id = o_bill_id;

    -- Commit transaction if all operations successful
    COMMIT;

END //
DELIMITER ;

SELECT 'Stored Procedure CreateNewBill created.' AS Status;

-- Stored Procedure: GetPatientMedicalHistory
-- Description: Retrieves a comprehensive medical history for a given patient.

DELIMITER //
CREATE PROCEDURE GetPatientMedicalHistory(
    IN p_patient_id INT
)
BEGIN
    -- Patient Details
    SELECT 'Patient Details' AS Section,
           patient_id, first_name, last_name, date_of_birth, gender, blood_group,
           phone_number, email, allergies, medical_history_summary
    FROM Patients
    WHERE patient_id = p_patient_id;

    -- Medical Records (Encounters)
    SELECT 'Medical Records' AS Section,
           mr.record_id, mr.encounter_datetime, mr.record_type, mr.symptoms,
           mr.diagnosis_description, mr.treatment_plan, mr.notes, mr.follow_up_date,
           d.first_name AS doctor_first_name, d.last_name AS doctor_last_name
    FROM MedicalRecords mr
    JOIN Doctors d ON mr.doctor_id = d.doctor_id
    WHERE mr.patient_id = p_patient_id
    ORDER BY mr.encounter_datetime DESC;

    -- Prescriptions
    SELECT 'Prescriptions' AS Section,
           p.prescription_id, m.name AS medication_name, p.dosage, p.frequency, p.start_date, p.end_date, p.quantity,
           d.first_name AS prescribed_by_first_name, d.last_name AS prescribed_by_last_name,
           mr.encounter_datetime AS prescribed_during_encounter
    FROM Prescriptions p
    JOIN Medications m ON p.medication_id = m.medication_id
    LEFT JOIN MedicalRecords mr ON p.record_id = mr.record_id
    JOIN Doctors d ON p.prescribed_by_doctor_id = d.doctor_id
    WHERE p.record_id IN (SELECT record_id FROM MedicalRecords WHERE patient_id = p_patient_id)
    ORDER BY p.start_date DESC;

    -- Lab Results
    SELECT 'Lab Results' AS Section,
           lr.result_id, lt.test_name, lr.result_value, lt.unit, lr.result_date, lr.is_abnormal,
           lr.notes, lr.performed_by, mr.encounter_datetime AS associated_encounter_datetime
    FROM LabResults lr
    JOIN LabTests lt ON lr.test_id = lt.test_id
    LEFT JOIN MedicalRecords mr ON lr.record_id = mr.record_id
    WHERE lr.patient_id = p_patient_id
    ORDER BY lr.result_date DESC;

    -- Billing and Payments (simplified view)
    SELECT 'Billing Summary' AS Section,
           b.bill_id, b.bill_date, b.total_amount, b.paid_amount, b.status, b.due_date,
           SUM(py.amount_paid) AS total_payments_for_bill
    FROM Billing b
    LEFT JOIN Payments py ON b.bill_id = py.bill_id
    WHERE b.patient_id = p_patient_id
    GROUP BY b.bill_id
    ORDER BY b.bill_date DESC;
    
    -- Appointments
    SELECT 'Appointments' AS Section,
           a.appointment_id, a.appointment_datetime, a.reason_for_visit, a.status,
           d.first_name AS doctor_first_name, d.last_name AS doctor_last_name, ms.specialty_name
    FROM Appointments a
    JOIN Doctors d ON a.doctor_id = d.doctor_id
    JOIN MedicalSpecialities ms ON d.specialty_id = ms.specialty_id
    WHERE a.patient_id = p_patient_id
    ORDER BY a.appointment_datetime DESC;

END //
DELIMITER ;

SELECT 'Stored Procedure GetPatientMedicalHistory created.' AS Status;

-- Stored Procedure: RecordPayment
-- Description: Records a payment for a bill and updates the bill's paid_amount and status.

DELIMITER //
CREATE PROCEDURE RecordPayment(
    IN p_bill_id INT,
    IN p_amount_paid DECIMAL(10, 2),
    IN p_payment_method ENUM('Cash', 'Card', 'Bank Transfer', 'Insurance', 'Other'),
    IN p_transaction_id VARCHAR(100)
)
BEGIN
    DECLARE v_total_amount DECIMAL(10, 2);
    DECLARE v_current_paid_amount DECIMAL(10, 2);

    -- Declare an error handler for any SQL exception
    -- If an error occurs, it will automatically jump to this block,
    -- execute the rollback, and then exit the procedure.
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        -- Rollback the transaction on any error
        ROLLBACK;
        -- Re-raise a custom error message
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Error processing payment.';
    END;

    -- Start the transaction
    START TRANSACTION;

    -- 1. Insert the payment record
    INSERT INTO Payments (bill_id, amount_paid, payment_method, transaction_id)
    VALUES (p_bill_id, p_amount_paid, p_payment_method, p_transaction_id);

    -- 2. Update the Billing table's paid_amount
    -- Lock the row to prevent other sessions from modifying it
    SELECT total_amount, paid_amount INTO v_total_amount, v_current_paid_amount
    FROM Billing WHERE bill_id = p_bill_id FOR UPDATE;

    UPDATE Billing
    SET paid_amount = v_current_paid_amount + p_amount_paid,
        status = CASE
            WHEN (v_current_paid_amount + p_amount_paid) >= v_total_amount THEN 'Paid'
            WHEN (v_current_paid_amount + p_amount_paid) > 0 THEN 'Partially Paid'
            ELSE 'Outstanding'
        END
    WHERE bill_id = p_bill_id;

    -- Commit the transaction if everything was successful
    COMMIT;

END //
DELIMITER ;

SELECT 'Stored Procedure RecordPayment created.' AS Status;

SELECT 'Finished creation of Stored Procedures.' AS Status;
