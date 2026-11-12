"""Reproduce vector figures from the copied study tables; no model fitting."""
import csv
from pathlib import Path
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
from matplotlib.patches import FancyBboxPatch

ROOT=Path(__file__).resolve().parents[1]; DATA=ROOT/'daten'; OUT=ROOT/'abbildungen'
def read(name):
    with (DATA/name).open(encoding='utf-8-sig',newline='') as f:return list(csv.DictReader(f))
S=read('pipeline_summary_corrected.csv'); R=read('run_results.csv'); P=read('controlled_rank_n768.csv')
D=read('controlled_pod_diagnostics.csv'); O=read('extrapolation_outliers_paired.csv'); B=read('benchmark_summary.csv')
methods=['mlp','rbf','pod_mlp','pod_gpr']; labels=['MLP','RBF','POD–MLP','POD–GPR']; colors=['#365f94','#d18734','#43846b','#9e4568']
plt.rcParams.update({'font.size':9,'axes.spines.top':False,'axes.spines.right':False,'savefig.bbox':'tight','pdf.fonttype':42})
def save(name):
    plt.savefig(OUT/(name+'.pdf')); plt.close()

# Flow diagram: data roles and test guard, generated as editable vector graphics.
fig,ax=plt.subplots(figsize=(8.3,2.1)); ax.set_xlim(-.2,10.15); ax.set_ylim(0,2.7); ax.axis('off')
boxes=[(.05,1.1,1.6,.9,'FEM-Referenzen\nund Trainingspool'),(2.1,1.1,1.6,.9,'Training\nN = 48 … 768'),(4.15,1.1,1.6,.9,'Auswahl: N = 384\n128 Val.-Fälle'),(6.2,1.1,1.45,.9,'Freeze von\nModellen'),(8.1,1.1,1.8,.9,'Unabhängige Tests\nInterpolation / Extra.')]
for x,y,w,h,t in boxes:
    ax.add_patch(FancyBboxPatch((x,y),w,h,boxstyle='round,pad=0.1',facecolor='#edf2f7',edgecolor='#365f94'));ax.text(x+w/2,y+h/2,t,ha='center',va='center',fontsize=8)
for a,b in zip(boxes,boxes[1:]):ax.annotate('',xy=(b[0]-.12,1.55),xytext=(a[0]+a[2]+.12,1.55),arrowprops={'arrowstyle':'->','color':'#365f94'})
ax.text(5.0,.45,'Konfigurationen der Lernkurven bleiben nach der Auswahl fest',ha='center',fontsize=8)
save('ablauf')

fig,axes=plt.subplots(1,2,figsize=(8,3.2))
for m,l,c in zip(methods,labels,colors):
    rows=[next(r for r in S if r['role']=='interpolation' and r['method']==m and int(r['n'])==n) for n in [48,96,192,384,768]]
    axes[0].plot([48,96,192,384,768],[100*float(r['meanError']) for r in rows],'-o',label=l,color=c,ms=3.5)
    axes[1].plot([48,96,192,384,768],[float(r['fitMedian']) for r in rows],'-o',label=l,color=c,ms=3.5)
for ax in axes: ax.set_xscale('log',base=2);ax.set_yscale('log');ax.set_xticks([48,96,192,384,768],['48','96','192','384','768']);ax.grid(alpha=.22,which='both');ax.set_xlabel('Trainingsfälle N')
axes[0].set_ylabel('Mittlerer relativer Feldfehler [%]');axes[1].set_ylabel('Median Fit-Zeit [s]');axes[0].legend(fontsize=7)
fig.tight_layout();save('lernkurven')

fig,ax=plt.subplots(figsize=(7,3)); x=np.arange(4); width=.36
for j,(role,offset) in enumerate([('interpolation',-.18),('extrapolation',.18)]):
    v=[float(next(r for r in S if r['role']==role and r['method']==m and r['n']=='768')['meanError'])*100 for m in methods]
    ax.bar(x+offset,v,width,label='Interpolation' if j==0 else 'Extrapolation',color=('#365f94','#d18734')[j])
ax.set_xticks(x,labels);ax.set_ylabel('Mittlerer relativer Feldfehler [%]');ax.grid(axis='y',alpha=.2);ax.legend();fig.tight_layout();save('genauigkeit')

fig,axes=plt.subplots(1,2,figsize=(8,3)); ranks=[2,10,15]
for m,l,c in [('pod_mlp','POD–MLP',colors[2]),('pod_gpr','POD–GPR',colors[3])]:
    p=[next(r for r in P if r['method']==m and r['split']=='interpolation' and int(r['rank'])==k) for k in ranks]
    d=[next(r for r in D if r['Method']==m and r['Role']=='interpolation' and r['RunId'].replace('/','\\')==f'controlled\\n768_rep1_rank{k}_{m}') for k in ranks]
    axes[0].plot(ranks,[100*float(x['MeanRelativeRegression']) for x in d],'-o',color=c,label=l+' Regression')
    axes[1].plot(ranks,[float(x['fit_standalone_s']) for x in p],'-o',color=c,label=l)
axes[0].plot(ranks,[float(next(r for r in P if r['method']=='pod_gpr' and r['split']=='interpolation' and int(r['rank'])==k)['projection_percent']) for k in ranks],':o',color='#333333',label='Projektion (gemeinsam)')
axes[0].set_yscale('log');axes[0].set_ylabel('Mittlerer relativer Anteil [%]');axes[1].set_ylabel('Eigenständiger Fit inkl. POD [s]')
for ax in axes:ax.set_xticks(ranks);ax.set_xlabel('POD-Rang');ax.grid(alpha=.2);ax.legend(fontsize=7)
fig.tight_layout();save('pod_rang')

fig,ax=plt.subplots(figsize=(7,3));x=np.arange(4)
def dist(kind,m):
    return 100*float(next(r for r in R if r['id'].replace('/','\\')==f'distribution\\{kind}_{m}' and r['role']=='interpolation')['avg'])
a=[dist('space',m) for m in methods];b=[dist('skew',m) for m in methods]
ax.bar(x-.18,a,.36,label='raumfüllend',color='#365f94');ax.bar(x+.18,b,.36,label='konzentriert',color='#d18734')
ax.set_xticks(x,labels);ax.set_ylabel('Mittlerer relativer Feldfehler [%]');ax.set_title('Interpolation, N = 192');ax.legend();ax.grid(axis='y',alpha=.2);fig.tight_layout();save('verteilung')

fig,ax=plt.subplots(figsize=(7,3));vals=[1000*float(next(r for r in O if r['method']==m)['predicted_tip_m']) for m in methods];ref=1000*float(O[0]['fem_tip_m'])
ax.bar(np.arange(4),vals,color=colors);ax.axhline(ref,color='black',linestyle='--',label=f'FEM: {ref:.4f} mm');ax.axhline(0,color='gray',linewidth=.6)
ax.set_xticks(np.arange(4),labels);ax.set_ylabel('Vorhergesagtes Spitzen-$u_z$ [mm]');ax.set_title('Extrapolationsfall 830644, Seed 42');ax.legend();fig.tight_layout();save('ausreisser')

fig,ax=plt.subplots(figsize=(7,3));x=np.arange(4)
ax.bar(x-.18,[1000*float(next(r for r in B if r['method']==m)['surrogateSingleMedian']) for m in methods],.36,label='Einzelfall',color='#365f94')
ax.bar(x+.18,[1000*float(next(r for r in B if r['method']==m)['surrogateBatch12Median']) for m in methods],.36,label='Batch mit 12 Fällen',color='#d18734')
ax.set_xticks(x,labels);ax.set_ylabel('Vollständiger Vorhersageaufruf [ms]');ax.legend();ax.grid(axis='y',alpha=.2);fig.tight_layout();save('vorhersagezeit')
