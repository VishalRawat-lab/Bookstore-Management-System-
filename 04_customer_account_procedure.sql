-- Experiment 1: create a customer wallet only if opening balance >= 500.
CREATE OR REPLACE PROCEDURE create_customer_account(
 p_customer_id IN NUMBER, p_opening_balance IN NUMBER, p_account_id OUT NUMBER)
IS
 e_minimum_balance EXCEPTION;
 v_customer_count NUMBER;
 c_minimum_balance CONSTANT NUMBER := 500;
BEGIN
 SELECT COUNT(*) INTO v_customer_count FROM customers WHERE customer_id=p_customer_id;
 IF v_customer_count=0 THEN RAISE_APPLICATION_ERROR(-20010,'Customer ID does not exist.'); END IF;
 IF p_opening_balance < c_minimum_balance THEN RAISE e_minimum_balance; END IF;
 INSERT INTO wallet_accounts(customer_id,balance) VALUES(p_customer_id,p_opening_balance)
 RETURNING account_id INTO p_account_id;
 COMMIT;
 DBMS_OUTPUT.PUT_LINE('Account created. Account ID: '||p_account_id);
EXCEPTION
 WHEN e_minimum_balance THEN ROLLBACK; RAISE_APPLICATION_ERROR(-20011,'Minimum opening balance is 500.');
 WHEN VALUE_ERROR THEN ROLLBACK; RAISE_APPLICATION_ERROR(-20012,'Invalid numeric value.');
 WHEN OTHERS THEN ROLLBACK; RAISE;
END;
/
-- Test: VARIABLE new_account NUMBER; EXEC create_customer_account(1,1000,:new_account); PRINT new_account;
-- Expected failure: EXEC create_customer_account(1,200,:new_account);
