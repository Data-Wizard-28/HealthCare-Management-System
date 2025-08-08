USE HealthCare_HMS;

SELECT 'Starting creation of Triggers...' AS Status;

-- Creating a generic AuditLog table
CREATE TABLE IF NOT EXISTS AuditLog (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    record_id INT COMMENT 'ID of the record affected in the original table',
    action_type ENUM('INSERT', 'UPDATE', 'DELETE') NOT NULL,
    action_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    user_context VARCHAR(255) COMMENT 'MySQL user who performed the action',
    old_value JSON COMMENT 'JSON representation of the old row data (for UPDATE/DELETE)',
    new_value JSON COMMENT 'JSON representation of the new row data (for INSERT/UPDATE)'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
SELECT 'Table AuditLog created.' AS Status;

-- Trigger for BEFORE INSERT on Patients
DELIMITER //
CREATE TRIGGER trg_patients_before_insert
BEFORE INSERT ON Patients
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (table_name, record_id, action_type, user_context, new_value)
    VALUES (
        'Patients',
        NEW.patient_id, -- patient_id might not be generated yet for AUTO_INCREMENT, so handle AFTER INSERT or use LAST_INSERT_ID() in a procedure
        'INSERT',
        CURRENT_USER(),
        JSON_OBJECT(
            'first_name', NEW.first_name,
            'last_name', NEW.last_name,
            'date_of_birth', NEW.date_of_birth,
            'gender', NEW.gender,
            'phone_number', NEW.phone_number,
            'email', NEW.email,
            'status', NEW.status
            -- Add other relevant columns
        )
    );
END //
DELIMITER ;
SELECT 'Trigger trg_patients_before_insert created.' AS Status;

-- Trigger for AFTER INSERT on Patients (to capture auto-generated ID)
-- This is often preferred for auto_increment IDs when the trigger needs the actual ID.
DELIMITER //
CREATE TRIGGER trg_patients_after_insert
AFTER INSERT ON Patients
FOR EACH ROW
BEGIN
    UPDATE AuditLog
    SET record_id = NEW.patient_id -- Update the record_id with the actual ID
    WHERE log_id = LAST_INSERT_ID(); -- Get the ID of the last audit log entry for this transaction
END //
DELIMITER ;
SELECT 'Trigger trg_patients_after_insert created.' AS Status;

-- Trigger for BEFORE UPDATE on Patients
DELIMITER //
CREATE TRIGGER trg_patients_before_update
BEFORE UPDATE ON Patients
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (table_name, record_id, action_type, user_context, old_value, new_value)
    VALUES (
        'Patients',
        OLD.patient_id,
        'UPDATE',
        CURRENT_USER(),
        JSON_OBJECT(
            'first_name', OLD.first_name,
            'last_name', OLD.last_name,
            'date_of_birth', OLD.date_of_birth,
            'gender', OLD.gender,
            'phone_number', OLD.phone_number,
            'email', OLD.email,
            'status', OLD.status
            -- Add other relevant columns
        ),
        JSON_OBJECT(
            'first_name', NEW.first_name,
            'last_name', NEW.last_name,
            'date_of_birth', NEW.date_of_birth,
            'gender', NEW.gender,
            'phone_number', NEW.phone_number,
            'email', NEW.email,
            'status', NEW.status
            -- Add other relevant columns
        )
    );
END //
DELIMITER ;
SELECT 'Trigger trg_patients_before_update created.' AS Status;

-- Trigger for BEFORE DELETE on Patients
DELIMITER //
CREATE TRIGGER trg_patients_before_delete
BEFORE DELETE ON Patients
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (table_name, record_id, action_type, user_context, old_value)
    VALUES (
        'Patients',
        OLD.patient_id,
        'DELETE',
        CURRENT_USER(),
        JSON_OBJECT(
            'first_name', OLD.first_name,
            'last_name', OLD.last_name,
            'date_of_birth', OLD.date_of_birth,
            'gender', OLD.gender,
            'phone_number', OLD.phone_number,
            'email', OLD.email,
            'status', OLD.status
            -- Add other relevant columns
        )
    );
END //
DELIMITER ;
SELECT 'Trigger trg_patients_before_delete created.' AS Status;

-- Inventory Management Trigger
DELIMITER //
CREATE TRIGGER trg_prescriptions_after_insert_update_stock
AFTER INSERT ON Prescriptions
FOR EACH ROW
BEGIN
    -- Decrease stock_quantity for the prescribed medication
    UPDATE Medications
    SET stock_quantity = stock_quantity - NEW.quantity
    WHERE medication_id = NEW.medication_id
    AND stock_quantity >= NEW.quantity; -- Prevent negative stock if logic in app layer isn't strict
END //
DELIMITER ;
SELECT 'Trigger trg_prescriptions_after_insert_update_stock created.' AS Status;

-- Bill Total Update Trigger

-- Helper procedure to recalculate bill total
DELIMITER //
CREATE PROCEDURE RecalculateBillTotal(IN p_bill_id INT)
BEGIN
    DECLARE new_total DECIMAL(10, 2);
    SELECT SUM(item_amount) INTO new_total
    FROM BillItems
    WHERE bill_id = p_bill_id;

    UPDATE Billing
    SET total_amount = COALESCE(new_total, 0) -- Handle case where no items exist (bill might be 0)
    WHERE bill_id = p_bill_id;
END //
DELIMITER ;
SELECT 'Helper procedure RecalculateBillTotal created.' AS Status;

-- Trigger for AFTER INSERT on BillItems
DELIMITER //
CREATE TRIGGER trg_bill_items_after_insert
AFTER INSERT ON BillItems
FOR EACH ROW
BEGIN
    CALL RecalculateBillTotal(NEW.bill_id);
END //
DELIMITER ;
SELECT 'Trigger trg_bill_items_after_insert created.' AS Status;

-- Trigger for AFTER UPDATE on BillItems (if quantity or unit_price changes)
DELIMITER //
CREATE TRIGGER trg_bill_items_after_update
AFTER UPDATE ON BillItems
FOR EACH ROW
BEGIN
    IF OLD.quantity <> NEW.quantity OR OLD.unit_price <> NEW.unit_price THEN
        CALL RecalculateBillTotal(NEW.bill_id);
    END IF;
END //
DELIMITER ;
SELECT 'Trigger trg_bill_items_after_update created.' AS Status;

-- Trigger for AFTER DELETE on BillItems
DELIMITER //
CREATE TRIGGER trg_bill_items_after_delete
AFTER DELETE ON BillItems
FOR EACH ROW
BEGIN
    CALL RecalculateBillTotal(OLD.bill_id);
END //
DELIMITER ;
SELECT 'Trigger trg_bill_items_after_delete created.' AS Status;

-- Reset DELIMITER back to default
DELIMITER ;

SELECT 'Finished creation of Triggers.' AS Status;
