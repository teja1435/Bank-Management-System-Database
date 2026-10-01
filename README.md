# Bank Management System (PostgreSQL)

A learning project based on the DBMS training report supplied as reference. It models branches, customers, accounts, joint account holders, and a transaction history in PostgreSQL. It includes integrity constraints, atomic deposit/withdrawal/transfer routines, sample data, and reporting queries.

> Educational demonstration only. It is not suitable for real banking or production financial use. It has no authentication, authorization policy, encryption, regulatory controls, or production-grade audit/security review.

## Requirements

- PostgreSQL 14 or later
- `psql` or pgAdmin

## Setup with psql

Create an empty database, then run these scripts in order from this folder:

```text
createdb bank_management
psql -d bank_management -f sql/01_schema.sql
psql -d bank_management -f sql/02_routines.sql
psql -d bank_management -f sql/03_sample_data.sql
psql -d bank_management -f sql/04_reports.sql
```

`sql/04_reports.sql` contains examples to run interactively; it creates views and prints a few reports. In pgAdmin, create a database, open Query Tool, and execute each file in the same order.

## Included features

- Branch, customer, account, and joint-holder records
- `NUMERIC` currency amounts, positive-value checks, foreign keys, uniqueness, and account status checks
- Atomic `deposit`, `withdraw`, and `transfer` routines that update balances and record matching ledger rows in one SQL statement
- Row locks during money movement; transfer locks accounts in a stable order to reduce deadlocks
- Balance and customer-account views, transaction history and summary report queries
- Sample records for learning and demonstrations

## Example operations

```sql
SELECT bank.deposit(100001, 250.00, 'Cash deposit');
SELECT bank.withdraw(100001, 50.00, 'ATM withdrawal');
SELECT bank.transfer(100001, 100002, 75.00, 'Sample transfer');
SELECT * FROM bank.account_balances ORDER BY account_no;
SELECT * FROM bank.transaction_history ORDER BY occurred_at DESC;
```

Each operation is a PostgreSQL function call. If a check fails, the statement errors and its balance and ledger changes roll back together. `deposit`, `withdraw`, and `transfer` return the generated transaction ID.

## Project structure

- `sql/01_schema.sql` — schema, tables, constraints, and indexes
- `sql/02_routines.sql` — atomic money movement functions
- `sql/03_sample_data.sql` — fictional demo data
- `sql/04_reports.sql` — reusable views and report queries
- `sql/05_demo.sql` — optional interactive transaction examples (changes demo balances)
- `docs/DATABASE_DESIGN.md` — entities, relationships, assumptions, and flow
- `LICENSE` — MIT license

## Notes

The database uses the `bank` schema. The sample data uses fictional names and values. Re-running `sql/03_sample_data.sql` will fail on duplicate primary keys; use a fresh database for a clean demonstration. The transaction table records each successful operation as one row; a transfer references both source and destination accounts. Opening balances are seeded directly as initial demo state, without transaction rows.
