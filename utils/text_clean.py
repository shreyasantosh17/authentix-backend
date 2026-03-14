def clean_text(text):
    """
    Basic normalization for consistency
    """
    text = text.lower()
    text = " ".join(text.split())
    return text
