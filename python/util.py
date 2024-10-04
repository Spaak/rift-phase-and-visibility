# Copyright 2024 Eelke Spaak, Donders Institute.
# See https://github.com/Spaak/rift-phase-and-visibility for readme/license.
# Belongs with:
# Spaak, E., Bouwkamp, F. G., & de Lange, F. P. (2024). Perceptual foundation and extension
# to phase tagging for rapid invisible frequency tagging (RIFT). Imaging Neuroscience, 2, 1–14.
# https://doi.org/10.1162/imag_a_00242

import logging

import numpy as np

from scipy.stats import gaussian_kde
_log = logging.getLogger(__name__)

import arviz as az
from arviz.utils import _var_names
from arviz.data.utils import extract

def _my_extract(idata, var_name, **kwargs):
    """
    Extract data from InferenceData while optionally indexing along one dimension.
    """
    try:
        ind = var_name.index('[')
        level_name = var_name[ind+1:var_name.index(']')]
        var_name = var_name[0:ind]
    except ValueError:
        level_name = None

    data = extract(idata, var_names=var_name, **kwargs)

    if level_name is not None:
        data = data.loc[level_name,:]
    
    return data


def compute_bf(idata, var_name, ref_val=0):
    posterior = _my_extract(idata, var_name=var_name)

    if ref_val > posterior.max() or ref_val < posterior.min():
        _log.warning(
            "The reference value is outside of the posterior. "
            "This translate into infinite support for H1, which is most likely an overstatement."
        )
    
    prior = _my_extract(idata, var_name=var_name, group="prior")

    if posterior.dtype.kind == "f":
        posterior_pdf = gaussian_kde(posterior)
        prior_pdf = gaussian_kde(prior)
        posterior_at_ref_val = posterior_pdf(ref_val)
        prior_at_ref_val = prior_pdf(ref_val)
    elif posterior.dtype.kind == "i":
        prior_pdf = None
        posterior_pdf = None
        posterior_at_ref_val = (posterior == ref_val).mean()
        prior_at_ref_val = (prior == ref_val).mean()

    bf_10 = prior_at_ref_val / posterior_at_ref_val
    bf_01 = 1 / bf_10

    return {"BF10": bf_10, "BF01": bf_01}

def extended_summary(idata, var_names=['~Intercept', '~1|', '~_sigma'], filter_vars='like'):
    summary = az.summary(idata, var_names=var_names, filter_vars=filter_vars)
    summary = summary.drop(['mcse_mean', 'mcse_sd', 'ess_bulk', 'ess_tail'], axis='columns')
    for v in summary.index:
        bf = compute_bf(idata, v)
        summary.at[v,'bf_10'] = '{:.5g}'.format(bf['BF10'][0])
        summary.at[v,'bf_01'] = '{:.5g}'.format(bf['BF01'][0])
    
    return summary
