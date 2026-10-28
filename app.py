import os
from functools import wraps

from flask import (
    Flask, render_template, request, redirect,
    url_for, session, flash
)

from database import BookstoreDB

app = Flask(__name__)
app.secret_key = os.getenv(
    "FLASK_SECRET_KEY",
    "change-this-local-demo-key"
)


def get_db():
    return BookstoreDB(
        os.getenv("ORACLE_USER", ""),
        os.getenv("ORACLE_PASSWORD", ""),
        os.getenv("ORACLE_DSN", "localhost:1521/freepdb1")
    )


def login_required(function):
    @wraps(function)
    def wrapped(*args, **kwargs):
        if not session.get("signed_in"):
            return redirect(url_for("login"))
        return function(*args, **kwargs)
    return wrapped


@app.route("/", methods=["GET", "POST"])
def login():
    if session.get("signed_in"):
        return redirect(url_for("dashboard"))

    if request.method == "POST":
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "")

        if not username or not password:
            flash("Enter both username and password.", "error")
        else:
            db = get_db()
            try:
                db.connect()
                session["signed_in"] = True
                session["username"] = username
                return redirect(url_for("dashboard"))
            except Exception as error:
                flash(f"Database connection failed: {error}", "error")
            finally:
                db.close()

    return render_template("login.html")


@app.route("/logout")
def logout():
    session.clear()
    return redirect(url_for("login"))


@app.route("/dashboard")
@login_required
def dashboard():
    db = get_db()
    try:
        db.connect()
        return render_template(
            "dashboard.html",
            stats=db.dashboard_stats(),
            books=db.books()[:5],
            username=session["username"]
        )
    except Exception as error:
        flash(f"Could not load dashboard: {error}", "error")
        return render_template(
            "dashboard.html",
            stats={},
            books=[],
            username=session["username"]
        )
    finally:
        db.close()


@app.route("/books", methods=["GET", "POST"])
@login_required
def books():
    db = get_db()
    try:
        db.connect()

        if request.method == "POST":
            try:
                db.add_book(request.form)
                flash("Book added successfully.", "success")
                return redirect(url_for("books"))
            except Exception as error:
                flash(f"Could not add book: {error}", "error")

        return render_template(
            "books.html",
            books=db.books(),
            username=session["username"]
        )
    except Exception as error:
        flash(f"Could not load catalogue: {error}", "error")
        return render_template(
            "books.html",
            books=[],
            username=session["username"]
        )
    finally:
        db.close()


@app.route("/orders", methods=["GET", "POST"])
@login_required
def orders():
    db = get_db()
    try:
        db.connect()

        if request.method == "POST":
            try:
                order_id, total = db.place_order(
                    int(request.form["customer_id"]),
                    int(request.form["book_id"]),
                    int(request.form["quantity"])
                )
                flash(
                    f"Order #{order_id} placed. "
                    f"Total: ₹{total:.2f}",
                    "success"
                )
                return redirect(url_for("orders"))
            except Exception as error:
                flash(f"Order failed: {error}", "error")

        return render_template(
            "orders.html",
            books=db.books(),
            orders=db.orders(),
            username=session["username"]
        )
    except Exception as error:
        flash(f"Could not load orders: {error}", "error")
        return render_template(
            "orders.html",
            books=[],
            orders=[],
            username=session["username"]
        )
    finally:
        db.close()


@app.route("/reports")
@login_required
def reports():
    db = get_db()
    try:
        db.connect()
        return render_template(
            "reports.html",
            low_stock=db.low_stock(),
            stats=db.dashboard_stats(),
            username=session["username"]
        )
    except Exception as error:
        flash(f"Could not load reports: {error}", "error")
        return render_template(
            "reports.html",
            low_stock=[],
            stats={},
            username=session["username"]
        )
    finally:
        db.close()


if __name__ == "__main__":
    app.run(debug=True)