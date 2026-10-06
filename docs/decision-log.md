# Analysis Decision Log

Record consequential data, method, and tooling decisions here so that both language tracks can be reviewed and reproduced. Update the status and evidence after decisions are tested; do not describe planned work as a completed result.

## Decision record template

For each new decision, copy and complete this entry:

- **ID / date:**
- **Phase:**
- **Question:**
- **Decision and status:** Proposed / accepted / tested / superseded
- **Alternatives considered:**
- **Rationale and evidence:** Include checks, diagnostics, references, and reviewer notes.
- **Impact on Python and R:**
- **Revisit when:** State what new evidence or requirement would change the decision.

---

## D-001 — Use one Bank Marketing file for the practice pipeline

- **Date:** 2026-10-05
- **Phase:** Scope and data validation
- **Question:** Which dataset version is the single input for this exercise?
- **Decision and status:** Accepted — use `BankMarketing.csv` only. The inspected file has 41,188 records and 21 columns, with the `bank-additional-full` schema. Do not append or merge another Bank Marketing version.
- **Alternatives considered:** Add the older `bank-full.csv` version as more records; use both versions as one pooled dataset.
- **Rationale and evidence:** The versions have different schemas and no reliable record-matching key. The current file has the additional campaign/economic fields intended for this exercise. A separate sensitivity study could be added later, but is outside the single-dataset scope.
- **Impact on Python and R:** Both tracks read the same raw file independently. Each validates the semicolon delimiter, schema, row count, outcome labels, and special values before analysis.
- **Revisit when:** The project explicitly expands to multi-version benchmarking and defines a separate protocol for comparing non-joinable datasets.

## D-002 — Keep the outcome and post-contact duration out of segmentation

- **Date:** 2026-10-05
- **Phase:** Feature definition and segmentation
- **Question:** Which fields can define segments?
- **Decision and status:** Accepted — exclude `y` from all segmentation features and use it only for post-segmentation validation. Exclude `duration` from predictors because it is only known after the call.
- **Alternatives considered:** Include `y` to create groups with different response rates; use `duration` as a predictor.
- **Rationale and evidence:** Including `y` would make outcome differences in the resulting groups circular. `duration` creates post-outcome leakage for a prediction task.
- **Impact on Python and R:** Enforce the exclusions in both feature-preparation steps and add tests that fail if either field enters the segmentation matrix.
- **Revisit when:** A separately specified descriptive analysis has a justified, non-predictive purpose for examining `duration`; it must remain distinct from the primary segmentation.

## D-003 — Maintain parallel, independently reproducible Python and R tracks

- **Date:** 2026-10-05
- **Phase:** Project architecture
- **Question:** How should the two language implementations be organized?
- **Decision and status:** Accepted — each language will run independently from the raw CSV to the documented parameter-table schema. Keep language environments and generated outputs separate while sharing variable definitions, input assumptions, and evaluation criteria.
- **Alternatives considered:** Use one language for the complete pipeline and the other only for LCA; have R consume Python-generated intermediate data.
- **Rationale and evidence:** The exercise is intended to compare the end-to-end tooling experience. Shared intermediate results would hide setup and reproducibility differences.
- **Impact on Python and R:** Use separate dependency/environment lock files, record package versions and seeds, and align feature meaning and model evaluation. Do not require matching cluster IDs or identical stochastic results.
- **Revisit when:** A deployment requirement or method is only supportable in one language; document that exception and its effect on comparability.

## D-004 — Treat survival analysis as a feasibility assessment

- **Date:** 2026-10-05
- **Phase:** Outcome modelling
- **Question:** Can the current fields support time-to-response analysis?
- **Decision and status:** Accepted — do not promise a survival model unless an event time, time origin, and censoring mechanism can be justified. `pdays` describes time since a previous contact, and `999` denotes no previous contact; it is not automatically time to the current subscription.
- **Alternatives considered:** Treat `pdays` as time until the current response and fit survival models directly.
- **Rationale and evidence:** That interpretation is not established by the available summary fields and could produce misleading timing estimates.
- **Impact on Python and R:** First document the feasibility assessment. Only if it supports a valid outcome should the two tracks fit comparable models (`lifelines` in Python and `survival` in R).
- **Revisit when:** Contact-level event timestamps and defensible censoring information become available.

## D-005 — Limit full-data hierarchical clustering claims

- **Date:** 2026-10-05
- **Phase:** Segmentation
- **Question:** How should hierarchical clustering be handled at this dataset size?
- **Decision and status:** Accepted — assess memory and runtime before a full-data distance matrix. A sampled analysis is exploratory and must be labelled as such; do not report it as a full-data solution.
- **Alternatives considered:** Construct a dense pairwise distance matrix for all 41,188 records without first checking resource requirements.
- **Rationale and evidence:** Pairwise distance storage grows quadratically with record count and may require substantial memory, before additional algorithm overhead.
- **Impact on Python and R:** Record sample-selection rules, seed, and sample size if sampling is used; compare only results with clearly stated scope.
- **Revisit when:** A validated scalable implementation or adequate compute resources are available.

## D-006 — Lock and smoke-test the Python environment with uv (superseded)

- **Date:** 2026-10-05
- **Phase:** Reproducible setup
- **Question:** How should Python dependencies be resolved and verified?
- **Decision and status:** Superseded by D-008. Historically tested — `pyproject.toml` and `uv.lock` resolved 74 packages; `uv sync --locked --all-extras --all-groups` installed 53 packages in the project-local Python 3.11.9 virtual environment.
- **Alternatives considered:** Unlocked installs or manually maintained version pins without a generated transitive lock.
- **Rationale and evidence:** Imports succeeded for the planned data, clustering, LCA, Bayesian, survival, mixed-clustering, plotting, and test packages. Verified versions include pandas 3.0.6, scikit-learn 1.9.1, StepMix 3.0.0, PyMC 5.28.5, ArviZ 0.23.4, lifelines 0.30.0, and pytest 9.1.1.
- **Impact on Python and R:** Historically, Python was restored with `uv sync --locked --all-extras --all-groups`; this workflow is superseded by D-008. The local R runtime was verified separately; no R packages or R lockfile were installed/generated because the request was to avoid downloads.
- **Caveats:** PyTensor reported that `g++` was unavailable and warned that C implementations could not be compiled, potentially slowing PyMC. Imports passed, but a representative Bayesian sampling run has not yet been tested.
- **Revisit when:** R package installation is authorized, or a PyMC sampling benchmark shows that a C++ toolchain is needed for acceptable performance.

## D-007 — Point the R extension at the existing local R runtime

- **Date:** 2026-10-06
- **Phase:** Reproducible setup
- **Question:** Can the installed VS Code R extension use an R runtime already on this machine without downloading software?
- **Decision and status:** Tested — use the existing R 4.4.0 installation at `C:\My_RStudio\R-4.4.0`. Correct the user-level `r.executablePath` and `r.consolePath` settings to `C:\My_RStudio\R-4.4.0\bin\R.exe`; do not set a machine-specific absolute path in the shared workspace.
- **Alternatives considered:** Point the extension at `unins000.exe` (the prior, incorrect setting); add the local executable path to shared workspace settings; install another R distribution.
- **Rationale and evidence:** The R extension is installed. `Rscript.exe --version` reports R 4.4.0, and `r/01_validate_data.R` passed using base R: 41,188 rows, 21 columns, 36,548 `no`, 4,640 `yes`, and no actual `NA` values. The old settings targeted the uninstaller, not the R executable.
- **Impact on Python and R:** The extension's `r.executablePath` and `r.consolePath` settings point to the valid R binary at user scope. The invalid `r.libPaths` entry pointing at `R.exe` was removed. `r.sessionWatcher` and `r.lsp.enabled` are disabled to stop auto-install attempts for `sess` and `languageserver`; base R console use remains available, while session/workspace viewer and language-server features are disabled. Reload VS Code after these changes.
- **Caveats:** The extension's `sess` setup could not reach CRAN and reported missing dependencies (`processx`, `later`, `jsonlite`, `rstudioapi`). `cluster` and base `survival` are installed; `renv`, `poLCA`, `brms`, `rstanarm`, `readr`, `dplyr`, `ggplot2`, `recipes`, `forcats`, `testthat`, `DBI`, and `RSQLite` are not installed. No project packages were downloaded. R dependency locking and package-level model tests remain pending.
- **Revisit when:** The team authorizes package installation; then initialize `renv`, install only required packages, snapshot `renv.lock`, restore in a clean library, and run R package/model smoke tests.

## D-008 — Use requirements.txt for Python dependencies

- **Date:** 2026-10-06
- **Phase:** Reproducible setup
- **Question:** Should the Python dependencies be managed with `uv` and TOML/lock files, or a pip requirements file?
- **Decision and status:** Accepted — use `requirements.txt` with pip and a project-local virtual environment. Remove `pyproject.toml` and `uv.lock` from the project.
- **Alternatives considered:** Continue with the tested `uv` workflow and its exact transitive lock; keep both workflows; use a requirements file with pinned versions.
- **Rationale and evidence:** The project setup should be straightforward and use the familiar `python -m pip install -r requirements.txt` workflow. Include the previously optional analysis and test packages in the same file so all planned Python methods are installable.
- **Impact on Python and R:** Create/activate `.venv` with Python 3.11 and install from `requirements.txt`. Keep R dependency management separate. Package versions are currently unpinned, so record installed versions and expect dependency resolution to vary over time.
- **Revisit when:** Exact repeatability becomes a requirement; pin tested package versions in `requirements.txt` or adopt a separate lockfile.
