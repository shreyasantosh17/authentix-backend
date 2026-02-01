from flask import Flask, request, jsonify
import sqlite3
import os
from datetime import datetime

from utils.hashing import generate_hash
from utils.text_clean import clean_text
from watermark.embed import embed_watermark
from watermark.extract import extract_watermark

app = Flask(__name__)

DB_PATH = "database/books.db"

# ---------- DB INIT ----------
def init_db():
    os.makedirs("database", exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("""
        CREATE TABLE IF NOT EXISTS books (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            book_hash TEXT,
            watermark_id TEXT,
            author_name TEXT,
            timestamp TEXT
        )
    """)
    conn.commit()
    conn.close()

init_db()

# ---------- REGISTER BOOK ----------
@app.route("/register", methods=["POST"])
def register_book():
    data = request.json

    text = clean_text(data["text"])
    author_name = data["author_name"]
    author_email = data["author_email"]

    watermark_id = author_email
    book_hash = generate_hash(text)
    watermarked_text = embed_watermark(text, watermark_id)

    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()

    try:
        c.execute("""
            INSERT INTO books (book_hash, watermark_id, author_name, timestamp)
            VALUES (?, ?, ?, ?)
        """, (
            book_hash,
            watermark_id,
            author_name,
            datetime.now().isoformat()
        ))
        conn.commit()
    except:
        conn.close()
        return jsonify({"message": "Book already registered"}), 409

    conn.close()

    return jsonify({
        "message": "Book registered successfully",
        "watermarked_text": watermarked_text
    })

# ---------- VERIFY BOOK ----------
@app.route("/verify", methods=["POST"])
def verify_book():
    data = request.json

    text = clean_text(data["text"])
    extracted_watermark = extract_watermark(text)

    if not extracted_watermark:
        return jsonify({
            "status": "TAMPERED / FAKE",
            "reason": "Watermark missing"
        })

    conn = sqlite3.connect(DB_PATH)
    c = conn.cursor()
    c.execute("""
        SELECT author_name, timestamp FROM books
        WHERE watermark_id=?
    """, (extracted_watermark,))
    result = c.fetchone()
    conn.close()

    if result:
        return jsonify({
            "status": "ORIGINAL",
            "author_name": result[0],
            "registered_on": result[1]
        })

    return jsonify({
        "status": "TAMPERED / FAKE",
        "reason": "No matching authorship record"
    })

# ---------- HEALTH ----------
@app.route("/")
def home():
    return "Authentix Backend Running"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)

