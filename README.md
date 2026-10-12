# Behavioural Segmentation Practice Pipeline

A training exercise for a data science team preparing to build a behavioural population-segmentation pipeline for a national census programme. The restricted census data is not available for practice, so this project uses the UCI/Kaggle **Bank Marketing** dataset as a structural stand-in.

> **Important:** This is a tooling and methods rehearsal only. The dataset and any findings from it do not represent the census population or provide real-world insights about the census programme.

## Project goals

Practice two independent, end-to-end implementations—one in Python and one in R—that segment records by behavioural covariates, estimate behavioural parameters for each segment with uncertainty, and package results in the same documented schema. Compare the tooling, results, runtime, and implementation effort while keeping each language's environment and outputs separate.

## Dataset

The project uses the Bank Marketing dataset. The current raw CSV is at `data/BankMarketing.csv` (update the configured input path if you use another location). The data concerns direct marketing campaigns by a Portuguese banking institution.

The CSV currently in this workspace uses semicolons as delimiters and has 21 columns, including `day_of_week` and economic indicators such as `emp.var.rate`, `cons.price.idx`, `cons.conf.idx`, `euribor3m`, and `nr.employed`. It appears to use the 41,188-record `bank-additional-full` schema. Treat these details as a preliminary file inspection, not a substitute for validating the complete dataset at runtime.

Before modelling, run a data/schema check that confirms the expected delimiter, required columns, row and column counts, outcome labels, and missing-value conventions. Fail with a clear error if parsing produces one column or required variables are absent. Record the verified dataset version and source in the run metadata so that results are reproducible.

## Variable definitions

| Bank Marketing column | Practice concept | Notes |
| --- | --- | --- |
| `y` | Response outcome | Main outcome to explain: subscribed (`yes`) or did not subscribe (`no`). Do not use it to form segments. |
| `contact` | Contact channel | Categorical channel, such as cellular or telephone. |
| `campaign` | Contact attempts | Number of contacts in the current campaign. |
| `pdays` | Time since previous intervention | Days since the client was last contacted in a previous campaign; check the dataset's special value for “not previously contacted” before analysis. |
| `previous` | Prior intervention history | Number of contacts before the current campaign. |
| `poutcome` | Prior response behaviour | Outcome of the previous marketing campaign. |
| `age`, `job`, `marital`, `education`, `housing`, `loan` | Demographic/area covariates | Practice stand-ins for census demographic attributes. |
| `month`, `day_of_week` | Contact timing | Calendar context for the last contact; document whether these are available at the intended prediction point. |
| `emp.var.rate`, `cons.price.idx`, `cons.conf.idx`, `euribor3m`, `nr.employed` | Economic context | Additional fields present in the current CSV; decide and document whether they are eligible covariates for each analysis. |
| `duration` | Excluded from predictors | Call duration is only known after the call. Exclude it from segmentation and predictive models to avoid leakage; it may be used for post-hoc analysis only. |

Before modelling, inspect the raw file and document the final predictor list, outcome encoding, missing-value handling, and any transformations. Define the prediction point explicitly: fields such as `campaign`, `pdays`, `previous`, `poutcome`, `month`, and `day_of_week` must only be predictors if they would be known at that point. In particular, exclude information recorded after the prediction point. Segmentation must use covariates only—not `y` or `duration`.

## Pipeline stages

### Stage 1 — Variable definition

Document which columns represent each behavioural concept. Confirm `y` as the outcome and specify legitimate predictors, excluding `duration` and the outcome itself from segmentation. Record any data-cleaning and encoding decisions.

### Stage 2 — Segmentation

**Goal:** group records into a small number of behaviourally distinct segments using covariates only, then compare subscription rates across segments as a post-segmentation validation.

Implement and compare the following methods in order:

1. **K-Means clustering** — quick baseline. Because the data contains categorical and numeric fields, document the encoding and scaling choices and their limitations. One-hot encoding can make distance behaviour depend on category counts, so consider a mixed-data distance method as a sensitivity comparison where practical.
2. **Hierarchical clustering** — comparison method; document the distance/linkage choices and any practical constraints. Select a distance appropriate for mixed data (for example, Gower distance) or explain the encoding-based alternative.
3. **Latent Class Analysis (LCA)** — a more realistic candidate for the likely real-project method.
   - Implement Python LCA with `stepmix` and R LCA with `poLCA` as parallel tracks.
   - `poLCA` uses categorical indicators; document any binning of numeric variables and align the input definitions as closely as the two implementations allow.

Choose the number of clusters/classes using documented, outcome-independent evidence. For K-Means and hierarchical clustering, report suitable internal metrics and sensitivity to choices such as random seed, scaling, distance, and linkage. For LCA, compare candidate class counts using information criteria such as BIC (and AIC where useful), class sizes, convergence, and classification uncertainty/entropy. Check whether solutions are stable across initializations. Use the same analysis variables and comparable preprocessing in the Python/R LCA comparison.

After clustering, report segment sizes and subscription rates by segment, with uncertainty intervals where practical. If subscription rates do not differ meaningfully, report that as a result rather than hiding it. Do not use the outcome to select the number of segments, choose a solution, or construct segments; treat `y` as a post-hoc validation outcome only.

### Stage 3 — Parameter estimation per segment

Estimate behavioural parameters with uncertainty rather than reporting only point estimates:

- **Logistic regression per segment:** estimate the probability of `y = yes`; report uncertainty and explain how small or separated samples are handled.
- **Time-to-event / survival feasibility:** assess whether a defensible event-time setup can be defined. In this dataset, `pdays` is time since a previous contact—not necessarily time to the current response—and `999` represents no previous contact. Unless event time and censoring can be justified, document why survival analysis is unsupported rather than reporting a misleading estimate. If justified, use Python `lifelines` and R `survival` with the same event definition.
- **Bayesian hierarchical model:** use Python `PyMC` and R `brms` (or `rstanarm`) to estimate segment-level subscription probabilities while allowing smaller segments to borrow strength. Document priors, diagnostics, interval definitions, runtime, and fitting issues; the models need not produce identical estimates, but their assumptions must be comparable.

### Stage 4 — Parameter packaging

Write a documented parameter table to a local SQLite database or CSV. Use this exact schema:

| Column | Description |
| --- | --- |
| `segment_id` | Segment identifier; use a documented value for population-wide parameters if needed. |
| `variable_name` | Behavioural variable or parameter being described. |
| `parameter_type` | Type of parameter or distribution (for example, probability or survival parameter). |
| `value_or_distribution` | Point estimate and/or distribution summary, with uncertainty represented where appropriate. |
| `confidence_level` | Report the level and interval type (for example, `95% confidence interval` or `95% credible interval`). Keep the required column name even for Bayesian estimates. |
| `evidence_source` | Model, analysis stage, or data source supporting the parameter. |
| `notes` | Interpretation, assumptions, caveats, or other relevant details. |

Use a consistent, machine-readable representation for `value_or_distribution` (for example, a documented JSON object with `estimate`, `lower`, and `upper` fields). State the interval type in `confidence_level`, and include units, outcome coding, and distribution parameterization in `notes` where relevant. Do not label credible intervals as confidence intervals.

## Phase-by-phase implementation tracks

Run each phase from the same raw CSV. Python and R must validate their inputs independently, use separately managed dependencies, and produce comparable outputs without one track relying on intermediate files from the other.

| Phase | Work and methods | Python tools | R tools | Phase output |
| --- | --- | --- | --- | --- |
| 0. Reproducible setup | Create independent environments, record package versions and seeds, and define shared column/feature specifications. | Python virtual environment, `requirements.txt` | `renv`, `renv.lock` | Separate environments and run configuration for each language. |
| 1. Ingest and validate | Read the semicolon-delimited CSV; check schema, row/column counts, outcome labels, missing-value conventions, and special values such as `pdays = 999`. | `pandas`, `pytest` | Base R `read.csv()` initially; `readr`, `dplyr`, `testthat` after the R environment is locked | Validation report; fail early on unexpected data. |
| 2. Explore and define variables | Summarize distributions and outcome rates; define behavioural predictors, context variables, excluded fields, and the prediction point. | `pandas`, `seaborn`, `matplotlib` | `dplyr`, `ggplot2` | Data dictionary, descriptive tables/plots, and a documented feature specification. |
| 3. Prepare features | Apply documented categorical encoding, numeric scaling/transformation, and special-value handling. Keep `y` and `duration` out of segmentation features. | `scikit-learn` `ColumnTransformer`, `OneHotEncoder`, `StandardScaler` | `recipes`, `forcats`, `scale()` or explicitly equivalent transformations | Prepared feature matrices and preprocessing notes. |
| 4. Segment | Compare K-Means, hierarchical clustering, and LCA; choose class counts without using `y`; examine stability and segment profiles. | `scikit-learn` `KMeans`; SciPy hierarchy; `stepmix`; optional `kmodes`/Gower library | `stats::kmeans()`; `cluster::daisy()`/`agnes()`; `poLCA` | Segment assignments, class-count evidence, sizes, profiles, and stability summaries. |
| 5. Estimate and validate outcomes | Compare `y` by segment after clustering; estimate probabilities and uncertainty. Assess survival only if valid event-time/censoring information can be defined. | `statsmodels`, PyMC, ArviZ; `lifelines` only if justified | `glm(family = binomial)`, `brms`/`rstanarm`; `survival` only if justified | Outcome rates/models with confidence or credible intervals, diagnostics, and limitations. |
| 6. Package results | Write the required parameter schema and run metadata. | `pandas`, built-in `sqlite3` or SQLAlchemy | `DBI`, `RSQLite`, `readr` | One parameter-table export per language, with the same columns and documented value format. |
| 7. Compare and report | Compare assumptions, outcomes, stability, runtime, environment setup, and ease of use; explain disagreements rather than forcing identical results. | Python run logs and reports | R run logs and reports | Tooling comparison and a reproducibility/limitations summary. |

Hierarchical clustering on all 41,188 records can require substantial memory, particularly for a dense pairwise distance matrix. Treat a sampled hierarchical run as exploratory and document the sample; do not describe it as a full-data result. For R's `poLCA`, categorical indicators are expected, so any numeric binning must be explicit and its information loss discussed. Align feature meaning and preprocessing across languages, but do not expect cluster IDs or stochastic solutions to match exactly.

For step-by-step Windows instructions for Python, R, RStudio, and Git/GitHub collaboration, see the [Python and R setup guide](docs/setup-guide.md). The workspace does not yet include the R validation script or an `renv.lock`; the guide distinguishes the available setup checks from planned pipeline work.

## Engineering and reproducibility standards

- Keep all project code and documentation in a shared GitHub repository, using meaningful commit messages.
- Each notebook or script should run end-to-end from the raw CSV through the final parameter table. Document setup and execution steps; avoid undocumented manual steps.
- Add a short README for each stage describing what was tried, what worked, what did not, and why.
- Record consequential data, method, and library choices—including alternatives, rationale, evidence, and revisit conditions—in the [analysis decision log](docs/decision-log.md). Add code comments for local implementation caveats, but keep the decision rationale in the log.
- Keep the raw data, generated outputs, and dependencies clearly identified. Do not commit data or derived files unless the repository's data-handling policy permits it.
- Follow a Reproducible Analytical Pipeline (RAP) approach: version-control code, manage and record dependencies separately for Python and R, validate inputs, automate the raw-data-to-output workflow, test key assumptions, log each run, and peer-review code and results. Document any unavoidable manual step.

## Comparison and project notes

Compare both complete pipelines, and include a focused comparison of Python LCA (`stepmix`) and R LCA (`poLCA`): ease of use, reliability, documentation, setup, convergence, class-count evidence, runtime, and uncertainty handling. If any phase is not implemented in one language, record it as incomplete rather than claiming a full end-to-end comparison.

Record whether the PyMC hierarchical model was straightforward to fit and how long it took to run, including relevant environment details. This is a genuine planning data point for estimating the real project's timeline.

## Completion criteria

- Independent, reproducible Python and R pipelines each run from the raw CSV through validation, segmentation, outcome analysis, and final parameter-table export.
- Segmentation methods are compared, and segment differences in `y` are evaluated after clustering.
- Parameter estimates include appropriate uncertainty and documented assumptions.
- The final table follows the specified schema and is saved as CSV or in SQLite.
- A comparison write-up documents the Python/R tooling experience, including LCA; a note records Bayesian model fitting experience and runtime for each implemented language.
- At least one other team member reviews the final parameter table before it is considered complete, practising the two-reviewer standard planned for the real project.

## Data source and attribution

The dataset is the **Bank Marketing** dataset from the [UCI Machine Learning Repository](https://archive.ics.uci.edu/dataset/222/bank+marketing), also used in the linked Kaggle notebook. UCI lists the dataset under the **Creative Commons Attribution 4.0 International (CC BY 4.0)** license. Retain appropriate attribution when redistributing or adapting the data, and verify the source and license of the specific copy used in this repository.

## This is a line from Rstudio