-- Optional examples. These mutate the demonstration account balances.
SELECT bank.deposit('100001', 1000.00, 'Demo deposit');
SELECT bank.withdraw('100002', 250.00, 'Demo withdrawal');
SELECT bank.transfer('200001', '100001', 500.00, 'Demo transfer');
SELECT * FROM bank.account_balances ORDER BY account_no;
SELECT * FROM bank.transaction_history ORDER BY occurred_at DESC;
