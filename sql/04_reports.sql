CREATE OR REPLACE VIEW bank.account_balances AS
SELECT a.account_id, a.account_no, a.account_type, a.currency_code, a.balance, a.status,
       b.branch_code, b.branch_name
FROM bank.account a JOIN bank.branch b USING (branch_id);

CREATE OR REPLACE VIEW bank.customer_accounts AS
SELECT c.customer_id, c.full_name, c.phone, a.account_no, a.account_type,
       h.holder_role, a.balance, a.currency_code, a.status, b.branch_name
FROM bank.customer c
JOIN bank.account_holder h USING (customer_id)
JOIN bank.account a USING (account_id)
JOIN bank.branch b USING (branch_id);

CREATE OR REPLACE VIEW bank.transaction_history AS
SELECT t.transaction_id, t.transaction_type,
       src.account_no AS from_account_no, dst.account_no AS to_account_no,
       t.amount, t.description, t.occurred_at
FROM bank.bank_transaction t
LEFT JOIN bank.account src ON src.account_id = t.from_account_id
LEFT JOIN bank.account dst ON dst.account_id = t.to_account_id;

-- Example reports: execute/select individually in psql or pgAdmin.
SELECT * FROM bank.account_balances ORDER BY account_no;
SELECT * FROM bank.customer_accounts ORDER BY customer_id, account_no;
SELECT * FROM bank.transaction_history ORDER BY occurred_at DESC;

-- Total balances by branch and currency.
SELECT branch_name, currency_code, SUM(balance) AS total_balance, COUNT(*) AS account_count
FROM bank.account_balances GROUP BY branch_name, currency_code ORDER BY branch_name;

-- Transaction volume by type.
SELECT transaction_type, COUNT(*) AS transaction_count, SUM(amount) AS total_amount
FROM bank.bank_transaction GROUP BY transaction_type ORDER BY transaction_type;
