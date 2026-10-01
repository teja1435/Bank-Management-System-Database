-- Fictional sample records only. Intended for an empty database after scripts 01 and 02.
INSERT INTO bank.branch (branch_code, branch_name, address, city) VALUES
 ('LPU001', 'University Road Branch', 'University Road', 'Phagwara'),
 ('JAL001', 'City Centre Branch', 'Model Town', 'Jalandhar');

INSERT INTO bank.customer (full_name, email, phone, address, date_of_birth) VALUES
 ('Aarav Sharma', 'aarav@example.test', '+910000000001', 'Phagwara, Punjab', '2002-04-14'),
 ('Meera Patel', 'meera@example.test', '+910000000002', 'Jalandhar, Punjab', '2001-09-22'),
 ('Kabir Singh', 'kabir@example.test', '+910000000003', 'Ludhiana, Punjab', '2000-12-03');

INSERT INTO bank.account (account_no, branch_id, account_type, balance) VALUES
 ('100001', (SELECT branch_id FROM bank.branch WHERE branch_code='LPU001'), 'savings', 25000.00),
 ('100002', (SELECT branch_id FROM bank.branch WHERE branch_code='LPU001'), 'savings', 12000.00),
 ('200001', (SELECT branch_id FROM bank.branch WHERE branch_code='JAL001'), 'current', 50000.00);

INSERT INTO bank.account_holder (account_id, customer_id, holder_role)
SELECT a.account_id, c.customer_id, 'owner'
FROM (VALUES ('100001','aarav@example.test'), ('100002','meera@example.test'), ('200001','kabir@example.test')) AS x(account_no,email)
JOIN bank.account a USING (account_no)
JOIN bank.customer c USING (email);

-- Demo seed ledger operations through the same routines used by the application.
SELECT bank.deposit('100001', 500.00, 'Opening demo activity');
SELECT bank.withdraw('200001', 250.00, 'Opening demo activity');
SELECT bank.transfer('100001', '100002', 125.00, 'Opening demo activity');
