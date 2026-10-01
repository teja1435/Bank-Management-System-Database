-- Run against an empty database. All objects are namespaced in schema bank.
CREATE SCHEMA bank;

CREATE TABLE bank.branch (
    branch_id       BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    branch_code     VARCHAR(12) NOT NULL UNIQUE,
    branch_name     VARCHAR(100) NOT NULL,
    address         TEXT NOT NULL,
    city            VARCHAR(80) NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE bank.customer (
    customer_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    full_name       VARCHAR(120) NOT NULL,
    email           VARCHAR(254) UNIQUE,
    phone           VARCHAR(24) NOT NULL UNIQUE,
    address         TEXT NOT NULL,
    date_of_birth   DATE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT customer_dob_not_future CHECK (date_of_birth IS NULL OR date_of_birth <= CURRENT_DATE)
);

CREATE TABLE bank.account (
    account_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    account_no      VARCHAR(20) NOT NULL UNIQUE,
    branch_id       BIGINT NOT NULL REFERENCES bank.branch(branch_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    account_type    VARCHAR(16) NOT NULL CHECK (account_type IN ('savings', 'current')),
    currency_code   CHAR(3) NOT NULL DEFAULT 'INR',
    balance         NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (balance >= 0),
    status          VARCHAR(12) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'frozen', 'closed')),
    opened_on       DATE NOT NULL DEFAULT CURRENT_DATE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE bank.account_holder (
    account_id      BIGINT NOT NULL REFERENCES bank.account(account_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    customer_id     BIGINT NOT NULL REFERENCES bank.customer(customer_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    holder_role     VARCHAR(12) NOT NULL DEFAULT 'owner' CHECK (holder_role IN ('owner', 'joint')),
    added_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (account_id, customer_id)
);

CREATE TABLE bank.bank_transaction (
    transaction_id  BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    transaction_type VARCHAR(12) NOT NULL CHECK (transaction_type IN ('deposit', 'withdrawal', 'transfer')),
    from_account_id BIGINT REFERENCES bank.account(account_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    to_account_id   BIGINT REFERENCES bank.account(account_id) ON UPDATE RESTRICT ON DELETE RESTRICT,
    amount          NUMERIC(14,2) NOT NULL CHECK (amount > 0),
    description     VARCHAR(240),
    occurred_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT transaction_account_shape CHECK (
      (transaction_type = 'deposit' AND from_account_id IS NULL AND to_account_id IS NOT NULL) OR
      (transaction_type = 'withdrawal' AND from_account_id IS NOT NULL AND to_account_id IS NULL) OR
      (transaction_type = 'transfer' AND from_account_id IS NOT NULL AND to_account_id IS NOT NULL AND from_account_id <> to_account_id)
    )
);

CREATE INDEX account_branch_idx ON bank.account(branch_id);
CREATE INDEX holder_customer_idx ON bank.account_holder(customer_id);
CREATE INDEX transaction_from_time_idx ON bank.bank_transaction(from_account_id, occurred_at DESC);
CREATE INDEX transaction_to_time_idx ON bank.bank_transaction(to_account_id, occurred_at DESC);
