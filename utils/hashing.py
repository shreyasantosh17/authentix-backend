import hashlib

def generate_hash(text):
    """
    Generate SHA256 hash for indexing purpose
    """
    return hashlib.sha256(text.encode("utf-8")).hexdigest()
