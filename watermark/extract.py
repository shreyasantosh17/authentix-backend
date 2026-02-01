def extract_watermark(text):
    """
    Extract embedded watermark from text
    """
    start = text.find("<<WM:")
    end = text.find(">>")

    if start != -1 and end != -1:
        return text[start+5:end]

    return None
