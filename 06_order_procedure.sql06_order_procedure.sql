-- Experiment 4: order header/detail inserts and stock decrement in PL/SQL.
CREATE OR REPLACE PROCEDURE place_book_order(
 p_customer_id IN NUMBER, p_book_id IN NUMBER, p_quantity IN NUMBER,
 p_order_id OUT NUMBER, p_total_amount OUT NUMBER)
IS
 v_price books.price%TYPE; v_stock books.stock_qty%TYPE;
 v_subtotal NUMBER(12,2); v_discount NUMBER(12,2); v_customer_count NUMBER;
BEGIN
 SAVEPOINT before_order;
 IF p_quantity IS NULL OR p_quantity<=0 THEN RAISE_APPLICATION_ERROR(-20020,'Quantity must be greater than zero.'); END IF;
 SELECT COUNT(*) INTO v_customer_count FROM customers WHERE customer_id=p_customer_id;
 IF v_customer_count=0 THEN RAISE_APPLICATION_ERROR(-20021,'Customer ID does not exist.'); END IF;
 SELECT price,stock_qty INTO v_price,v_stock FROM books WHERE book_id=p_book_id FOR UPDATE;
 IF v_stock<p_quantity THEN RAISE_APPLICATION_ERROR(-20022,'Not enough stock for this order.'); END IF;
 v_subtotal:=v_price*p_quantity;
 v_discount:=calculate_discount(v_subtotal);
 p_total_amount:=v_subtotal-v_discount;
 INSERT INTO book_orders(customer_id,subtotal,discount_amount,total_amount)
 VALUES(p_customer_id,v_subtotal,v_discount,p_total_amount) RETURNING order_id INTO p_order_id;
 INSERT INTO order_items(order_id,book_id,quantity,unit_price,line_total)
 VALUES(p_order_id,p_book_id,p_quantity,v_price,v_subtotal);
 UPDATE books SET stock_qty=stock_qty-p_quantity WHERE book_id=p_book_id;
 COMMIT;
 DBMS_OUTPUT.PUT_LINE('Order placed. Order ID: '||p_order_id);
 DBMS_OUTPUT.PUT_LINE('Subtotal: '||v_subtotal||', discount: '||v_discount||', total: '||p_total_amount);
EXCEPTION
 WHEN NO_DATA_FOUND THEN ROLLBACK TO before_order; RAISE_APPLICATION_ERROR(-20023,'Book ID does not exist.');
 WHEN OTHERS THEN ROLLBACK TO before_order; RAISE;
END;
/
-- Test: VARIABLE order_no NUMBER; VARIABLE order_total NUMBER;
-- EXEC place_book_order(1,1,2,:order_no,:order_total); PRINT order_no; PRINT order_total;
