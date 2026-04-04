CREATE DATABASE cie3;
USE cie3;

CREATE TABLE accounts (
    account_id INT PRIMARY KEY,
    name VARCHAR(50),
    balance DECIMAL(10,2)
);

CREATE TABLE transactions (
    txn_id INT PRIMARY KEY,
    account_id INT,
    amount DECIMAL(10,2),
    txn_type VARCHAR(10),
    txn_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (account_id) REFERENCES accounts(account_id)
);

CREATE TABLE logs (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    message VARCHAR(200),
    time DATETIME DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$

CREATE TRIGGER check_balance
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
    DECLARE bal DECIMAL(10,2);

    SELECT balance INTO bal
    FROM accounts
    WHERE account_id = NEW.account_id;

    IF NEW.txn_type = 'Withdraw' AND NEW.amount > bal THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'not enough balance';
    END IF;
END $$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER update_balance
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    IF NEW.txn_type = 'Deposit' THEN
        UPDATE accounts
        SET balance = balance + NEW.amount
        WHERE account_id = NEW.account_id;
    ELSE
        UPDATE accounts
        SET balance = balance - NEW.amount
        WHERE account_id = NEW.account_id;
    END IF;
END $$

DELIMITER ;

DELIMITER $$

CREATE TRIGGER log_txn
AFTER INSERT ON transactions
FOR EACH ROW
BEGIN
    INSERT INTO logs(message)
    VALUES(CONCAT('txn done: ', NEW.txn_type, ' amount ', NEW.amount));
END $$

DELIMITER ;

START TRANSACTION;

LOCK TABLES accounts WRITE;

UPDATE accounts
SET balance = balance + 1000
WHERE account_id = 101;

UNLOCK TABLES;

COMMIT;

INSERT INTO accounts VALUES (101, 'Rahul', 5000);

INSERT INTO transactions VALUES (1, 101, 500, 'Deposit',2300);

INSERT INTO transactions VALUES (2, 101, 200, 'Withdraw', 1000);

SELECT * FROM accounts
SELECT * FROM transactions;
SELECT * FROM logs;
SELECT balance FROM accounts WHERE account_id = 101;
INSERT INTO transactions VALUES (3, 101, 10000, 'Withdraw', NOW());
INSERT INTO transactions VALUES (1, 101, 500, 'Deposit', NOW());
INSERT INTO transactions VALUES (2, 101, 200, 'Withdraw', NOW());
SELECT * FROM accounts;
SELECT * FROM transactions;
SELECT * FROM logs;
