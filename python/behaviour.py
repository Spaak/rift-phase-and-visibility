# Copyright 2024 Eelke Spaak, Donders Institute.
# See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
# Belongs with:
# Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
# to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
# https://doi.org/10.1162/imag_a_00242


#%% imports

import pickle

import itertools as it

import numpy as np

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

# these are important to make sure we're exporting editable text
mpl.rcParams['pdf.fonttype'] = 42
mpl.rcParams['ps.fonttype'] = 42

colors = plt.rcParams["axes.prop_cycle"].by_key()["color"]

import bambi as bmb
import arviz as az

from fastprogress.fastprogress import master_bar, progress_bar

from IPython.core.display_functions import display

import os
os.chdir('/home/predatt/eelspa/riftbasics/analysis-4paper/python')

import util

plotdir = '/home/predatt/eelspa/riftbasics/analysis-4paper/plots'

#%% load data

df_full = pd.read_csv('/project/3018045.03/scratch/aggr-behaviour-axb.csv')

# add condition and accuracy (correct=True/False) column (accuracy used in plots)
def _cond(row):
    if np.min(row[['FreqL', 'FreqR']]) == 0 and row['TagType'] == 1:
        return '60 Hz vs no tagging (type 1)'
    elif np.min(row[['FreqL', 'FreqR']]) == 0 and row['TagType'] == 4:
        return '60 Hz vs no tagging (type 4)'
    elif np.min(row[['FreqL', 'FreqR']]) == 60 and row['TagType'] == 1:
        return '60 Hz vs 66 Hz (type 1)'
    else:
        return '(invalid condition)'
df_full['Condition'] = df_full.apply(_cond, axis=1)

df_full['Accuracy'] = df_full['Response'] == df_full['ProbeStim']

#%% preprocessing: report on and remove timeouts

df_timeout = df_full.copy()
df_timeout['Timeout'] = (df_timeout.Response == 0).astype('float')
df_timeout = df_timeout[['Subject','Timeout']]
display(df_timeout.groupby('Subject').mean().Timeout.describe())

df_full = df_full[df_full.Response > 0]

#%% violin plots

# remove subjects with only one response per condition (only holds for single subject) for plot
# note: not needed for Bayesian stats

to_kick_out = df_full.groupby(['Subject', 'Condition']).count()
to_kick_out = to_kick_out[to_kick_out.Accuracy==1].index
assert len(to_kick_out) == 1

df_acc = df_full.groupby(['Subject', 'Condition']).mean().reset_index()
df_acc = df_acc[~((df_acc.Subject == to_kick_out[0][0]) & (df_acc.Condition == to_kick_out[0][1]))]

fig, ax = plt.subplots(figsize=(5,4))
sns.swarmplot(data=df_acc, x='Condition', y='Accuracy', ax=ax, color='k')
sns.violinplot(data=df_acc, x='Condition', y='Accuracy', ax=ax, width=0.5, bw='silverman', color='k', inner=None)
plt.setp(ax.collections, alpha=.3, edgecolor='none')
ax.set_ylim([0,0.85])
ax.set_yticks(np.arange(0,0.751,0.25))
ax.set_xticklabels(['60 vs 66 Hz\nType 1', '60 vs 0 Hz\nType 1', '60 vs 0 Hz\nType 4'])
sns.despine()
plt.tight_layout()
plt.axhline(0.5, ls=':', c='k')

fig.savefig('{}/violins-behaviour.pdf'.format(plotdir))


#%% Bayesian stats

# recode probe and response as 0/1 (such that Bernoulli regression works)
df_recode = df_full.copy()
df_recode.ProbeStim -= 1
df_recode.Response -= 1

allmodels = {}
allresults = {}

# separate stats for each of the three conditions
for condition in np.sort(df_full.Condition.unique()):
    df = df_recode[df_recode.Condition == condition]
    model = bmb.Model('Response ~ 1 + ProbeStim + (1 + ProbeStim|Subject)', df, family='bernoulli')
    allmodels[condition] = model
    results = model.fit() # do the MCMC using default priors
    results.extend(model.prior_predictive()) # also sample from prior to facilitate BF computation
    allresults[condition] = results

# output posterior descriptives and bayes factors
resultsfile = '/home/predatt/eelspa/riftbasics/analysis-4paper/stats-behaviour.txt'
with open(resultsfile, 'w') as f:
    for condition in np.sort(df_full.Condition.unique()):
        print('{}:\n{}\n'.format(condition, az.summary(allresults[condition])), file=f)
        bf01 = az.plot_bf(allresults[condition], var_name='ProbeStim', ref_val=0, show=False)[0]['BF01']
        print('{}: BF01 = {}'.format(condition, bf01), file=f)


#%% sensitivity analysis on cluster

import os
os.chdir('/home/predatt/eelspa/riftbasics/analysis-4paper/python')

import myqsub
import imp; imp.reload(myqsub)

myqsub.qsub('walltime=00:30:00,mem=6gb,nodes=1:intel:ppn=4',
            'job_behaviour_sensitivity',
            'run_simulation', list(range(1, 301)))

#%% load sensitivity analysis results

accs_to_check = np.arange(0.4, 0.61, 0.01)
allbf = []
missing = []
for k in range(1, 301):
    try:
        with open('../sensitivity-results/run-{:03d}.pkl'.format(k), 'rb') as f:
            dat = pickle.load(f)
            assert np.allclose(accs_to_check, dat['accs_to_check'])
            thisbf = [x[0] for x in dat['allbf01']]
            assert(len(thisbf) == len(accs_to_check))
            allbf.append(thisbf)
    except:
        missing.append(k)
allbf = np.asarray(allbf)

#%% store as dataframe for easy plotting with pandas

df_bf = []
for run, accind in it.product(range(allbf.shape[0]), range(len(accs_to_check))):
    df_bf.append({'Run': run,
                  'Accuracy': accs_to_check[accind],
                  'BF01': allbf[run,accind]})
df_bf = pd.DataFrame(df_bf)

df_bf['log2(BF01)'] = np.log2(df_bf['BF01'])

#%% plot

fig, ax = plt.subplots()

sns.lineplot(df_bf, x='Accuracy', y='log2(BF01)',
             estimator='median',
             errorbar=lambda x: np.quantile(x, (0.25, 0.75)),
             err_kws=dict(ec=None),
             ax=ax, ls='--', lw=1, c='k')
ax.set_ylim([-5,5])
ax.set_xlim([0.4, 0.6])
#sns.boxplot(df_bf, x='Accuracy', y='log2(BF01)')

# for reference: BFs from actual data
obs_bfs = np.log2([19.4642163, 19.44697409, 26.05412224])
ax.fill_between([0.4, 0.6], obs_bfs.min(), obs_bfs.max(),
                 facecolor=(0,0.5,0,0.6))

# indicate strength of evidence
ax.fill_between([0.4, 0.6], np.log2(1/3), np.log2(3), facecolor=(0,0,0,0.8))

# fit log-quadratic curve
curve = np.median(np.log2(allbf), axis=0)
params = np.polyfit(accs_to_check, curve, deg=2)
accs_interp = np.linspace(accs_to_check.min(), accs_to_check.max(), 200)
bfs_fit = np.polyval(params, accs_interp)
ax.plot(accs_interp, bfs_fit, lw=1)

# highlight all accuracies for which the curve falls inside the band
inds = np.flatnonzero((bfs_fit >= obs_bfs.min()) & (bfs_fit <= obs_bfs.max()))
minacc = accs_interp[inds.min()]
maxacc = accs_interp[inds.max()]
ax.fill_betweenx([-5,obs_bfs.min()], minacc, maxacc,
                 facecolor=(0,0.5,0,0.2))

ax.set_xticks([0.4, 0.45, 0.5, 0.55, 0.6])
ax.set_ylabel('BF01')
ax.set_yticks(np.log2([1/10, 1/3, 1, 3, 10]))
ax.set_yticklabels(['1/10', '1/3', '1', '3', '10'])

sns.despine()

fig.savefig('{}/sensitivity-analysis-behaviour.pdf'.format(plotdir))