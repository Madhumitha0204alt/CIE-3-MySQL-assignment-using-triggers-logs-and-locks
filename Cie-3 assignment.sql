-- Bank Transaction Monitoring System
-- This project uses triggers, logs and locks

CREATE DATABASE CIE_3_ASSIGNMENT;
USE CIE_3_ASSIGNMENT;
-- 1. Creating tables

CREATE TABLE accounts (
    account_id INT PRIMARY KEY,
    name VARCHAR(100),
    balance DECIMAL(10,2) DEFAULT 0
);

CREATE TABLE transactions (
    txn_id INT PRIMARY KEY,
    account_id INT,
    amount DECIMAL(10,2),
    txn_type VARCHAR(10),  -- Deposit / Withdraw
    txn_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

CREATE TABLE logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    message VARCHAR(255),
    log_time DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- 2. Trigger to check balance before withdraw

DELIMITER $$

CREATE TRIGGER trg_check_balance
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
    DECLARE current_balance DECIMAL(10,2);

    -- getting current balance
    SELECT balance INTO current_balance
    FROM accounts
    WHERE account_id = NEW.account_id;

    -- checking if withdrawal is possible
    IF NEW.txn_type = 'Withdraw' AND NEW.amount > current_balance THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Insufficient Balance!';
    END IF;
END $$

DELIMITER ;

-- 3. Trigger to update balance after transaction


DELIMITER $$

CREATE TRIGGER trg_update_balance
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    IF NEW.txn_type = 'Deposit' THEN
        UPDATE accounts
        SET balance = balance + NEW.amount
        WHERE account_id = NEW.account_id;

    ELSEIF NEW.txn_type = 'Withdraw' THEN
        UPDATE accounts
        SET balance = balance - NEW.amount
        WHERE account_id = NEW.account_id;
    END IF;
END $$

DELIMITER ;


-- 4. Trigger to log transactions

DELIMITER $$

CREATE TRIGGER trg_log_transaction
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    DECLARE msg VARCHAR(255);

    IF NEW.txn_type = 'Deposit' THEN
        SET msg = CONCAT('Transaction of ', NEW.amount,
                         ' deposited for account ', NEW.account_id);
    ELSE
        SET msg = CONCAT('Transaction of ', NEW.amount,
                         ' withdrawn from account ', NEW.account_id);
    END IF;

    INSERT INTO logs(message) VALUES(msg);
END $$

DELIMITER ;


-- 5. Locking example (to avoid conflicts)


START TRANSACTION;

LOCK TABLES accounts WRITE;

-- updating balance safely
UPDATE accounts
SET balance = balance + 1000
WHERE account_id = 101;

UNLOCK TABLES;

COMMIT;


-- 6. Sample data for testing


INSERT INTO accounts VALUES (101, 'Rahul', 5000);

-- deposit
INSERT INTO transactions VALUES (1, 101, 500, 'Deposit', NOW());

-- withdraw
INSERT INTO transactions VALUES (2, 101, 200, 'Withdraw', NOW());

