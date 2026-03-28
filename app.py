from flask import Flask, request, jsonify
from sqlalchemy import create_engine, text
from datetime import datetime
from supabase import create_client
import hashlib

app = Flask(__name__)

# ================= HASH FUNCTION =================
def generate_hash(data):
    return hashlib.sha256(data).hexdigest()

# ================= DATABASE =================
DATABASE_URL = "postgresql://postgres.aqakepzkfusdwqhvhdup:Shrey4%40172005@aws-1-ap-northeast-2.pooler.supabase.com:5432/postgres"
engine = create_engine(DATABASE_URL)

# ================= SUPABASE =================
SUPABASE_URL = "https://aqakepzkfusdwqhvhdup.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFxYWtlcHprZnVzZHdxaHZoZHVwIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3MTAyNDk5MSwiZXhwIjoyMDg2NjAwOTkxfQ.VOVWkTzxgV705mTQJMEut00vdt4lLzH0HSLUb_4FAFI"   # 🔴 IMPORTANT: env me daalna better

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
            SELECT book_hash, verifier_email, result, checked_at
            FROM verification_logs
            WHERE verifier_email = :email
            ORDER BY checked_at DESC
            """),
            {"email": email}
        ).fetchall()

    logs = [
        {
            "book_hash": row[0],
            "verifier": row[1],
            "result": row[2],
            "time": str(row[3])
        }
        for row in result
    ]

    return jsonify(logs)


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