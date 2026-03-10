from flask import Flask, request, jsonify
from sqlalchemy import create_engine, text
from datetime import datetime
from PyPDF2 import PdfReader

from utils.hashing import generate_hash
from watermark.embed import embed_watermark
from watermark.extract import extract_watermark

app = Flask(__name__)

# ================= DATABASE CONNECTION =================
DATABASE_URL = "postgresql://postgres:Shrey4%40172005@db.aqakepzkfusdwqhvhdup.supabase.co:5432/postgres"
engine = create_engine(DATABASE_URL)

# ================= REGISTER PDF =================
@app.route("/register", methods=["POST"])
def register_book():
    try:
        file = request.files["file"]
        author_name = request.form["author_name"]
        author_email = request.form["author_email"]

        reader = PdfReader(file)
        text_data = ""

        for page in reader.pages:
            extracted = page.extract_text()
            if extracted:
                text_data += extracted

        if text_data.strip() == "":
            return jsonify({"error": "PDF text not readable"}), 400

        watermark_id = author_email
        book_hash = generate_hash(text_data)

        with engine.connect() as conn:
            conn.execute(
                text("""
                    INSERT INTO books
                    (book_hash, watermark_id, author_name, author_email, created_at)
                    VALUES
                    (:book_hash, :watermark_id, :author_name, :author_email, :created_at)
                """),
                {
                    "book_hash": book_hash,
                    "watermark_id": watermark_id,
                    "author_name": author_name,
                    "author_email": author_email,
                    "created_at": datetime.now()
                }
            )
            conn.commit()

        return jsonify({"message": "PDF registered successfully"})

    except Exception as e:
        return jsonify({"error": str(e)}), 500


# ================= VERIFY PDF =================
@app.route("/verify", methods=["POST"])
def verify_book():

    try:
        file = request.files["file"]

        reader = PdfReader(file)
        text_data = ""

        for page in reader.pages:
            if page.extract_text():
                text_data += page.extract_text()

        # ✅ HASH GENERATE
        book_hash = generate_hash(text_data)

        # ✅ DB CHECK
        with engine.connect() as conn:
            result = conn.execute(
                text("""
                    SELECT author_name, timestamp
                    FROM books
                    WHERE book_hash = :book_hash
                """),
                {"book_hash": book_hash}
            ).fetchone()

        if result:
            return jsonify({
                "status": "ORIGINAL",
                "author_name": result[0],
                "registered_on": result[1]
            })

        return jsonify({
            "status": "TAMPERED / FAKE",
            "reason": "No matching record"
        })

    except Exception as e:
        return jsonify({"error": str(e)}), 500



# ================= HEALTH =================
@app.route("/")
def home():
    return "Authentix Backend Running (PDF Mode Enabled)"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
@app.route("/my-books", methods=["GET"])
def get_my_books():

    email = request.args.get("email")

    with engine.connect() as conn:
        result = conn.execute(
            text("""
                SELECT author_name, watermark_id, created_at
                FROM books
                WHERE watermark_id = :email
                ORDER BY created_at DESC
            """),
            {"email": email}
        ).fetchall()

    books = [
        {
            "author_name": row[0],
            "watermark_id": row[1],
            "timestamp": str(row[2])
        }
        for row in result
    ]

    return jsonify(books)
#test change