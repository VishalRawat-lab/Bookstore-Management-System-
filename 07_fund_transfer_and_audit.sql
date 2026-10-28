-- Experiment 6: audit every wallet balance update.
CREATE OR REPLACE TRIGGER trg_wallet_balance_audit
AFTER UPDATE OF balance ON wallet_accounts FOR EACH ROW
WHEN (OLD.balance <> NEW.balance)
BEGIN
 INSERT INTO account_audit(account_id,old_balance,new_balance,changed_by,action_note)
 VALUES(:NEW.account_id,:OLD.balance,:NEW.balance,USER,'Wallet balance updated');
END;
/

-- Experiment 5: transfer funds, validate accounts/amount, and preserve minimum source balance.
CREATE OR REPLACE PROCEDURE transfer_funds(
 p_from_account IN NUMBER,p_to_account IN NUMBER,p_amount IN NUMBER)
IS
 v_from_balance wallet_accounts.balance%TYPE;
 v_to_balance wallet_accounts.balance%TYPE;
 c_minimum_balance CONSTANT NUMBER:=500;
 v_found NUMBER;
BEGIN
 SAVEPOINT before_transfer;
 IF p_from_account=p_to_account THEN RAISE_APPLICATION_ERROR(-20030,'Source and destination accounts must differ.'); END IF;
 IF p_amount IS NULL OR p_amount<=0 THEN RAISE_APPLICATION_ERROR(-20031,'Transfer amount must be greater than zero.'); END IF;
 SELECT COUNT(*) INTO v_found FROM wallet_accounts WHERE account_id IN (p_from_account,p_to_account);
 IF v_found<>2 THEN RAISE_APPLICATION_ERROR(-20033,'Source or destination account number is invalid.'); END IF;
 -- Lock rows in ascending account order to reduce deadlock risk.
 FOR r IN (SELECT account_id FROM wallet_accounts WHERE account_id IN(p_from_account,p_to_account) ORDER BY account_id FOR UPDATE) LOOP NULL; END LOOP;
 SELECT balance INTO v_from_balance FROM wallet_accounts WHERE account_id=p_from_account;
 SELECT balance INTO v_to_balance FROM wallet_accounts WHERE account_id=p_to_account;
 IF v_from_balance-p_amount<c_minimum_balance THEN RAISE_APPLICATION_ERROR(-20032,'Insufficient funds: source account must retain minimum balance 500.'); END IF;
 UPDATE wallet_accounts SET balance=balance-p_amount WHERE account_id=p_from_account;
 UPDATE wallet_accounts SET balance=balance+p_amount WHERE account_id=p_to_account;
 INSERT INTO fund_transfers(from_account,to_account,amount,transfer_status) VALUES(p_from_account,p_to_account,p_amount,'SUCCESS');
 COMMIT;
 DBMS_OUTPUT.PUT_LINE('Transfer successful: '||p_amount);
EXCEPTION
 WHEN OTHERS THEN ROLLBACK TO before_transfer; RAISE;
END;
/
-- Tests: EXEC transfer_funds(1,2,500);
-- SELECT * FROM account_audit ORDER BY changed_at DESC;
-- SELECT * FROM fund_transfers ORDER BY transfer_time DESC;
