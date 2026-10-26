"""Rebuild the German comparison PDF and editable Markdown from saved results.
No model fitting or numerical test execution occurs in this report builder.
"""
from pathlib import Path
import json, math, hashlib, csv
import numpy as np
import pandas as pd
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.colors import LogNorm
from reportlab.platypus import (SimpleDocTemplate, Paragraph, Spacer, Table,
    TableStyle, Image, PageBreak, KeepTogether)
from reportlab.lib import colors
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.enums import TA_CENTER
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from xml.sax.saxutils import escape

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[1]
COUNTS=[12,24,48,96,192,384]
S=pd.read_csv(HERE/'deeponet_summary.csv')
B=pd.read_csv(HERE/'baseline_summary.csv')
PC=pd.read_csv(HERE/'deeponet_per_case.csv')
BC=pd.read_csv(HERE/'baseline_per_case.csv')
OLD=pd.read_csv(ROOT/'experiments/pod_galerkin_20261023_v1/comparison.csv')
EVENTS=pd.read_csv(HERE/'events.csv')
HARDWARE=json.loads((HERE/'hardware.json').read_text(encoding='utf-8-sig'))
FIG=HERE/'figures'; FIG.mkdir(exist_ok=True)
OUT=HERE/'output/pdf'; OUT.mkdir(parents=True,exist_ok=True)
plt.rcParams.update({'font.size':10,'axes.spines.top':False,'axes.spines.right':False,
                     'figure.dpi':140,'savefig.bbox':'tight'})
palette={'POD_GP':'#276FBF','POD_RBF':'#C47A16','POD_MLP':'#9656A5',
         'POD_Galerkin':'#19845B','DeepONet':'#C73349'}

def fmt(x,scale=1,digits=3):
    if pd.isna(x): return '-'
    return f'{float(x)*scale:.{digits}f}'.replace('.',',')

def savefig(name):
    plt.savefig(FIG/name,dpi=180); plt.close()

combined=pd.concat([B,S.assign(Model='DeepONet')],ignore_index=True)
combined.to_csv(HERE/'comparison_all_runs.csv',index=False)
pd.concat([BC,PC.assign(Model='DeepONet')],ignore_index=True).to_csv(HERE/'comparison_all_cases.csv',index=False)
G=S.groupby('TrainingCases')
A=G.agg(Median=('FieldMedianRelL2','median'),Min=('FieldMedianRelL2','min'),
        Max=('FieldMedianRelL2','max'),P95=('FieldP95RelL2','median'),
        Worst=('FieldWorstRelL2','max'),Online=('OnlineSeconds','median'),
        Fit=('TrainingSeconds','sum'),Prep=('PreparationSeconds','sum'))
A.to_csv(HERE/'seed_aggregate.csv')
assert len(S)==30 and len(PC)==180 and S.groupby('TrainingCases').size().eq(5).all()
assert set(S.Seed)==set(range(42,47))
assert S.ClampMax_m.eq(0).all()

for metric,name,label in [('FieldMedianRelL2','learning_curve.png','Median Feldfehler [%]'),
                          ('FieldWorstRelL2','worst_curve.png','Schlechtester Testfall [%]')]:
    fig,ax=plt.subplots(figsize=(7.7,4.4))
    g=S.groupby('TrainingCases')[metric]
    med=g.median().reindex(COUNTS); lo=g.min().reindex(COUNTS); hi=g.max().reindex(COUNTS)
    ax.fill_between(COUNTS,100*lo,100*hi,color=palette['DeepONet'],alpha=.18,label='DeepONet: Min-Max der 5 Seeds')
    ax.plot(COUNTS,100*med,'o-',color=palette['DeepONet'],label='DeepONet: Seed-Median')
    for method in ['POD_GP','POD_RBF','POD_MLP','POD_Galerkin']:
        b=B[B.Model.eq(method)].sort_values('TrainingCases')
        ax.plot(b.TrainingCases,100*b[metric],'.-',label=method,color=palette[method])
    ax.set(xscale='log',yscale='log',xlabel='Unabhängige Trainingsfälle N',ylabel=label)
    ax.set_xticks(COUNTS,labels=COUNTS); ax.grid(alpha=.25); ax.legend(fontsize=8,ncol=2)
    savefig(name)

fig,axes=plt.subplots(1,2,figsize=(7.7,3.5))
for method in ['POD_GP','POD_RBF','POD_MLP','POD_Galerkin']:
    b=B[B.Model.eq(method)].sort_values('TrainingCases')
    axes[0].plot(b.TrainingCases,b.OnlineSeconds*1000,'.-',label=method,color=palette[method])
axes[0].plot(COUNTS,A.Online*1000,'o-',color=palette['DeepONet'],label='DeepONet')
axes[0].set(xscale='log',yscale='log',ylabel='Feldvorhersage pro Fall [ms]',xlabel='Trainingsfälle N')
axes[0].set_xticks(COUNTS,labels=COUNTS); axes[0].legend(fontsize=7)
axes[1].scatter(B[B.TrainingCases.eq(384)].OnlineSeconds*1000,
                B[B.TrainingCases.eq(384)].FieldMedianRelL2*100,color='grey')
for method in ['POD_GP','POD_RBF','POD_MLP','POD_Galerkin']:
    b=B[B.Model.eq(method)&B.TrainingCases.eq(384)].iloc[0]
    axes[1].annotate(method,(b.OnlineSeconds*1000,b.FieldMedianRelL2*100),fontsize=7)
d=S[S.TrainingCases.eq(384)]
axes[1].scatter(d.OnlineSeconds*1000,d.FieldMedianRelL2*100,color=palette['DeepONet'],label='5 DeepONet-Seeds')
axes[1].set(xscale='log',yscale='log',xlabel='Feldvorhersage [ms]',ylabel='Median Feldfehler [%]')
for ax in axes: ax.grid(alpha=.25)
fig.tight_layout(); savefig('cost_accuracy.png')

selections=[]
for n in COUNTS:
    q=pd.read_csv(HERE/f'n{n}/validation_selection.csv'); q.insert(0,'TrainingCases',n)
    q['Selected']=q.ValidationScore.eq(q.ValidationScore.min())
    selections.append(q)
SEL=pd.concat(selections); SEL.to_csv(HERE/'hyperparameter_search.csv',index=False)

# Every combination is explicit in the machine-readable capability matrix.
cap=[]
models=['Scalar_GPR','POD_GP','POD_RBF','POD_MLP','Beam_plus_GPR','Beam_theory','POD_Galerkin','DeepONet']
for model in models:
    for n in COUNTS:
        for output in ['Verschiebungsfeld','Spitzen-uz','Gittermaximum']:
            supported=(model not in ['Scalar_GPR','Beam_plus_GPR','Beam_theory'] or output!='Verschiebungsfeld')
            supported=supported and not(model in ['Beam_plus_GPR','Beam_theory'] and output=='Gittermaximum')
            for kind in ['Parameterinterpolation','Einspannung','Neue Topologie','Extrapolation','Netztransfer']:
                status='nicht untersucht'
                if not supported: status='keine entsprechende Ausgabe'
                elif kind=='Parameterinterpolation': status='ausgewertet: 6 feste Testfälle'
                elif kind=='Einspannung' and output=='Verschiebungsfeld': status='geprüft am Auswertegitter'
                cap.append([model,output,n,kind,status])
CAP=pd.DataFrame(cap,columns=['Modell','Ausgabe','Trainingsfälle','Testart','Prüfstatus'])
CAP.to_csv(HERE/'capability_matrix.csv',index=False,encoding='utf-8-sig')

# Spatial diagnostics: a predeclared seed (42), never the best test seed.
DSP=pd.read_csv(HERE/'deeponet_spatial_seed42.csv')
SP=pd.concat([pd.read_csv(HERE/'baseline_spatial.csv'),DSP],ignore_index=True)
ranked=PC[(PC.TrainingCases==384)&(PC.Seed==42)].sort_values('FieldRelativeL2')
chosen=[int(ranked.iloc[i].CaseID) for i in [0,2,5]]
spatial_methods=['POD_GP','POD_RBF','POD_MLP','POD_Galerkin','DeepONet']
slice_data=SP[SP.CaseID.isin(chosen)&np.isclose(SP.Eta,.5)]
vmax=max(slice_data.VectorError_m.max()*1e6,1e-5)
vmin=max(slice_data.loc[slice_data.VectorError_m>0,'VectorError_m'].min()*1e6,1e-6)
for title,caseid in zip(['gut','mittel','schlecht'],chosen):
    fig,axes=plt.subplots(6,1,figsize=(7.6,8.1),constrained_layout=True)
    ref=slice_data[(slice_data.CaseID==caseid)&(slice_data.Model=='DeepONet')]
    grid=lambda df,col: df.pivot(index='Zeta',columns='Xi',values=col).to_numpy()*1e6
    im=axes[0].imshow(grid(ref,'ReferenceUz_m'),origin='lower',extent=[0,1,0,1],aspect='auto',cmap='coolwarm')
    axes[0].set_title(f'Fall {caseid}: FEM-Referenz uz [µm], Schnitt eta=0,5',fontsize=10)
    fig.colorbar(im,ax=axes[0],label='uz [µm]',fraction=.03)
    for ax,method in zip(axes[1:],spatial_methods):
        df=slice_data[(slice_data.CaseID==caseid)&(slice_data.Model==method)]
        z=grid(df,'VectorError_m'); z=np.ma.masked_less_equal(z,0)
        im=ax.imshow(z,origin='lower',extent=[0,1,0,1],aspect='auto',cmap='magma',norm=LogNorm(vmin=vmin,vmax=vmax))
        ax.set_title(method+': Betrag des Vektorfehlers [µm]',fontsize=9)
        cb=fig.colorbar(im,ax=ax,label='Fehler [µm], log',fraction=.03)
        cb.set_ticks([vmin,1e-2,vmax],labels=[f'{vmin:.0e}','1e-2',f'{vmax:.2g}'])
    for ax in axes: ax.set_ylabel('zeta'); ax.set_xlabel('xi')
    savefig(f'spatial_{title}.png')
pd.DataFrame({'Kategorie':['gut','mittel (unterer Median)','schlecht'],'CaseID':chosen,
              'N':384,'Seed':42}).to_csv(HERE/'representative_cases.csv',index=False)

# Typeset source is mirrored to Markdown alongside the executable generator.
fontdir=Path('C:/Windows/Fonts')
pdfmetrics.registerFont(TTFont('Arial',str(fontdir/'arial.ttf')))
pdfmetrics.registerFont(TTFont('ArialBold',str(fontdir/'arialbd.ttf')))
pdfmetrics.registerFontFamily('Arial',normal='Arial',bold='ArialBold',italic='Arial',boldItalic='ArialBold')
styles=getSampleStyleSheet()
styles.add(ParagraphStyle(name='BodyDE',fontName='Arial',fontSize=9.5,leading=14,spaceAfter=9))
styles.add(ParagraphStyle(name='TitleDE',fontName='ArialBold',fontSize=26,leading=31,textColor=colors.HexColor('#17324D'),spaceAfter=20))
styles.add(ParagraphStyle(name='HeadingDE',fontName='ArialBold',fontSize=17,leading=21,textColor=colors.HexColor('#17324D'),spaceAfter=14))
styles.add(ParagraphStyle(name='SmallDE',fontName='Arial',fontSize=7.4,leading=10,spaceAfter=5))
story=[]; md=[]
def title(t): story.append(Paragraph(escape(t),styles['TitleDE'])); md.append('# '+t+'\n')
def heading(t): story.append(Paragraph(escape(t),styles['HeadingDE'])); md.append('## '+t+'\n')
def p(t,small=False):
    story.append(Paragraph(t,styles['SmallDE' if small else 'BodyDE'])); md.append(t.replace('<b>','**').replace('</b>','**')+'\n')
def table(headers,rows,widths=None):
    data=[[Paragraph(escape(str(x)),styles['SmallDE']) for x in headers]]
    data += [[Paragraph(escape(str(x)),styles['SmallDE']) for x in row] for row in rows]
    t=Table(data,colWidths=widths,repeatRows=1,hAlign='LEFT')
    t.setStyle(TableStyle([('BACKGROUND',(0,0),(-1,0),colors.HexColor('#DFEAF2')),
        ('ROWBACKGROUNDS',(0,1),(-1,-1),[colors.white,colors.HexColor('#F5F7FA')]),
        ('VALIGN',(0,0),(-1,-1),'TOP'),('BOTTOMPADDING',(0,0),(-1,-1),5),
        ('TOPPADDING',(0,0),(-1,-1),5),('LINEBELOW',(0,0),(-1,0),.5,colors.HexColor('#90A8BA'))]))
    story.append(t); story.append(Spacer(1,10))
    md.append('| '+' | '.join(map(str,headers))+' |\n| '+' | '.join(['---']*len(headers))+' |')
    md.extend('| '+' | '.join(map(str,row))+' |' for row in rows); md.append('\n')
def fig(name,w=490,h=None):
    from PIL import Image as PILImage
    size=PILImage.open(FIG/name).size
    h=h or w*size[1]/size[0]
    story.append(Image(str(FIG/name),width=w,height=h)); md.append(f'![{name}](figures/{name})\n')
def page(): story.append(PageBreak()); md.append('\n---\n')

title('FEM-Ersatzmodelle im Vergleich')
p('Parametrische DeepONet-Adaption, POD-Regressoren, Balkenmodelle und klassischer POD-Galerkin-ROM')
p('<b>Ausgewertete Reihe:</b> 12, 24, 48, 96, 192 und 384 Trainingsfälle; fünf feste DeepONet-Seeds je Größe. Stand: 25.10.2026. MATLAB R2025b Update 1, Ausführung über MATLAB MCP.')
d384=S[S.TrainingCases==384]
gp384=B[(B.TrainingCases==384)&(B.Model=='POD_GP')].iloc[0]
rom384=B[(B.TrainingCases==384)&(B.Model=='POD_Galerkin')].iloc[0]
p(f'<b>Gemessen bei N=384:</b> DeepONet erreicht über die fünf Seeds einen Median der fallweisen Medianfehler von {fmt(d384.FieldMedianRelL2.median(),100)} %. Die Seed-Spanne beträgt {fmt(d384.FieldMedianRelL2.min(),100)} bis {fmt(d384.FieldMedianRelL2.max(),100)} %. POD-GPR liegt bei {fmt(gp384.FieldMedianRelL2,100)} %, der klassische ROM bei {fmt(rom384.FieldMedianRelL2,100)} %.')
p('Der Vergleich bewertet die Parameterinterpolation derselben linear-elastischen Quaderfamilie auf sechs bereits bekannten Testfällen. Er belegt weder neue Topologien noch Extrapolation, Spannungsgenauigkeit oder allgemeine Zuverlässigkeit.')
p('Die neue Architektur ist tatsächlich gemeinsam in Parameter- und Ortsdarstellung trainiert. Ihre räumliche Flexibilität allein ist kein Nachweis besseren Geometrietransfers. Bestehende Modelle wurden nicht nachtrainiert; neue FEM-Rechnungen waren für diese Erweiterung nicht erforderlich.')
p('Berichtsquelle: REPORT.md und build_report.py. Messwerte, vollständige Modellstände, Checkpoints und Konfiguration liegen im zugehörigen Experimentordner.')
page()

heading('1 | Physik und Zielgrößen')
p('Untersucht wird ein homogener isotroper Quaderbalken in linearer statischer 3D-Elastizität: div(sigma)=0, sigma=lambda tr(epsilon) I + 2 mu epsilon, epsilon=sym(grad u), lambda=E nu/((1+nu)(1-2nu)), mu=E/(2(1+nu)). Körperkräfte sind null. An der linken Stirnfläche gilt u=0; rechts wirkt eine konstante Traktion [0,0,Fz/(b h)]. Die übrigen Flächen sind lastfrei.')
table(['Parameter','Bereich','Einheit'],[['L','0,6 bis 1,2','m'],['b','0,06 bis 0,10','m'],['h','0,08 bis 0,14','m'],['E','70 bis 210','GPa (intern Pa)'],['nu','0,25 bis 0,35','dimensionslos'],['Fz','-1000 bis -100','N']],[150,220,120])
p('Referenzraum [0,1]³: x=L(xi-0,5), y=b(eta-0,5), z=h zeta. Die feste Abfrageanordnung umfasst 21 × 5 × 5 = 525 Punkte. Feldvektoren haben die Länge 1575 und die Blockreihenfolge [alle ux; alle uy; alle uz]. Verschiebungen werden in Metern gespeichert.')
p('Spitzenverschiebung bedeutet das signierte uz am rechten Stirnflächenmittelpunkt (xi,eta,zeta)=(1; 0,5; 0,5). Das Gittermaximum ist max sqrt(ux²+uy²+uz²) über dieselben 525 Punkte. Es ist kein garantiertes kontinuierliches Körpermaximum.')
p('Die verwendete Norm ist e_j=sqrt(sum_i w_i (u_ij-uRef_ij)² / sum_i w_i uRef_ij²). Tensorprodukt-Trapezgewichte summieren sich je Komponente zu eins, über alle Komponenten zu drei. Auf einem Quader hebt sich die konstante physikalische Volumenskalierung im relativen Fehler auf. Die Einspannung wird am gesamten linken Abfragegitter separat geprüft.')
page()

heading('2 | Datenentstehung und Trennung')
p('Vorhandene Originaldaten: quadratische Tetraeder, fallweise generateMesh mit Hmax=min(b,h)/3. Material und Last werden pro Fall gesetzt. Die FEM-Lösung wird mit interpolateDisplacement auf das Referenzgitter abgebildet; Clamp-Punkte werden explizit auf null gesetzt. Rohknoten, Elemente und nodale Verschiebungen bleiben gespeichert.')
table(['N','Trainings-IDs','neu hinzugefügte IDs / Design-Seed'],[
['12','1-12','ursprünglicher Smoke; Training 1001'],['24','1-12, 25-36','erste 12 aus Zusatz-LHS 20261023'],
['48','1-12, 25-60','vollständiges Zusatz-LHS 20261023'],['96','1-12, 25-108','61-108; Seed 20261024'],
['192','1-12, 25-204','109-204; Seed 20261025'],['384','1-12, 25-396','205-396; Seed 20261026']],[45,150,295])
p('Validierung sind unverändert IDs 13-18, Test IDs 19-24. Ursprüngliche Sampling-Seeds: Training 1001, Validierung 11001, Test 21001. Zusätze verwenden randomisierte Latin-Hypercube-Samples im gleichen Parameterquader. Die verschachtelten Gesamtmengen sind nicht jeweils neu optimierte LHS-Designs. Die gespeicherten Design-CSV mit 17 signifikanten Stellen sind maßgeblich.')
p('Alle 396 Parameterzeilen sind eindeutig. Sämtliche Splits sind disjunkt; Validierungs- und Testdateien sind zwischen Größen vollständig identisch. 525 Punkte eines Balkens bilden einen physikalischen Fall und erhöhen die unabhängige Fallzahl nicht. Die volle Trainingsmenge umfasst 384 Fälle und keinerlei Holdout-Fälle.')
mesh=pd.read_csv(ROOT/'runs/smoke/mesh_check.csv')
p('Vorhandene Netzprüfung: zwei ausgewählte Geometrien, Divisoren 2, 3, 4 und 5. Relative Änderung des ungewichteten Gitterfeldes zum jeweils gröberen Netz:')
table(['Fall','Divisor 3','Divisor 4','Divisor 5'],[[i,*[fmt(mesh[(mesh.Case==i)&(mesh.Divisor==d)].RelativeChangeToCoarser.iloc[0],100,4)+' %' for d in [3,4,5]]] for i in [1,2]],[70,140,140,140])
p('Das zeigt Verfeinerungsstabilität an zwei Beispielen, keine flächendeckende Konvergenz oder exakte Kontinuumslösung. Der vorhandene ROM nutzt einen anderen affinen gemeinsamen FEM-Raum; dessen Test-Netzabweichung zur Originalreferenz beträgt im Median etwa 0,0601 %, maximal 0,1117 %. Für DeepONet wurden keine neuen FEM-Samples erzeugt.',small=True)
page()

heading('3 | Was die Verfahren untersuchen')
table(['Verfahren','Abbildung und untersuchte Frage'],[
['Scalar_GPR','Zwei separate Gaußprozesse bilden die sechs Parameter auf Spitze und Gittermaximum ab. Wie gut lassen sich nur skalare Zielgrößen lernen?'],
['Balkentheorie','Euler-Bernoulli-Spitze Fz L³/(3 E I), I=b h³/12. Liefert die einfache Mechanik bereits einen guten skalaren Referenzwert?'],
['Beam_plus_GPR','Gaußprozess lernt nur die FEM-Abweichung von dieser Balkenspitze. Hilft eine bekannte physikalische Näherung beim skalaren Lernen?'],
['POD_GP','Gewichtete, zentrierte Trainings-POD; Gaußprozesse für Koeffizienten. Wie gut trägt eine feste datenbasierte Feldbasis?'],
['POD_RBF','Gleiche POD-Idee; kubische Radialbasis mit linearem Polynom für Parameter-Koeffizienten-Abbildung.'],
['POD_MLP','Gleiche POD-Idee; neuronales tanh-Netz lernt ausschließlich POD-Koeffizienten, nicht die räumliche Basis.'],
['POD_Galerkin','Unzentrierte nodale Trainingsbasis im gemeinsamen FEM-Raum; Koeffizienten aus Kr a=fr mit Kr=Vᵀ K V. Mechanischer ROM, kein gelernter Regressor.'],
['DeepONet','Branch lernt Parameterkoeffizienten, Trunk gleichzeitig räumliche Funktionen. Kann eine gemeinsame lernbare Darstellung die festen POD-Regressoren ersetzen?']],[100,390])
p('Bestehende POD-Regressoren wählen Rang und weitere Kandidaten anhand der Validierung; Kandidatenränge [2,4,8,11]. MLP-Breiten [32,64], zwei tanh-Schichten, höchstens 300 Epochen. GP: standardisierte Ausgaben und ARD-Matern-5/2-Kernel; RBF-Regularisierung [0, 1e-8, 1e-6, 1e-4]. Ein vorhandener Modell-Seed 42. Diese Altmodelle erhalten keine nachträglich erfundene Seed-Streuung.')
p('ROM: 5586 gemeinsame Knoten, 3257 quadratische Tetraeder, 16509 freie Freiheitsgrade; Kandidatenränge [1,2,4,8,11]. Vollständige Geometrie und Steifigkeit werden online assembliert. Deshalb zählt die gesamte Assemblierung zur Online-Zeit. Seine frühere zusätzliche Snapshot-Erzeugung wird als historischer Aufwand getrennt berichtet.')
page()

heading('4 | Parametrische DeepONet-Adaption')
p('Branch-Eingang ist der endliche Parametervektor (L,b,h,E,nu,Fz), keine diskretisierte freie Eingabefunktion. Deshalb lautet die genaue Bezeichnung parametrische DeepONet-Adaption. Trunk-Eingang sind Referenzkoordinaten (xi,eta,zeta). Es wurde genau diese eine zusätzliche Architekturklasse implementiert.')
p('Beide Netze bestehen aus zwei voll verbundenen tanh-Schichten gleicher Breite und einer linearen Ausgabeschicht. Der Trunk erzeugt p räumliche Features t_k. Der Branch erzeugt drei getrennte Blöcke b_ck der Länge p, je einen für ux, uy, uz. Ihre Verknüpfung ist:')
p('<b>u_c(X,xi,eta,zeta) = s_u · xi · sum(k=1..p) b_ck(Z(X)) t_k(2[xi,eta,zeta]-1).</b>')
p('Der Faktor xi erzwingt u=0 bei xi=0 in allen drei Komponenten, ohne eine zusätzliche Rotationsrandbedingung aufzuzwingen. Gemeinsame Trunk-Features werden mit komponentenspezifischen Branch-Koeffizienten kombiniert. Branch und Trunk werden gemeinsam differenziert und optimiert; keine vorab gelernte oder eingefrorene POD-Basis wird benutzt.')
p('Eingang Z=(X-Trainingsmittel)/Trainingsstandardabweichung. Eine einzige gemeinsame physikalische Verschiebungsskala s_u=sqrt(mean_j sum_i w_i uRef_ij²) stammt ausschließlich aus den jeweiligen Trainingsfeldern. Alle drei Komponenten verwenden dieselbe Skala. Die Koordinatentransformation [-1,1] ist durch den Referenzraum festgelegt.')
p('Verlust = Mittel über physikalische Fälle der gewichteten relativen quadrierten Feldfehler. Die Nenner stammen im Training ausschließlich aus den Trainingszielen; zur Vorhersage wird kein Zielwert benötigt. Dadurch erhält jeder Fall das gleiche Gewicht, anstatt große Auslenkungen oder zusätzliche Punkte als zusätzliche Fälle zu zählen. Die Komponenten tragen entsprechend ihrer physikalischen Verschiebungsenergie bei; sehr kleine ux/uy können trotz gutem Gesamt-L2 schlechter sein.')
p('Effizienz: Branch einmal für alle Fälle im Batch, Trunk einmal für alle Abfragepunkte, anschließend drei Matrixprodukte. Training verwendet sämtliche Fälle einer Größe in einem vollständigen Batch und das vorhandene Gitter. Auswertung benötigt keine FEM-Matrix und kann beliebige Referenzpunkte entgegennehmen; Erfolg an neuen Punkten wird hier nicht durch neue FEM-Labels validiert.')
page()

heading('5 | Auswahl, Prüfungen und Wiederaufnahme')
p('Vorab festgelegtes Suchbudget: zwei Kandidaten je N, beide Seed 42. Kandidat 1: Breite 32, p=16; Kandidat 2: Breite 64, p=32. Adam startet mit 0,001, halbiert nach jeweils 500 Epochen, Maximum 1500 Epochen. Validierung alle zehn Epochen (zusätzlich Epoche 1), Abbruch nach 30 Prüfungen ohne relative Verbesserung von mindestens 1e-5. Das beste Validierungsmodell bleibt erhalten.')
p('Auswahlkriterium ist der mittlere quadrierte relative Validierungs-Feldfehler. Gewinner-Seed 42 wird wiederverwendet, weitere Seeds 43-46 werden mit derselben gewählten Konfiguration trainiert. Insgesamt 12 Such-Fits und 24 weitere Fits, also 36 reguläre Trainingsläufe und 30 finale Modelle. Testdaten dienen niemals zur Architektur-, Epoche- oder Seed-Auswahl. Alle 30 Modelle mussten vor der offiziellen Testauswertung vorliegen.')
table(['Prüfung','Tatsächlicher Status'],[
['Daten-/Split-Audit','Bestanden: alle sechs Größen, disjunkte IDs, identische Holdouts, Gitter, Gewichte und Spitze.'],
['Tensoren und Komponenten','matlab.unittest: Dimension 1575×N und separat nachgerechneter uy-Block bestanden.'],
['Gradienten','Verlust sowie sämtliche Branch-/Trunk-Gradienten endlich.'],
['Winziger Trainingssatz','Zwei Fälle, 3000 Epochen; maximaler Trainings-Feldfehler unter 3 %. Dies ist keine exakte Memorierung bis Maschinengenauigkeit.'],
['Einspannung','Exakt null an allen Clamp-Abfragepunkten, einschließlich sämtlicher offizieller DeepONet-Tests.'],
['Einzel-/Batchausgabe','Relative Differenz unter 2e-5; bestanden.'],
['Checkpoint-Wiederherstellung','Separater Test stellt das beste Netz aus dem vollständigen Checkpoint wieder her; bitidentische Vorhersage.'],
['Punktpermutation','Umgekehrte Abfragereihenfolge ergibt entsprechend umgeordnete identische Felder; bestanden.'],
['Vollständiger Probelauf','Interner Split der ursprünglichen Trainingsfälle: IDs 1-4 Training, 5-6 Validierung, 7-8 Test; 100 Epochen. Kein offizieller Test zur Auswahl.']],[135,355])
p('Checkpoint alle 100 Epochen, beim Abbruch und am Ende: aktuelles/bestes Netz, Adam-Momente, Epoche, Geduldzähler, Historie und Zeiten. Ein existierendes finales Modell wird unverändert zurückgegeben. Jeder reguläre Schritt protokolliert PASS/FAIL und Laufzeit; Fehler werden nicht als fehlende erfolgreiche Zeile verdeckt.',small=True)
page()

heading('6 | Feldgenauigkeit und Seed-Streuung')
fig('learning_curve.png')
fig('worst_curve.png')
p('Band: Minimum bis Maximum über fünf Trainingsinitialisierungen derselben Datenmenge; Linie: Median der fünf Kennzahlen. Dies ist kein Konfidenzintervall und keine Wiederholung des Daten-Samplings. Altmodelle besitzen jeweils nur einen gespeicherten Seed. Bei sechs Testfällen entspricht MATLAB prctile(...,95) hier dem Maximum.',small=True)
page()

heading('7 | Alle Trainingsgrößen im Vergleich')
table(['N','DeepONet Median [%]','Seed-Spanne [%]','DeepONet P95 [%]','POD-GP [%]','POD-RBF [%]','POD-MLP [%]','ROM [%]'],[
    [n,fmt(A.loc[n,'Median'],100),fmt(A.loc[n,'Min'],100)+' - '+fmt(A.loc[n,'Max'],100),fmt(A.loc[n,'P95'],100),
     *[fmt(B[(B.TrainingCases==n)&(B.Model==m)].FieldMedianRelL2.iloc[0],100) for m in ['POD_GP','POD_RBF','POD_MLP','POD_Galerkin']]] for n in COUNTS],
    [30,72,88,63,59,59,59,60])
p('Alle Kennzahlen in dieser Tabelle sind Prozent. DeepONet-Zellen zeigen jeweils den Median über Seeds, die Spanne alle fünf. P95 ist zunächst pro Seed über sechs Fälle berechnet, dann über Seeds medianisiert. Der schlechteste Seed-Fall wird zusätzlich ausgewiesen:')
table(['N','Schlechtester Fehler über 5×6 Tests [%]','Median Spitzen-MAE über Seeds [µm]','Median Gittermax.-MAE [µm]'],[
    [n,fmt(A.loc[n,'Worst'],100),fmt(G.TipMAE_m.median().loc[n],1e6),fmt(G.MaxGridMAE_m.median().loc[n],1e6)] for n in COUNTS],[40,150,150,150])
p('Ein kleiner Median allein kann problematische Fälle verbergen. Der sehr große historische POD-MLP-Ausreißer bei N=192 bleibt in den Vergleichsdaten und im Worst-Case-Diagramm sichtbar. Alle neuen Seed-Läufe sind in der folgenden Tabelle enthalten; keine Auswahl nach Testfehler.')
page()

heading('8 | Vollständige DeepONet-Seed-Ergebnisse')
table(['N','Seed','Median [%]','P95 / Max [%]','Spitze MAE [µm]','Best-Epoche','Fit [s]'],[
    [int(r.TrainingCases),int(r.Seed),fmt(r.FieldMedianRelL2,100),fmt(r.FieldWorstRelL2,100),
     fmt(r.TipMAE_m,1e6),int(r.BestEpoch),fmt(r.TrainingSeconds,1,1)] for r in S.itertuples()],
    [35,42,75,85,100,80,73])
p('CSV-Rohwerte speichern relative Fehler als Verhältnis und Verschiebungen in Metern. Diese Tabelle skaliert Feldfehler mit 100 und Verschiebungen mit 10⁶.',small=True)
page()

heading('9 | Gemeinsame skalare Zielgrößen')
p('Bei N=384 ergeben sich folgende MAE. Skalare Modelle werden nur in ihren vorhandenen Ausgaben verglichen. DeepONet-Werte zeigen die Median-Kennzahl über alle fünf Seeds und keine ausgesuchte Initialisierung.')
table(['Modell','Spitzen-MAE [µm]','Gittermaximum-MAE [µm]','Einspannfehler [m]'],[
    [r.Model,fmt(r.TipMAE_m,1e6,5),fmt(r.MaxGridMAE_m,1e6,5),fmt(r.ClampMax_m,1,12)]
    for r in B[B.TrainingCases==384].itertuples()]+[
    ['DeepONet (5 Seeds)',fmt(d384.TipMAE_m.median(),1e6,5),fmt(d384.MaxGridMAE_m.median(),1e6,5),'exakt 0']],
    [160,110,115,105])
p('Alle skalaren Größen der Feldmodelle werden aus demselben vollständigen Gitterfeld abgeleitet. Feld-L2 und absolute Spitzen-MAE gewichten die Fälle unterschiedlich; ein Modell kann deshalb bei einer Kennzahl besser und bei einer anderen schlechter sein. Die Balkenkorrektur enthält bewusst nur ein skalares Ziel und darf nicht als Feldmodell bewertet werden.')
table(['N','Scalar_GPR Spitze [µm]','Beam+GPR Spitze [µm]','Balkentheorie Spitze [µm]'],[
    [n,*[fmt(B[(B.TrainingCases==n)&(B.Model==m)].TipMAE_m.iloc[0],1e6,4) for m in ['Scalar_GPR','Beam_plus_GPR','Beam_theory']]] for n in COUNTS],[40,150,150,150])
page()

heading('10 | Rang und Projektionsuntergrenze')
table(['N','Modell','Rang','Projektionsmedian [%]','tatsächlicher Median [%]'],[
    [n,m,int(B[(B.TrainingCases==n)&(B.Model==m)].PODRank.iloc[0]),
     fmt(B[(B.TrainingCases==n)&(B.Model==m)].ProjectionMedianRelL2.iloc[0],100,5),
     fmt(B[(B.TrainingCases==n)&(B.Model==m)].FieldMedianRelL2.iloc[0],100,4)]
    for n in COUNTS for m in ['POD_GP','POD_RBF','POD_MLP','POD_Galerkin']],
    [35,115,45,145,150])
p('POD-Projektion: gewichtetes bestmögliches Testfeld im gewählten Ausgaberaum, bei KI-POD mit Trainingsmittelwert. Beim ROM wird O V statt nodaler Koordinaten gegen das Originalgitter projiziert. Die diagnostischen Test-Projektionskoeffizienten werden niemals zur eigentlichen Vorhersage benutzt. Kleine Projektionsfehler bei größerem Regressionsfehler sprechen für die Parameterabbildung als Engpass.',small=True)
p('Der ROM minimiert den Energiefehler im gemeinsamen FEM-Raum, nicht den Ausgabe-L2-Abstand zur anders vernetzten Originalreferenz. Historisch geprüft: maximales projiziertes Residuum 4,65e-11, freies vollständiges Residuum bis 32,96 %, Energiefehler bis 0,2555 %. Kleine Ausgabefehler bedeuten daher nicht exakt erfüllte freie FEM-Gleichungen.',small=True)
page()

heading('11 | Hardware und tatsächliche Rechenkosten')
p(f"Hardware: {HARDWARE['Name'].strip()}, {HARDWARE['NumberOfCores']} Kerne / {HARDWARE['NumberOfLogicalProcessors']} logische Prozessoren; Windows. MATLAB 25.2.0.3042426 (R2025b) Update 1. Neue DeepONets rechnen auf CPU mit Single-Precision-Netzen; Altmodelle/ROM nutzen ihre vorhandene numerische Präzision auf derselben CPU. Keine GPU-Auswertung, daher keine GPU-Synchronisationszeit.")
fig('cost_accuracy.png')
p('Neue Zeitmessung pro Methode/Fall: ein Warmup, fünf Wiederholungen, vollständiges Feld einschließlich Skalierung/Rekonstruktion. Tabelle: Median aller 30 Messungen pro Modell; DeepONet anschließend Median über Seeds. Scalar-Zeiten beziehen sich nur auf deren skalare Ausgaben und sind kein identischer Arbeitsumfang. Laden des Modells und Fehlerdiagnostik sind nicht Teil der Online-Inferenz. Kleine Zeitunterschiede sind wegen Systemlast, Caches und Timerauflösung nicht als robuste Beschleunigung zu interpretieren.')
table(['N','DeepONet [ms]','POD-GP [ms]','POD-RBF [ms]','POD-MLP [ms]','ROM [ms]'],[
    [n,fmt(A.loc[n,'Online'],1000),*[fmt(B[(B.TrainingCases==n)&(B.Model==m)].OnlineSeconds.iloc[0],1000) for m in ['POD_GP','POD_RBF','POD_MLP','POD_Galerkin']]] for n in COUNTS],
    [35,95,90,90,90,90])
page()

heading('12 | Offline-Aufwand und Suchbudget')
table(['N','gewählt Breite / p','Parameter','Suche 2 Fits [s]','5 finale Fits [s]','zusätzliche 4 Fits [s]','Vorbereitung 5 Fits [s]'],[
    [n,f"{int(SEL[(SEL.TrainingCases==n)&SEL.Selected].Width.iloc[0])} / {int(SEL[(SEL.TrainingCases==n)&SEL.Selected].Latent.iloc[0])}",
     int(S[S.TrainingCases==n].Parameters.iloc[0]),fmt(SEL[SEL.TrainingCases==n].Seconds.sum(),1,1),
     fmt(S[S.TrainingCases==n].TrainingSeconds.sum(),1,1),fmt(S[(S.TrainingCases==n)&(S.Seed!=42)].TrainingSeconds.sum(),1,1),
     fmt(S[S.TrainingCases==n].PreparationSeconds.sum(),1,3)] for n in COUNTS],
    [30,78,62,80,80,80,80])
p('Realer regulärer Optimierungsaufwand = beide Such-Fits + vier weitere Seeds je N. Die fünf finalen Fits enthalten den wiederverwendeten Gewinner-Seed 42 und werden nicht nochmals komplett zur Suche addiert. Fit-Zeit enthält laufende Validierung, aber keine Checkpoint-Schreibintervalle. Vorbereitung enthält Skalierung und Netzaufbau. events.csv misst die Gesamt-Schrittzeiten mit Dateiladen, Checkpoints und finalem Speichern; die Logausgabe folgt anschließend.')
prep=pd.read_csv(HERE/'data_preparation.csv')
p('Eine ergänzende, separat gemessene Wiederholung der Datenaufbereitung nach dem Training ist in data_preparation.csv enthalten: warme Ladezeit von Training/Validierung und reine Skalierungszeit, getrennt von Netztraining. Diese warmen Nachmessungen werden nicht als ursprünglich kalte Trainings-I/O ausgegeben. Sämtliche daraus berechneten Trainingsmittel, Standardabweichungen und Verschiebungsskalen stimmen exakt mit allen 30 Modellen überein.')
table(['N','Warme Ladezeit [ms]','Skalierung [ms]','gemeinsame Skala [µm]'],[[int(r.TrainingCases),fmt(r.WarmDataLoadSeconds,1000),fmt(r.ScalingSeconds,1000),fmt(r.DisplacementScale_m,1e6)] for r in prep.itertuples()],[35,155,145,155])
total=SEL.Seconds.sum()+S[S.Seed!=42].TrainingSeconds.sum()
wall=EVENTS[EVENTS.Stage.isin(['search','candidate1','candidate2','train'])].Seconds.sum()
p(f'Optimierung inklusive Suche: {fmt(total,1,1)} s; protokollierte Schrittzeiten inklusive I/O: {fmt(wall,1,1)} s. Tiny-Overfit und Workflow-Smoke sind separat. Fehlgeschlagene reguläre Schritte: {int(EVENTS.Status.eq("FAIL").sum())}; events.csv und failure_notes.md dokumentieren Fehler und Korrekturen.')
p('Datengewinnung ist hier ein bereits vorhandener Aufwand. Es wurden keine FEM-Fälle für DeepONet neu berechnet. Historische FEM-Zeiten der Originalfälle und zusätzliche gemeinsame ROM-Snapshots sind nicht mit reiner Fit-Zeit gleichzusetzen. Der vorhandene ROM benötigte 396 zusätzliche gemeinsame Snapshots, zusammen rund 497,69 s, und etwa 28-30 s Basis-/Rangwahl pro Größe. Diese historischen Zahlen sind kein neuer kontrollierter Offline-Benchmark.')
p('Die Trainingsreihe lief mit Unterbrechungen vom 23. bis 25.10.2026 und wechselnder Systemlast. Gespeicherte Fits werden bei Wiederaufnahme nicht erneut berechnet. Die Einzelzeiten sind gemessene Wallclock-Zeiten und kein streng kontrollierter Vergleich identischer Auslastung; insbesondere sind kurze und lange Fit-Zeiten verschiedener Tage nur eingeschränkt vergleichbar.')
page()

heading('12a | Ausführungsweg und Komponenten')
p('Die kleine Suche prüft zwei feste Konfigurationen, keine erschöpfende Optimierung. Ein schlechtes DeepONet-Ergebnis beweist daher nicht die Unterlegenheit jeder DeepONet-Konfiguration. Gleiche Epochenzahl bedeutet bei vollständigen Batches gleiche Zahl Adam-Updates, aber steigende Rechenarbeit pro Update bei größerem N.')
engine=pd.read_csv(HERE/'gradient_engine_benchmark.csv').iloc[0]
p(f'Nach dem ersten 384er-Kandidaten wurde die automatische Differenzierung profiliert und der gecachte Ausführungsweg dlaccelerate geprüft. Reiner Gradientenaufruf: {fmt(engine.PlainGradientSeconds,1,6)} s direkt, {fmt(engine.CachedGradientSeconds,1,6)} s gecacht, Faktor {fmt(engine.Ratio,1,2)}. Gemessene Verlust- und Gradientenabweichung: jeweils exakt null. Dies ist ein Kernelvergleich, keine gemessene Beschleunigung des gesamten Trainings.')
p('Die verbleibenden Fits (zweiter 384er-Kandidat und vier weitere Seeds) verwenden den gecachten Weg. Architektur, Verlust, Adam-Parameter und Auswahlregel bleiben gleich. Frühere finale Modelle wurden erhalten. Alle Fit-Zeiten sind tatsächlich gemessen; sie stammen damit aus zwei dokumentierten Ausführungswegen. source_snapshot_pre_cache bewahrt den zuvor verwendeten direkten Trainer; source_snapshot den finalen Stand. Profil und Benchmark liegen separat vor.')
components=pd.read_csv(HERE/'component_errors.csv')
components=components[components.TrainingCases.eq(384)]
p('Zusätzliche Komponentendiagnose bei N=384: je Komponente Median und Maximum über alle 5 Seeds mal 6 Testfälle. Die relative Komponentennorm bezieht sich jeweils nur auf die betreffende Referenzkomponente. Sie ist daher nicht mit dem gemeinsamen Feldfehler gleichzusetzen.')
table(['Komponente','Median relativ [%]','Maximum relativ [%]','Median abs. RMS [µm]'],[[name,fmt(components[components.Component.eq(c)].ComponentRelativeL2.median(),100),fmt(components[components.Component.eq(c)].ComponentRelativeL2.max(),100),fmt(components[components.Component.eq(c)].ComponentWeightedRMS_m.median(),1e6)] for c,name in enumerate(['ux','uy','uz'],1)],[85,135,135,135])
p('Die gemeinsame physikalische Verschiebungsskala und die Energienorm bevorzugen keine künstlich separat normierte kleine Komponente. Für Anwendungen mit hohen Anforderungen an kleine Komponenten ist diese Diagnose wichtiger als ein einzelner Gesamtfehler.')
page()

for label,caseid in zip(['gut','mittel','schlecht'],chosen):
    heading(f'13 | Räumliche Diagnose: {label}, Fall {caseid}')
    p('N=384, vorab fester DeepONet-Seed 42. Kategorien nach dessen sechs Testfehlern: kleinster, unterer mittlerer und größter Fehler. Diese nachträgliche Bildauswahl dient nur der Diagnose und ändert keine Modellwahl.',small=True)
    fig(f'spatial_{label}.png',w=470)
    p('Gleiche logarithmische Fehlerfarbskala in sämtlichen Methoden und allen drei Fällen; weiße Einspannpunkte haben exakt null Fehler. Dargestellt ist ein Referenzschnitt eta=0,5; die Kennzahlen nutzen weiterhin alle 525 Punkte. FEM-uz verwendet eine eigene signierte Farbskala.',small=True)
    page()

heading('14 | Fähigkeits- und Evidenzmatrix')
table(['Modell','Ausgaben','N','Parameter-Test','Weitere Evidenz'],[
['Scalar_GPR','Spitze, Gittermaximum','alle 6','6 feste Fälle','kein Feld'],
['Beam_plus_GPR','Spitze','alle 6','6 feste Fälle','kein Feld'],
['Beam_theory','Spitze','datenunabhängig','dieselben 6','analytisch; kein Feld'],
['POD_GP / RBF / MLP','Feld, Spitze, Gittermax.','alle 6','6 feste Fälle','Clamp-Gitter; POD-Floor'],
['POD_Galerkin','Feld, Spitze, Gittermax.','alle 6','6 feste Fälle','frühere Mechanik-/Energieprüfungen'],
['DeepONet','Feld, Spitze, Gittermax.','alle 6 × 5 Seeds','6 feste Fälle je Seed','7 Unit-Tests, exakte Clamp-Parametrisierung']],[105,125,65,80,115])
p('Die vollständige maschinenlesbare Matrix capability_matrix.csv führt Modell × Ausgabegröße × jede Trainingsgröße × Testart × Prüfstatus explizit auf. Fehlende Ausgaben werden nicht mit null Fehler verwechselt. Neue Topologien, Extrapolation und Transfer auf andere Netze/Geometriefamilien sind für alle Modelle als nicht untersucht markiert.')
p('Die früheren FEM-Skalierungs-, Assemblierungs-, Last-, Cholesky- und ROM-Einschlussprüfungen werden als vorhandene Evidenz referenziert. Sie wurden für diese rein datenbasierte Erweiterung nicht nochmals gerechnet. Neu ausgeführt wurden die DeepONet-Suite, Split-Audits, alle 36 regulären Fits und neue gemeinsame Ausgabe-/Zeitmessungen.')
p('Grenzen: nur sechs feste Validierungs- und sechs bereits bekannte Testfälle; eine Designreihe; Seed-Streuung nur der neuen Netze; keine unabhängigen Design-Wiederholungen. Test-P95 und Maximum fallen zusammen. Die Erweiterungen wurden nach Betrachtung früherer Testergebnisse beauftragt. Der Vergleich ist explorativ, keine neue blinde Bestätigung.')
p('Weiterhin nicht geprüft: Spannungen, lokale Spannungsspitzen, Plastizität, große Verformungen, Dynamik, wechselnde Einspannungen/Lastfunktionen, neue Topologien und Parameter außerhalb der definierten Bereiche. Die komponentenübergreifende Energienorm kann Fehler der viel kleineren Komponenten verdecken; einzelne Komponenten sollten bei entsprechenden Anwendungen zusätzlich gewichtet ausgewertet werden.')
page()

heading('15 | Bewertung und nächster Schritt')
for method in ['POD_GP','POD_RBF','POD_MLP','POD_Galerkin']:
    better=[str(n) for n in COUNTS if A.loc[n,'Median'] < B[(B.TrainingCases==n)&(B.Model==method)].FieldMedianRelL2.iloc[0]]
    worse=[str(n) for n in COUNTS if A.loc[n,'Median'] >= B[(B.TrainingCases==n)&(B.Model==method)].FieldMedianRelL2.iloc[0]]
    p(f'Deskriptiver Medianvergleich gegen {method}: DeepONet kleinerer Feldfehler bei N={", ".join(better) or "keinem"}; größerer oder gleicher Fehler bei N={", ".join(worse) or "keinem"}. Verglichen wird der Median aller fünf DeepONet-Seeds mit dem vorhandenen einzelnen Baseline-Modell.')
p('Statistische Gleichwertigkeit wurde nicht nachgewiesen. Weder überlappende Seed-Spannen noch ähnliche Fehler auf sechs bekannten Testfällen ersetzen eine unabhängige Bestätigung.')

ratio=d384.FieldMedianRelL2.median()/gp384.FieldMedianRelL2
p(f'Das neue DeepONet liegt bei N=384 im Seed-Median beim {fmt(ratio,1,2)}-fachen Feldfehler des vorhandenen POD-GPR. Diese Aussage bezieht sich auf die konkrete kleine Suche und die vorhandenen sechs Fälle. Die vollständigen Seed-Ergebnisse und Worst-Case-Werte sind maßgeblich; ein einzelner guter Lauf ist keine belastbare Empfehlung.')
uyMedian=components[components.Component.eq(2)].ComponentRelativeL2.median()
p(f'Besonders kritisch ist die kleine uy-Komponente: bei N=384 beträgt ihr komponentenbezogener relativer Medianfehler über alle Seeds und Testfälle {fmt(uyMedian,100)} %. Die gemeinsame Feldnorm wird vom größeren uz dominiert. Für Anforderungen an alle drei Komponenten ist der alleinige Feldmedian deshalb unzureichend; die Komponententabelle ist zwingend mitzulesen.')
mlp384=B[(B.TrainingCases==384)&(B.Model=='POD_MLP')].iloc[0]
p(f'Bei N=384 ist der größte DeepONet-Fehler über alle fünf Seeds und sechs Testfälle {fmt(d384.FieldWorstRelL2.max(),100)} %, beim vorhandenen POD-MLP {fmt(mlp384.FieldWorstRelL2,100)} %. Ein Medianvorteil und ein Vorteil beim schlechtesten bekannten Fall sind verschiedene Aussagen; diese kleine Stichprobe belegt keine sichere Tail-Garantie.')
p('Der klassische ROM bleibt auf diesem Ausgabegitter besonders genau und datensparsam, bezahlt dies jedoch mit voller Online-Assemblierung. POD-GPR ist eine starke schnelle Feld-Baseline. Für die einzelne Spitzenverschiebung ist die physikalische Balkenkorrektur besonders effizient. DeepONet bietet eine gemeinsam lernbare Ortsdarstellung und direkt erzwungene Einspannung; ein allgemeiner Genauigkeitsvorteil folgt daraus nicht.')
p('Empfehlung: vorhandene gute Baselines zunächst weiterverwenden. Vor größerer Hyperparametersuche oder einer Modellentscheidung einen neuen, getrennten Bestätigungstestsatz innerhalb der gleichen Parameterfamilie festlegen. Dabei Komponentenfehler, schwierige kleine Auslenkungen und Absolutfehler berücksichtigen. Erst danach gezielt untersuchen, ob mehr Trainingsbudget, andere Verlustgewichtung oder physikalisch motivierte Parametrisierung innerhalb derselben DeepONet-Klasse hilft. Solche Folgeexperimente wurden hier nicht gestartet.')
p('Der größere frühere pilot-Lauf wurde nicht gestartet. Der interne DeepONet-Workflow-Smoke ist eine getrennte kleine Funktionsprüfung vorhandener Fälle und kein zusätzlicher FEM-Pilot.')
page()

heading('16 | Reproduzierbarkeit und Dateien')
p('Im MATLAB-Projektordner ausführen; vorhandene Modelle werden wiederverwendet. Für einen unabhängigen neuen Versuch einen neuen Ausgabeordner wählen, nicht alte finale Modelle löschen oder überschreiben.')
commands='''addpath('src','tests')
run_deeponet_study("prepare")
run_deeponet_study("smoke")
results = runtests('tests/deeponetTest.m'); assertSuccess(results)
for N = [12 24 48 96 192 384]
    run_deeponet_logged("search",N)
    for seed = 42:46
        run_deeponet_logged("train",N,seed)
    end
end
for N = [12 24 48 96 192 384]
    for seed = 42:46
        run_deeponet_logged("evaluate",N,seed)
    end
end
run_deeponet_logged("summarize")
evaluate_deeponet_baselines
export_deeponet_diagnostics
% PDF außerhalb MATLAB: python build_report.py'''
p(escape(commands).replace('\n','<br/>'),small=True); md.append('```matlab\n'+commands+'\n```')
p('Direkte Vorhersage: a=load("experiments/deeponet_20261023_v1/n384/seed42/model.mat"); H=predict_deeponet(a.model,X,xi); X besitzt sechs SI-Spalten, xi drei Zeilen im Referenzraum. H ist [ux;uy;uz] in Metern.',small=True)
table(['Dateien','Inhalt'],[
['protocol.mat/json; *_ids.csv','vorab festgelegtes Budget, MATLAB-Version, sämtliche Split-IDs'],
['nN/candidateK; validation_selection.csv','beide Suchmodelle, Auswahlwerte und Trainingshistorien'],
['nN/seedS/model.mat; checkpoint.mat','finale Modelle; bei eigenen Fits resumierbarer Optimierer'],
['deeponet_summary/per_case.csv','30 Modellzeilen, 180 fallweise Testkennzahlen'],
['baseline_summary/per_case.csv','alle vorhandenen Verfahren; keine Nachtrainings'],
['*_timing_samples.csv; events.csv; logs','einzelne Messungen, tatsächliche Abläufe und Fehlerstatus'],
['capability_matrix.csv; representative_cases.csv','Fähigkeiten und eindeutig ausgewiesene räumliche Bildauswahl'],
['source_snapshot; protected_files.json','ausgeführter neuer Quellstand und Hashschutz alter Ergebnisse'],
['REPORT.md; build_report.py; figures; output/pdf','bearbeitbarer Bericht, Generator, Diagramme und PDF']],[200,290])

heading('Quellen')
p('Lu et al. (2021): Learning nonlinear operators via DeepONet based on the universal approximation theorem of operators. Nature Machine Intelligence 3, 218-229. DOI: 10.1038/s42256-021-00302-5. Grundidee Branch/Trunk; die konkrete endliche Parameter- und Mehrkomponenten-Adaption ist oben vollständig angegeben.',small=True)
p('MathWorks: Custom Training Loops; adamupdate; dlnetwork; dlgradient. https://www.mathworks.com/help/deeplearning/ug/custom-training-loops.html und https://www.mathworks.com/help/deeplearning/ref/adamupdate.html. Syntax zusätzlich mit lokaler R2025b-Hilfe geprüft. FEM: fegeometry, generateMesh, interpolateDisplacement und assembleFEMatrices in der PDE-Toolbox-Dokumentation.',small=True)
p('Projektquellen: config.m, src/solve_case.m, reference_grid.m, train_models.m, run_training_size_study.m, run_rom_study.m und gespeicherte Protokolle. Historische Original- und ROM-Ergebnisse liegen unverändert in den bisherigen Experimentordnern.',small=True)

def footer(canvas,doc):
    canvas.setStrokeColor(colors.HexColor('#B8C9D7')); canvas.line(42,35,553,35)
    canvas.setFont('Arial',7); canvas.setFillColor(colors.HexColor('#526779'))
    canvas.drawString(42,23,'FEM-Ersatzmodelle | DeepONet-Vergleich | 25.10.2026')
    canvas.drawRightString(553,23,f'{doc.page}')

(HERE/'REPORT.md').write_text('\n'.join(md),encoding='utf-8')
pdf=OUT/'FEM_Ersatzmodelle_DeepONet_Vergleich.pdf'
doc=SimpleDocTemplate(str(pdf),pagesize=(595.28,841.89),leftMargin=42,rightMargin=42,
                     topMargin=43,bottomMargin=48,title='FEM-Ersatzmodelle: DeepONet-Vergleich',author='MATLAB_FEM_Start')
doc.build(story,onFirstPage=footer,onLaterPages=footer)
print(pdf)
