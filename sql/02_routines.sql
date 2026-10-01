-- Each function is one atomic SQL statement from the caller's point of view.
CREATE OR REPLACE FUNCTION bank.deposit(p_account_no VARCHAR, p_amount NUMERIC, p_description VARCHAR DEFAULT NULL)
RETURNS BIGINT LANGUAGE plpgsql AS $$
DECLARE v_account_id BIGINT; v_transaction_id BIGINT;
BEGIN
  IF p_amount IS NULL OR p_amount <= 0 THEN RAISE EXCEPTION 'Amount must be greater than zero'; END IF;
  SELECT account_id INTO v_account_id FROM bank.account
    WHERE account_no = p_account_no AND status = 'active' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Active account % not found', p_account_no; END IF;
  UPDATE bank.account SET balance = balance + p_amount WHERE account_id = v_account_id;
  INSERT INTO bank.bank_transaction(transaction_type, to_account_id, amount, description)
    VALUES ('deposit', v_account_id, p_amount, p_description) RETURNING transaction_id INTO v_transaction_id;
  RETURN v_transaction_id;
END; $$;

CREATE OR REPLACE FUNCTION bank.withdraw(p_account_no VARCHAR, p_amount NUMERIC, p_description VARCHAR DEFAULT NULL)
RETURNS BIGINT LANGUAGE plpgsql AS $$
DECLARE v_account_id BIGINT; v_balance NUMERIC(14,2); v_transaction_id BIGINT;
BEGIN
  IF p_amount IS NULL OR p_amount <= 0 THEN RAISE EXCEPTION 'Amount must be greater than zero'; END IF;
  SELECT account_id, balance INTO v_account_id, v_balance FROM bank.account
    WHERE account_no = p_account_no AND status = 'active' FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Active account % not found', p_account_no; END IF;
  IF v_balance < p_amount THEN RAISE EXCEPTION 'Insufficient funds'; END IF;
  UPDATE bank.account SET balance = balance - p_amount WHERE account_id = v_account_id;
  INSERT INTO bank.bank_transaction(transaction_type, from_account_id, amount, description)
    VALUES ('withdrawal', v_account_id, p_amount, p_description) RETURNING transaction_id INTO v_transaction_id;
  RETURN v_transaction_id;
END; $$;

CREATE OR REPLACE FUNCTION bank.transfer(p_from_account_no VARCHAR, p_to_account_no VARCHAR, p_amount NUMERIC, p_description VARCHAR DEFAULT NULL)
RETURNS BIGINT LANGUAGE plpgsql AS $$
DECLARE v_from_id BIGINT; v_to_id BIGINT; v_first BIGINT; v_second BIGINT;
        v_from_balance NUMERIC(14,2); v_from_status VARCHAR(12); v_to_status VARCHAR(12); v_transaction_id BIGINT;
BEGIN
  IF p_amount IS NULL OR p_amount <= 0 THEN RAISE EXCEPTION 'Amount must be greater than zero'; END IF;
  IF p_from_account_no = p_to_account_no THEN RAISE EXCEPTION 'Source and destination must differ'; END IF;
  SELECT account_id INTO v_from_id FROM bank.account WHERE account_no = p_from_account_no;
  SELECT account_id INTO v_to_id FROM bank.account WHERE account_no = p_to_account_no;
  IF v_from_id IS NULL OR v_to_id IS NULL THEN RAISE EXCEPTION 'Source or destination account not found'; END IF;
  -- Lock both rows by ascending internal ID to reduce deadlocks between opposite transfers.
  v_first := LEAST(v_from_id, v_to_id); v_second := GREATEST(v_from_id, v_to_id);
  PERFORM 1 FROM bank.account WHERE account_id = v_first FOR UPDATE;
  PERFORM 1 FROM bank.account WHERE account_id = v_second FOR UPDATE;
  SELECT balance, status INTO v_from_balance, v_from_status FROM bank.account WHERE account_id = v_from_id;
  SELECT status INTO v_to_status FROM bank.account WHERE account_id = v_to_id;
  IF v_from_status <> 'active' OR v_to_status <> 'active' THEN RAISE EXCEPTION 'Both accounts must be active'; END IF;
  IF v_from_balance < p_amount THEN RAISE EXCEPTION 'Insufficient funds'; END IF;
  UPDATE bank.account SET balance = balance - p_amount WHERE account_id = v_from_id;
  UPDATE bank.account SET balance = balance + p_amount WHERE account_id = v_to_id;
  INSERT INTO bank.bank_transaction(transaction_type, from_account_id, to_account_id, amount, description)
    VALUES ('transfer', v_from_id, v_to_id, p_amount, p_description) RETURNING transaction_id INTO v_transaction_id;
  RETURN v_transaction_id;
END; $$;
