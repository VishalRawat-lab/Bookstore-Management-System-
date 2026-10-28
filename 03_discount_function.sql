CREATE OR REPLACE FUNCTION calculate_discount(p_purchase_amount IN NUMBER)
RETURN NUMBER IS
BEGIN
 IF p_purchase_amount IS NULL OR p_purchase_amount < 0 THEN
  RAISE_APPLICATION_ERROR(-20001, 'Purchase amount cannot be negative or null.');
 ELSIF p_purchase_amount >= 2500 THEN
  RETURN ROUND(p_purchase_amount * 0.10, 2);
 ELSIF p_purchase_amount >= 1000 THEN
  RETURN ROUND(p_purchase_amount * 0.05, 2);
 ELSE
  RETURN 0;
 END IF;
END;
/
SELECT 800 purchase_amount, calculate_discount(800) discount FROM dual
UNION ALL SELECT 1500, calculate_discount(1500) FROM dual
UNION ALL SELECT 3000, calculate_discount(3000) FROM dual;
