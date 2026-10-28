import oracledb


class BookstoreDB:
    def __init__(self, user, password, dsn):
        self.user = user
        self.password = password
        self.dsn = dsn
        self.connection = None

    def connect(self):
        if not self.user or not self.password:
            raise RuntimeError(
                "Set ORACLE_USER and ORACLE_PASSWORD first."
            )

        self.connection = oracledb.connect(
            user=self.user,
            password=self.password,
            dsn=self.dsn
        )

    def close(self):
        if self.connection:
            self.connection.close()
            self.connection = None

    def dashboard_stats(self):
        with self.connection.cursor() as cur:
            cur.execute("""
                SELECT COUNT(*),
                       NVL(SUM(stock_qty), 0),
                       NVL(SUM(
                           CASE
                               WHEN stock_qty <= reorder_level
                               THEN 1 ELSE 0
                           END
                       ), 0)
                FROM books
            """)
            books, stock, low = cur.fetchone()

            cur.execute("""
                SELECT COUNT(*), NVL(SUM(total_amount), 0)
                FROM book_orders
            """)
            orders, sales = cur.fetchone()

        return {
            "books": books,
            "stock": stock,
            "low_stock": low,
            "orders": orders,
            "sales": sales
        }

    def books(self):
        with self.connection.cursor() as cur:
            cur.execute("""
                SELECT book_id, title, author, category,
                       price, stock_qty, reorder_level
                FROM books
                ORDER BY title
            """)
            return cur.fetchall()

    def add_book(self, form):
        with self.connection.cursor() as cur:
            cur.execute("""
                INSERT INTO books (
                    title, author, category, price,
                    stock_qty, reorder_level
                )
                VALUES (
                    :title, :author, :category, :price,
                    :stock, :reorder
                )
            """,
                title=form["title"].strip(),
                author=form["author"].strip(),
                category=form["category"],
                price=float(form["price"]),
                stock=int(form["stock_qty"]),
                reorder=int(form["reorder_level"])
            )

        self.connection.commit()

    def place_order(self, customer_id, book_id, quantity):
        with self.connection.cursor() as cur:
            order_id = cur.var(oracledb.NUMBER)
            total = cur.var(oracledb.NUMBER)

            cur.callproc("place_book_order", [
                customer_id,
                book_id,
                quantity,
                order_id,
                total
            ])

            result_id = int(order_id.getvalue())
            result_total = float(total.getvalue())

        return result_id, result_total

    def orders(self):
        with self.connection.cursor() as cur:
            cur.execute("""
                SELECT o.order_id,
                       c.customer_name,
                       b.title,
                       i.quantity,
                       o.total_amount,
                       o.order_status,
                       o.order_date
                FROM book_orders o
                JOIN customers c
                    ON c.customer_id = o.customer_id
                JOIN order_items i
                    ON i.order_id = o.order_id
                JOIN books b
                    ON b.book_id = i.book_id
                ORDER BY o.order_date DESC
            """)
            return cur.fetchall()

    def low_stock(self):
        with self.connection.cursor() as cur:
            cur.callproc("print_low_stock_report")

            cur.execute("""
                SELECT book_id, title, stock_qty, reorder_level
                FROM books
                WHERE stock_qty <= reorder_level
                ORDER BY stock_qty
            """)
            return cur.fetchall()