def embed_watermark(text, watermark_id):
    """
    Embed invisible watermark inside text (prototype)
    """
    watermark = f"<<WM:{watermark_id}>>"
    return text + "\n" + watermark
