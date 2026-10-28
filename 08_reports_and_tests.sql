SET SERVEROUTPUT ON;
PROMPT === BOOK CATALOGUE ===
SELECT book_id,title,author,category,price,stock_qty,reorder_level FROM books ORDER BY title;
PROMPT === EXPLICIT-CURSOR LOW STOCK REPORT ===
EXEC print_low_stock_report;
PROMPT === DISCOUNT FUNCTION EXAMPLES ===
SELECT 800 purchase_amount,calculate_discount(800) discount FROM dual
UNION ALL SELECT 1500,calculate_discount(1500) FROM dual
UNION ALL SELECT 3000,calculate_discount(3000) FROM dual;
PROMPT === ORDER HISTORY ===
SELECT o.order_id,c.customer_name,b.title,i.quantity,o.subtotal,o.discount_amount,o.total_amount,o.order_status,o.order_date
FROM book_orders o JOIN customers c ON c.customer_id=o.customer_id
JOIN order_items i ON i.order_id=o.order_id JOIN books b ON b.book_id=i.book_id ORDER BY o.order_date DESC;
PROMPT === WALLET BALANCES ===
SELECT w.account_id,c.customer_name,w.balance,w.account_status FROM wallet_accounts w JOIN customers c ON c.customer_id=w.customer_id ORDER BY w.account_id;
PROMPT === BALANCE AUDIT ===
SELECT audit_id,account_id,old_balance,new_balance,changed_at,changed_by,action_note FROM account_audit ORDER BY changed_at DESC;
PROMPT === FUND TRANSFERS ===
SELECT * FROM fund_transfers ORDER BY transfer_time DESC;
