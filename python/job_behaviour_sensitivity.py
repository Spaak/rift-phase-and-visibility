# Copyright 2024 Eelke Spaak, Donders Institute.
# See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
# Belongs with:
# Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
# to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
# https://doi.org/10.1162/imag_a_00242

#%% imports

import pickle

import pymc as pm
import numpy as np
import pandas as pd
import bambi as bmb
import arviz as az

import os
os.chdir('/home/predatt/eelspa/riftbasics/analysis-4paper/python')

import util

#%%

def load_data():
    #% load data
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

    # remove timeouts
    df_full = df_full[df_full.Response > 0]
    to_kick_out = df_full.groupby(['Subject', 'Condition']).count()
    to_kick_out = to_kick_out[to_kick_out.Accuracy==1].index
    assert len(to_kick_out) == 1

    df_acc = df_full.groupby(['Subject', 'Condition']).mean().reset_index()
    df_acc = df_acc[~((df_acc.Subject == to_kick_out[0][0]) & (df_acc.Condition == to_kick_out[0][1]))]

    return df_full, df_acc


def run_simulation(seed):
    np.random.seed(seed)
    df_full, df_acc = load_data()

    # simulate data using a given sensitivity and compute BF
    def _simulate_data(mu_sens, sd_sens=None):
        if sd_sens is None:
            # use actually observed spread in accuracies
            df = df_acc.groupby('Subject').mean()
            sd_sens = np.std(df.Accuracy)

        sub_accs = {sub: np.random.normal(loc=mu_sens, scale=sd_sens) for sub in df_full['Subject'].unique()}

        # draw data of same subject and (per-subject) trial count as observed
        df_sim = []
        # limit to one "condition", arbitrarily (this is the one with most trials)
        df = df_full[df_full.Condition == '60 Hz vs no tagging (type 4)']
        for k, row in df.iterrows():
            row = row.copy()
            if np.random.uniform() < sub_accs[row.Subject]:
                row.Response = row.ProbeStim
            elif row.ProbeStim == 1:
                row.Response = 2
            else:
                row.Response = 1
            df_sim.append(row)
        return pd.DataFrame(df_sim)

    # check these actual accuracies
    accs_to_check = np.arange(0.4, 0.61, 0.01)
    allbf01 = []
    for acc in accs_to_check:
        print('now checking acc={:.3g}'.format(acc))
        df_sim = _simulate_data(mu_sens=acc)

        # recode probe and response as 0/1 (such that Bernoulli regression works)
        df_sim_recode = df_sim.copy()
        df_sim_recode.ProbeStim -= 1
        df_sim_recode.Response -= 1

        model = bmb.Model('Response ~ 1 + ProbeStim + (1 + ProbeStim|Subject)', df_sim_recode, family='bernoulli')
        results = model.fit() # do the MCMC using default priors
        results.extend(model.prior_predictive()) # also sample from prior to facilitate BF computation

        bf = util.compute_bf(results, 'ProbeStim')
        allbf01.append(bf['BF01'])

        bf_resultsfile = '/home/predatt/eelspa/riftbasics/analysis-4paper/sensitivity-results/run-{:03d}.pkl'.format(seed)
        with open(bf_resultsfile, 'wb') as f:
            pickle.dump(dict(accs_to_check=accs_to_check, allbf01=allbf01), f)


def testfun(seed):
    print(pm.__file__)
