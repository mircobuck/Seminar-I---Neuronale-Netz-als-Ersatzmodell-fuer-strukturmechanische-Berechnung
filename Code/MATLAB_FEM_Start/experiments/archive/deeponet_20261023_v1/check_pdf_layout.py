from pathlib import Path
import json
import pymupdf
from PIL import Image,ImageDraw
HERE=Path(__file__).resolve().parent
pdf=HERE/'output/pdf/FEM_Ersatzmodelle_DeepONet_Vergleich.pdf'
out=HERE/'tmp/pdfs'; out.mkdir(parents=True,exist_ok=True)
doc=pymupdf.open(pdf)
checks=[]; files=[]
for i,page in enumerate(doc):
    spans=[s for b in page.get_text('dict')['blocks'] if b['type']==0 for line in b['lines'] for s in line['spans']]
    outside=[s['text'] for s in spans if s['bbox'][0]<30 or s['bbox'][2]>565 or s['bbox'][1]<25 or s['bbox'][3]>825]
    checks.append({'Page':i+1,'Words':len(page.get_text().split()),'Images':len(page.get_images()),'OutsideText':outside})
    target=out/f'page-{i+1:02d}.png'
    page.get_pixmap(matrix=pymupdf.Matrix(1.2,1.2),alpha=False).save(target)
    files.append(target)
for offset in range(0,len(files),6):
    sheet=Image.new('RGB',(1140,1100),'#aeb9c4')
    for j,f in enumerate(files[offset:offset+6]):
        picture=Image.open(f).convert('RGB'); picture.thumbnail((360,510))
        thumb=Image.new('RGB',(380,550),'#d6dce2')
        thumb.paste(picture,((380-picture.width)//2,25))
        ImageDraw.Draw(thumb).text((10,5),f'Page {offset+j+1}',fill='black')
        sheet.paste(thumb,((j%3)*380,(j//3)*550))
    sheet.save(out/f'contact-{offset//6+1}.png')
(HERE/'pdf_layout_checks.json').write_text(json.dumps(checks,indent=2),encoding='utf-8')
assert not any(row['OutsideText'] for row in checks),checks
print('Rendered',len(doc),'pages; text within margins.')
for row in checks: print(row)
