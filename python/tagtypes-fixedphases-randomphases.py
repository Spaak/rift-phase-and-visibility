#%%

import itertools as it

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

# these are important to make sure we're exporting editable text
mpl.rcParams['pdf.fonttype'] = 42
mpl.rcParams['ps.fonttype'] = 42

colors = plt.rcParams["axes.prop_cycle"].by_key()["color"]

import bambi as bmb
import arviz as az

import os
os.chdir('/home/predatt/eelspa/riftbasics/analysis-4paper/python')

import util

plotdir = '/home/predatt/eelspa/riftbasics/analysis-4paper/plots'

#%% load data for spectra

df = pd.read_csv('/project/3018045.03/scratch/aggr-singlestim-spectra.csv')

# make df with better labels etc, and limit to tag types 1-4 plus no tagging
df = df.rename(columns={'frequency': 'Frequency', 'coherence': 'Coherence'})
df = df[(df.condition < 5) | (df.condition == 7)]
df['Tagging'] = df.condition.map({1: 'Type 1', 2: 'Type 2', 3: 'Type 3', 4: 'Type 4', 7: 'None'})

#%% spectra plots

df['log(Power)'] = np.log10(df['power'])

colors = sns.color_palette('deep', 4)
colors += [(0.5,0.5,0.5)] # append grey for no tagging

fig, allax = plt.subplots(nrows=1, ncols=5, figsize=(25,5))

ax = allax[0]
sns.lineplot(data=df, x='Frequency', y='log(Power)', hue='Tagging', errorbar='se',
             palette=colors, ax=ax, legend=None)
ax.set_xlim([0,80])

ax = allax[1]
sns.lineplot(data=df, x='Frequency', y='log(Power)', hue='Tagging', errorbar='se',
             palette=colors, ax=ax, legend=None)
ax.set_xlim([55,65])
ax.set_ylim(([-28.5, -27.8]))

ax = allax[2]
sns.lineplot(data=df, x='Frequency', y='Coherence', hue='Tagging', errorbar='se',
             palette=colors, ax=ax, legend=None)
ax.set_xlim([0,80])

ax = allax[3]
sns.lineplot(data=df, x='Frequency', y='Coherence', hue='Tagging', errorbar='se',
             palette=colors, ax=ax, legend=None)
ax.set_xlim([55,65])
#ax.set_ylim(([-28.5, -27.8]))

# plot legend in final axes
ax = allax[4]
sns.lineplot(data=df, x='Frequency', y='Coherence', hue='Tagging', errorbar='se',
             palette=colors, ax=ax)
sns.move_legend(ax, "upper left")
ax.set_xlim([55,65])
ax.set_ylim([10,11])
ax.set_axis_off()

sns.despine(fig)
plt.tight_layout()

fig.savefig('{}/spectra-tagtypes-fixedphases.pdf'.format(plotdir))

#%% SNR analyses: load data

# note: the single-trial power (snr per trial, then average across trials) results are almost
# identical to the average (avg across trials, then snr) results, so only use the
# avg results here (more easily comparable to the coherence results)
# df_tri = pd.read_csv('/project/3018045.03/scratch/aggr-singlestim-snr-alltri.csv')
df = pd.read_csv('/project/3018045.03/scratch/aggr-singlestim-snr-triavg.csv')

df = df.rename(columns={'snr_coherence': 'Coherence', 'snr_power_avg': 'Power', 'subject': 'Subject'})
df = df[(df.condition < 5) | (df.condition == 7)]
df['Tagging'] = df.condition.map({1: 'Type 1', 2: 'Type 2', 3: 'Type 3', 4: 'Type 4', 7: 'None'})

#%% plot

df_long = pd.melt(df, id_vars=["Subject", "Tagging"],
                  value_vars=["Power", "Coherence"])

fig, ax = plt.subplots(figsize=(7,4))
colors = sns.color_palette('deep', 4)
colors += [(0.5,0.5,0.5)] # append grey for no tagging
ax = sns.boxplot(df_long, x='variable', hue='Tagging', y='value',
               palette=colors, ax=ax)
sns.move_legend(ax, "upper left", bbox_to_anchor=(1, 1))
ax.set_ylabel('SNR (dB)')
ax.set_xlabel('')
sns.despine()
plt.tight_layout()

fig.savefig('{}/boxplots-tagtypes-fixedphases.pdf'.format(plotdir))

#%% stats

# make sure we use 'None' as reference level, by moving it explicitly first
lvls = ['None', 'Type 1', 'Type 2', 'Type 3', 'Type 4']
df['Tagging'] = df['Tagging'].astype(pd.CategoricalDtype(lvls))

depvars = ['Coherence', 'Power']
results = []
for depvar in depvars:
    model = bmb.Model(f'{depvar} ~ 1 + Tagging + (1|Subject)', df)
    res = model.fit(draws=1000)
    res.extend(model.prior_predictive(draws=1000))
    results.append(res)

# power vs coherence: simply average across the four tagging types
records = []
for n in df.Subject.unique():
    inds = (df.Subject==n) & (df.Tagging != 'None')
    records.append(dict(Subject=n, Type='Power', SNR=df[inds]['Power'].mean()))
    records.append(dict(Subject=n, Type='Coherence', SNR=df[inds]['Coherence'].mean()))
df2 = pd.DataFrame(records)
model = bmb.Model('SNR ~ 1 + C(Type) + (1|Subject)', df2)
results_cohvspow = model.fit(draws=1000)
results_cohvspow.extend(model.prior_predictive(draws=1000))

#%% compute pairwise differences between regression coefficients in prior/posterior

# note: prior variances will be considerably higher when priors are
# constructed this way, compared to when they would be constructed
# using a direct paired comparison. This is likely analogous to an
# implicit multiple comparison correction, because it has the effect
# of making Bayes factors go more in the direction of H0.

for res in results:
    for a, b in it.combinations(range(4), 2):
        res.posterior = res.posterior.assign({'Type {} - Type {}'.format(b+1, a+1): lambda x: x['Tagging'][:,:,b] - x['Tagging'][:,:,a]})
        res.prior = res.prior.assign({'Type {} - Type {}'.format(b+1, a+1): lambda x: x['Tagging'][:,:,b] - x['Tagging'][:,:,a]})

#%% store results

# output posterior descriptives and bayes factors
resultsfile = '/home/predatt/eelspa/riftbasics/analysis-4paper/stats-tagtypes-fixedphases.txt'
with open(resultsfile, 'w') as f:
    with pd.option_context('display.width', 1000):
        for label, res in zip(depvars + ['Coh vs Pow'], results + [results_cohvspow]):
            print('{}:\n{}\n\n'.format(label, util.extended_summary(res)), file=f)


#%% SNR fixed vs random phases: load data

df = pd.read_csv('/project/3018045.03/scratch/aggr-singlestim-snr-tagvscrosstriphase.csv')
df['Phases'] = df.PhasesRandom.map({0: 'Fixed', 1:'Random'})
df['Tagging'] = df.Tagging.map({1: 'Type 1', 4: 'Type 4'})
df['Reference'] = df.Corrected.map({0: 'ITC', 1: 'Phase-corrected'})
df['Reference'] = df.Reference.astype(pd.CategoricalDtype(['ITC', 'Phase-corrected']))
df = df.drop(columns=['PhasesRandom', 'Corrected'])

#%% plot

fig, ax = plt.subplots(figsize=(6,4))


colors = [(.5, .5, .5), (.8, .8, .8)]

sns.boxplot(df, x='Reference', y='SNR', orient='v', hue='Phases', width=0.5, palette=colors,
            boxprops={'edgecolor': 'k'}, medianprops={'color': 'k'}, whiskerprops={'color': 'k'}, capprops={'color': 'k'},
            fliersize=0, ax=ax, dodge=True)

# plot individual (linked) observations for both tagging types
colors = sns.color_palette('deep', 4)
colors = [colors[0], colors[3]]
jitter_size = 0.02
pointdodge = 0.4
xmap = {('ITC', 'Fixed'): -pointdodge,
        ('ITC', 'Random'): pointdodge,
        ('Phase-corrected', 'Fixed'): 1-pointdodge,
        ('Phase-corrected', 'Random'): 1+pointdodge}
dfplot = df.copy()
dfplot['xcoord'] = dfplot.apply(lambda x: xmap[(x.Reference, x.Phases)], axis=1)
for c, tag in zip(colors, ['Type 1', 'Type 4']):
    for ref in dfplot.Reference.unique():
        for sub in dfplot.Subject.unique():
            inds = (dfplot.Subject==sub) & (dfplot.Tagging==tag) & (dfplot.Reference==ref)
            ydat = dfplot.SNR[inds]
            xdat = dfplot.xcoord[inds]
            xdat += np.random.randn(2)*jitter_size
            ax.plot(xdat, ydat, c=c + (0.2,), marker='o', markerfacecolor=c, markersize=5,
            zorder=-1)

sns.despine()
plt.tight_layout()
plt.gcf().savefig('{}/boxplots-tagtypes-fixed-and-random-phases.pdf'.format(plotdir))

#%% stats: modelling

model = bmb.Model('SNR ~ 1 + Phases * Reference + (1|Subject)', df)
print(model)
results_2x2 = model.fit(draws=1000)
results_2x2.extend(model.prior_predictive(draws=1000))

model = bmb.Model('SNR ~ 0 + Phases:Reference + (1|Subject)', df)
print(model)
results_cellwise = model.fit(draws=1000)
results_cellwise.extend(model.prior_predictive(draws=1000))


#%% add pairwise comparisons

conds = [str(x.values) for x in results_cellwise.posterior.coords['Phases:Reference_dim']]

for a, b in it.combinations(range(4), 2):
    mapper = {f'{conds[a]} - {conds[b]}': lambda x: x['Phases:Reference'][:,:,a] - x['Phases:Reference'][:,:,b]}
    results_cellwise.posterior = results_cellwise.posterior.assign(mapper)
    results_cellwise.prior = results_cellwise.prior.assign(mapper)

#%% save results

resultsfile = '/home/predatt/eelspa/riftbasics/analysis-4paper/stats-tagtypes-fixed-and-random-phases.txt'
with open(resultsfile, 'w') as f:
    with pd.option_context('display.width', 1000):
        print('2x2:', file=f)
        print(util.extended_summary(results_2x2), file=f)
        print('\n cellwise:', file=f)
        print(util.extended_summary(results_cellwise), file=f)

