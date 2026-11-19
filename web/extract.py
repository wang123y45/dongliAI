import sys, json, os, re

path = sys.argv[1]
ext = os.path.splitext(path)[1].lower()
text = ''
try:
    if ext == '.pdf':
        from pypdf import PdfReader
        reader = PdfReader(path)
        parts = []
        for page in reader.pages[:80]:
            parts.append(page.extract_text() or '')
        text = '\n'.join(parts)
    elif ext == '.docx':
        from docx import Document
        doc = Document(path)
        parts = [p.text for p in doc.paragraphs if p.text.strip()]
        for table in doc.tables:
            for row in table.rows:
                parts.append(' | '.join(c.text.strip() for c in row.cells))
        text = '\n'.join(parts)
    else:
        with open(path, 'rb') as f:
            raw = f.read()
        text = raw.decode('utf-8', errors='ignore')
    text = re.sub(r'\x00', ' ', text)
    text = re.sub(r'[ \t]+', ' ', text)
    text = re.sub(r'\n{3,}', '\n\n', text).strip()
    print(json.dumps({'ok': True, 'text': text[:60000], 'chars': len(text)}, ensure_ascii=False))
except Exception as e:
    print(json.dumps({'ok': False, 'error': str(e)}, ensure_ascii=False))
