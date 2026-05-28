from flask import Flask, request, jsonify
from sqlalchemy import create_engine, text
from datetime import datetime
from supabase import create_client
import hashlib
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

# ================= HASH FUNCTION =================
def generate_hash(data):
    return hashlib.sha256(data).hexdigest()

# ================= DATABASE =================
DATABASE_URL = os.getenv("DATABASE_URL")
engine = create_engine(DATABASE_URL)

# ================= SUPABASE =================
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
supabase = create_client(SUPABASE_URL, SUPABASE_KEY)

# ================= REGISTER =================
@app.route("/register", methods=["POST"])
def register_book():
    try:
        file = request.files.get("file")

        if not file:
            return jsonify({"error": "PDF file missing"}), 400

        author_name = request.form.get("author_name")
        author_email = request.form.get("author_email")

        if not author_name or not author_email:
            return jsonify({"error": "Author name or email missing"}), 400

        # ===== READ FILE =====
        pdf_bytes = file.read()

        # ===== HASH =====
        book_hash = generate_hash(pdf_bytes)

        # ===== UPLOAD TO SUPABASE =====
        file_name = f"{author_email}_{datetime.now().timestamp()}.pdf"

        supabase.storage.from_("books").upload(
            file_name,
            pdf_bytes,
            {"content-type": "application/pdf"}
        )

        file_url = supabase.storage.from_("books").get_public_url(file_name)

        # ===== SAVE TO DB =====
        with engine.connect() as conn:
            conn.execute(
                text("""
                INSERT INTO books
                (book_hash, watermark_id, author_name, author_email, file_url, created_at)
                VALUES
                (:book_hash, :watermark_id, :author_name, :author_email, :file_url, :created_at)
                """),
                {
                    "book_hash": book_hash,
                    "watermark_id": author_email,
                    "author_name": author_name,
                    "author_email": author_email,
                    "file_url": file_url,
                    "created_at": datetime.now()
                }
            )
            conn.commit()

        return jsonify({
            "message": "PDF registered successfully",
            "file_url": file_url
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ================= VERIFY =================
@app.route("/verify", methods=["POST"])
def verify_book():
    try:
        file = request.files.get("file")

        if not file:
            return jsonify({"error": "PDF file missing"}), 400

        verifier_email = request.form.get("email", "anonymous")

        # ===== READ FILE =====
        pdf_bytes = file.read()

        # ===== HASH =====
        book_hash = generate_hash(pdf_bytes)

        # ===== CHECK DB =====
        with engine.connect() as conn:
            result = conn.execute(
                text("""
                SELECT author_name, author_email, file_url
                FROM books
                WHERE book_hash = :book_hash
                """),
                {"book_hash": book_hash}
            ).fetchone()

        status = "FAKE"

        if result:
            status = "REAL"

        # ===== SAVE LOG 🔥 =====
        with engine.connect() as conn:
            conn.execute(
                text("""
                INSERT INTO verification_logs (book_hash, verifier_email, result)
                VALUES (:book_hash, :verifier_email, :result)
                """),
                {
                    "book_hash": book_hash,
                    "verifier_email": verifier_email,
                    "result": status
                }
            )
            conn.commit()

        # ===== RESPONSE =====
        if result:
            return jsonify({
                "status": "REAL",
                "author": result[0],
                "email": result[1],
                "file_url": result[2]
            })

        return jsonify({
            "status": "FAKE"
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ================= OWNERSHIP LOGS =================
@app.route("/ownership-logs", methods=["GET"])
def get_logs():
    email = request.args.get("email")

    with engine.connect() as conn:
        result = conn.execute(
            text("""
            SELECT b.author_name, v.book_hash, COUNT(*) as total_checks,
                   MAX(v.checked_at) as last_checked
            FROM verification_logs v
            JOIN books b ON v.book_hash = b.book_hash
            WHERE b.author_email = :email
            GROUP BY b.author_name, v.book_hash
            ORDER BY last_checked DESC
            """),
            {"email": email}
        ).fetchall()

    logs = [
        {
            "author_name": row[0],
            "book_hash": row[1],
            "count": row[2],
            "last_checked": str(row[3])
        }
        for row in result
    ]

    return jsonify(logs)

@app.route("/analytics-summary", methods=["GET"])
def analytics_summary():
    email = request.args.get("email")

    with engine.connect() as conn:
        result = conn.execute(
            text("""
            SELECT result, COUNT(*) 
            FROM verification_logs v
            JOIN books b ON v.book_hash = b.book_hash
            WHERE b.author_email = :email
            GROUP BY result
            """),
            {"email": email}
        ).fetchall()

    summary = {"REAL": 0, "FAKE": 0}

    for row in result:
        summary[row[0]] = row[1]

    return jsonify(summary)


# ================= MY BOOKS =================
@app.route("/my-books", methods=["GET"])
def get_my_books():
    email = request.args.get("email")

    with engine.connect() as conn:
        result = conn.execute(
            text("""
            SELECT author_name, watermark_id, created_at, file_url
            FROM books
            WHERE author_email = :email
            ORDER BY created_at DESC
            """),
            {"email": email}
        ).fetchall()

    books = [
        {
            "author_name": row[0],
            "watermark_id": row[1],
            "timestamp": str(row[2]),
            "file_url": row[3]
        }
        for row in result
    ]

    return jsonify(books)


# ================= HEALTH =================
@app.route("/")
def home():
    return "Authentix Backend Running 🚀"


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)