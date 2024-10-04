# RIFT phase and visibility

The experiment and analysis code for Spaak, Bouwkamp, & De Lange (2024). [Perceptual foundation and extension to phase tagging for rapid invisible frequency tagging (RIFT)](https://doi.org/10.1162/imag_a_00242). Imaging Neuroscience, 2, 1–14. [https://doi.org/10.1162/imag_a_00242](https://doi.org/10.1162/imag_a_00242)

# Brief general code overview

The code is split between Python and Matlab. Everything that directly deals with MEG data is done in Matlab (using custom scripts and FieldTrip). Matlab code either exports data to .csv files, for further analysis in Python, or produces plots directly (topoplots, source plots). You'll find references to some absolute paths in the code. Whenever the path `/project/3018045.03/` is mentioned, the relevant data should be available at the Donders/Radboud Repository under [https://doi.org/10.34973/8dx5-7e51](https://doi.org/10.34973/8dx5-7e51). Whenever `/home/predatt/eelspa/riftbasics/analysis-4paper/` is mentioned, this basically refers to the present repository. Obviously, you'll need to adapt these paths if you want to run the code yourself.

Where possible, I've included all intermediate and raw files in either this repo or in the data repository. The only clear exception I'm aware of is that I'm not including the Polhemus headshape data for the participants, which are considered sensitive data (i.e.: identifiable head shape information). The head models that were built using these head shape data *are* included (not sensitive anymore at that stage).

For the Python code, a complete conda environment specification is included under `python/conda-spec-file.txt`.

# More detailed outline of data and files

(in relation to figures in the paper and related stats)

## Matlab

- Figure 3 (spectra, pow/coh SNR, topos)
	- `/home/predatt/eelspa/riftbasics/analysis-4paper/matlab/process_assess_snr_and_spectra.m`
		- Loads from: `/project/3018045.03/scratch/sub%03d-snr-and-spectra.mat`
			- Comes from: `job_assess_snr_and_spectra.m`
		- Writes plots to `/home/predatt/eelspa/riftbasics/analysis-4paper/plots`
			- `topos-tagtypes-fixedphases.pdf`
			- `colorbar.pdf`
		- Writes results to `/project/3018045.03/scratch/`
			- `aggr-singlestim-spectra.csv`
			- `aggr-singlestim-snr-triavg.csv`

- Figure 4 (SNR for ITC versus phase-corrected coherence X random vs fixed phases)
	- `/home/predatt/eelspa/riftbasics/analysis-4paper/matlab/process_assess_snr_tagvscrosstriphase.m`
		- Loads from: `/project/3018045.03/scratch/sub%03d-snr-tagvscrosstriphase.mat`
			- Comes from: `job_assess_snr_tagvscrosstriphase.m`
		- Writes results to `/project/3018045.03/scratch/aggr-singlestim-snr-tagvscrosstriphase.csv`

- Figure 5 (RIFT phase tagging)
	- `/home/predatt/eelspa/riftbasics/analysis-4paper/matlab/process_dipfits_phasetag.m`
		- Loads from:
			- `/project/3018045.03/scratch/sub%03d-phaseproject-topos-dipfits-alltri.mat` (type 1 tagging)
			- `/project/3018045.03/scratch/sub%03d-phaseproject-topos-dipfits-alltri-tagtype4.mat`
				- Both come from: `job_phaseproject_dipolefit.m`
					- Note: run this job twice (per subject), once for tag type 1, once for tag type 4 (manually edit lines 22/26/31/230)
					- Loads from: `/scratch/sub%03d-headmodel-template-warped.mat`
						- Which comes from: `run_interactive_template_warp_headmodel.m`
		- Writes plots to `/home/predatt/eelspa/riftbasics/analysis-4paper/plots`
			- `sourceplots-dipole-density-phasetag.png`
			- `sourceplots-colorbar.pdf`


- General files:
	- `fetch_clean_data.m`
		- Loads from:
			- `/project/3018045.03/scratch/sub%03d-cleaned-600Hz.mat`
			- `/project/3018045.03/scratch/sub%03d-cleaned-600Hz-attnblocks.mat`
			- `/project/3018045.03/scratch/sub%03d-preproc-ica-demean-weights.mat`
			- `/project/3018045.03/scratch/sub%03d-preproc-ica-badcomps.mat`
		- These files come from a sequence of:
			- `run_preproc_beforeica`/`run_preproc_beforeica_attnblocks` (note: attentional blocks never used)
			- `run_preproc_ica`
			- `run_preproc_afterica`
		- In turn depending on `expscript_v3/MakeOnsetTrig.m`
	- `append_corrected_tagsigs_v3_and_metadata`.m
		- Used in `run_preproc_beforica`, this is where the tagging signal is time-corrected for a potential lag between trigger and light sensor rampup and for buffer flips missed by more than 1ms.
	- `make_trial_selection.m`

## Python

- Figure 2 & behavioural stats:
	- `python/behaviour.py`
		- Loads from: `/project/3018045.03/scratch/aggr-behaviour-axb.csv`
		- Launches jobs `job_behaviour_sensitivity.py` and loads results
			- writes to `sensitivity-results/run-XXX.pkl`
		- Writes to:
			- `stats-behaviour.txt`
			- `plots/violins-behaviour.pdf`
			- `plots/sensitivity-analysis-behaviour.pdf`

- Figures 3 & 4 & stats for spectra and SNR:
	- `python/tagtypes-fixedphases-randomphases.py`
		- Loads from:
			- `/project/3018045.03/scratch/aggr-singlestim-spectra.csv`
			- `/project/3018045.03/scratch/aggr-singlestim-snr-triavg.csv`
			- `/project/3018045.03/scratch/aggr-singlestim-snr-tagvscrosstriphase.csv`
		- Writes to:
			- `plots/spectra-tagtypes-fixedphases.pdf`
			- `plots/boxplots-tagtypes-fixedphases.pdf`
			- `stats-tagtypes-fixedphases.txt`
			- `plots/boxplots-tagtypes-fixed-and-random-phases.pdf`
			- `stats-tagtypes-fixed-and-random-phases.txt`

- Figure 5 & stats for phase tagging dipole fits:
	- `python/tagging-dipolefits-xcoords.py`
		- Loads from:
			- `/project/3018045.03/scratch/aggr-dipfits-phase0and90-tagtype1-withgroupingvar.csv`
			- `/project/3018045.03/scratch/aggr-dipfits-phase0and90-tagtype4-withgroupingvar.csv`
		- Writes to:
			- `plots/boxplots-phaseproject-xcoords.pdf`
			- `stats-phaseproject-xcoords.txt`

- General files:
	- `util.py` - some utilities, mainly for easily reporting pymc results to text files including Bayes factors (based on code directly from pymc/bambi)
	- `myqsub.py` - execute Python job in parallel across a Torque(-compatible) cluster (with 'qsub' command)
