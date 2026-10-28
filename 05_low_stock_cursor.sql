-- Experiment 2: explicit cursor low-stock report.
CREATE OR REPLACE PROCEDURE print_low_stock_report IS
 CURSOR c_low_stock IS SELECT book_id,title,stock_qty,reorder_level FROM books
  WHERE stock_qty <= reorder_level ORDER BY stock_qty,title;
 v_id books.book_id%TYPE; v_title books.title%TYPE;
 v_stock books.stock_qty%TYPE; v_reorder books.reorder_level%TYPE; v_count NUMBER:=0;
BEGIN
 DBMS_OUTPUT.PUT_LINE('LOW-STOCK BOOK REPORT');
 DBMS_OUTPUT.PUT_LINE('------------------------------------------');
 OPEN c_low_stock;
 LOOP
  FETCH c_low_stock INTO v_id,v_title,v_stock,v_reorder;
  EXIT WHEN c_low_stock%NOTFOUND;
  v_count:=v_count+1;
  DBMS_OUTPUT.PUT_LINE('ID: '||v_id||' | '||v_title||' | Stock: '||v_stock||' | Reorder at: '||v_reorder);
 END LOOP;
 CLOSE c_low_stock;
 IF v_count=0 THEN DBMS_OUTPUT.PUT_LINE('No books are currently low in stock.');
 ELSE DBMS_OUTPUT.PUT_LINE('Total low-stock titles: '||v_count); END IF;
EXCEPTION WHEN OTHERS THEN IF c_low_stock%ISOPEN THEN CLOSE c_low_stock; END IF; RAISE;
END;
/
-- Test: SET SERVEROUTPUT ON; EXEC print_low_stock_report;
