# Copyright 2024 Eelke Spaak, Donders Institute.
# See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
# Belongs with:
# Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
# to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
# https://doi.org/10.1162/imag_a_00242

#%%

import numpy as np
import scipy as sp

import matplotlib.pyplot as plt
plt.ion()

import seaborn as sns
import pandas as pd

import matplotlib as mpl
mpl.rcParams['axes.linewidth'] = 0.5
mpl.rcParams['xtick.major.width'] = 0.5
mpl.rcParams['ytick.major.width'] = 0.5
mpl.rcParams['font.family'] = 'Muli'
mpl.rcParams['font.size'] = 14

import bambi as bmb
import arviz as az

# these are important to make sure we're exporting editable text
mpl.rcParams['pdf.fonttype'] = 42
mpl.rcParams['ps.fonttype'] = 42


from IPython.core.display_functions import display

import os
os.chdir('/home/predatt/eelspa/riftbasics/analysis-4paper/python')

import util

plotdir = '/home/predatt/eelspa/riftbasics/analysis-4paper/plots'

#%% load data

df1 = pd.read_csv('/project/3018045.03/scratch/aggr-dipfits-phase0and90-tagtype1-withgroupingvar.csv')
df4 = pd.read_csv('/project/3018045.03/scratch/aggr-dipfits-phase0and90-tagtype4-withgroupingvar.csv')
df1['subnum'] = list(range(1,13)) + list(range(1,13))
df4['subnum'] = list(range(1,13)) + list(range(1,13))
df1['Tagging'] = 'Type 1'
df4['Tagging'] = 'Type 4'

df = pd.concat([df1, df4])
display(df)

#%% plot

fig, ax = plt.subplots(figsize=(5,2.5))

ax.axvline(0, ls=':', c='k')

colors = sns.color_palette('Set2', 2)
colors = [c + (0.5,) for c in colors]

# sns.boxplot(df, x='x', y='is_shift', orient='h', boxprops={'facecolor': 'none', 'edgecolor': 'k'}, width=0.5, 
#             fliersize=0, ax=ax)
sns.boxplot(df, x='x', y='is_shift', orient='h', hue='is_shift', palette=colors, width=0.5,
            boxprops={'edgecolor': 'k'}, medianprops={'color': 'k'}, whiskerprops={'color': 'k'}, capprops={'color': 'k'},
            fliersize=0, ax=ax, dodge=False)
plt.legend([],[], frameon=False)
# note: fliersize=0 means don't plot outliers, but ONLY do this if we later plot the individual points!

# plot individual (linked) observations for both tagging types
colors = sns.color_palette('deep', 4)
colors = [colors[0], colors[3]]
jitter_size = 0.04
for c, tag in zip(colors, ['Type 1', 'Type 4']):
    for sub in df.subnum.unique():
        inds = (df.subnum==sub) & (df.Tagging==tag)
        xdat = [df.x[inds & (df.is_shift==0)], df.x[inds & (df.is_shift==1)]]
        ydat = np.random.randn(2)*jitter_size + [0,1]
        ax.plot(xdat, ydat, c=c + (0.2,), marker='o', markerfacecolor=c, markersize=5)

ax.set_xlim([-40,52])
ax.set_xlabel('MNI x (mm)')
ax.set_ylabel('Dipole phase')
ax.set_yticklabels(['0°', '90°'])

sns.despine()
plt.tight_layout()

fig.savefig('{}/boxplots-phaseproject-xcoords.pdf'.format(plotdir))

#%% overall stats

allmodels = {}
allresults = {}

for depvar in ['x', 'r2']:
    model = bmb.Model('{} ~ 1 + is_shift + (1|subnum)'.format(depvar), df)
    results = model.fit(draws=4000)
    # note: lots of draws because it makes the BF more stable; needed here because the reference
    # value (0) falls outside the posterior's support with the default number of draws (1000)
    results.extend(model.prior_predictive(draws=4000))
    print(model)

    allmodels[depvar] = model
    allresults[depvar] = results

#%% save stats

resultsfile = '/home/predatt/eelspa/riftbasics/analysis-4paper/stats-phaseproject-xcoords.txt'

with open(resultsfile, 'w') as f:
    for depvar in ['x', 'r2']:
        print('{}:\n{}\n'.format(depvar,
                                 util.extended_summary(allresults[depvar],
                                                       var_names=['~1|', '~_sigma']
                                                       )), file=f)



