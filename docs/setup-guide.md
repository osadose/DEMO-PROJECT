# Getting started: Python, R, RStudio, and GitHub

This guide is for team members setting up the project on Windows. Follow the parts you need: everyone should get the project from GitHub; Python users set up Python; R users set up R and can work in RStudio.

> **Project status:** The setup instructions below are ready to use. The analysis scripts and R dependency lockfile are not in this workspace yet, so there is not a complete pipeline to run. The checks here only confirm that your environment can read the data.

## 1. Install the tools

Install these programs before you begin:

- **Git for Windows** — lets your computer exchange project changes with GitHub.
- **Python 3.11** — needed for the Python work.
- **R 4.4 or newer** — needed for the R work.
- **RStudio Desktop** — recommended for R users; it is free to use for this project.

You can download these from their official websites. RStudio is an editor for R; it does not install R itself, so install both. After installing Git, Python, and R, open PowerShell and check that they are available:

```powershell
git --version
py -3.11 --version
Rscript --version
```

If one of these commands is not recognized, close and reopen PowerShell. If it still is not recognized, ask your IT support or project lead to check the installation and PATH settings.

## 2. Get a copy of the project from GitHub

You need access to the team's GitHub repository. Ask the project lead for its web address and make sure your GitHub account has permission to view it.

### Option A: Clone with RStudio

1. Open RStudio.
2. Select **File > New Project > Version Control > Git**. If you already have a project open, first close it or use the same menu to start a new project.
3. In GitHub, open the team repository and select the green **Code** button. Copy the URL under **HTTPS**.
4. Paste that URL into RStudio's **Repository URL** box.
5. Choose a folder on your computer where you keep projects. RStudio will create a new folder for this checkout; do not choose a folder that already contains another copy of the project.
6. Select **Create Project**. RStudio downloads the project and opens it.

If RStudio reports that it cannot find Git, open **Tools > Global Options > Git/SVN**, check that the Git executable is detected, and restart RStudio. If GitHub asks you to sign in, use the sign-in window or your organization's approved credential manager. Do not paste a password or token into a project file or chat.

### Option B: Clone with PowerShell

1. In GitHub, open the team repository, select **Code**, and copy its **HTTPS** URL.
2. Open PowerShell and go to the parent folder where you want the project saved. For example:

   ```powershell
   Set-Location "$HOME\Documents\GitHub"
   ```

3. Clone the repository, replacing the example URL with the one you copied:

   ```powershell
   git clone https://github.com/OWNER/REPOSITORY.git
   Set-Location REPOSITORY
   ```

After cloning, open the new repository folder in RStudio (**File > New Project > Existing Directory**) or VS Code. The repository root is the folder containing `README.md`.

## 3. Set up your Git name and email (once per computer)

Git records who made each commit. In PowerShell, enter your own name and the email associated with your GitHub account:

```powershell
git config --global user.name "Your Name"
git config --global user.email "you@example.com"
```

These commands set your identity for Git on this computer. They do not sign you in to GitHub. GitHub sign-in happens separately when you push changes; follow the browser or credential-manager prompt. Never save passwords or access tokens in the repository.

## 4. Make and share changes with your team

The shared repository is the team's online copy. A branch is your own workspace for a change. A pull request asks the team to review your branch before it is added to the shared copy.

For each task, follow these steps:

1. **Get the latest project.** In RStudio's **Git** pane, select **Pull** while on the team's main branch (usually named `main`). If you use PowerShell instead, run `git switch main` and then `git pull` from the repository folder.
2. **Create a branch for your task.** Use a short name that says what you are doing, such as `docs/setup-guide` or `python/validate-data`. In RStudio, use the Git branch menu to create and switch to a new branch. In PowerShell, run `git switch -c branch-name`, replacing `branch-name` with your chosen name.
3. **Make your changes and check them.** Save your files and run any relevant checks. Do not work directly on `main`.
4. **Review what you are about to share.** In RStudio's **Git** pane, review the changed-file list. Stage only the files you intended to change. In PowerShell, run `git status` to review the list before staging.
5. **Commit your changes.** A commit is a saved set of changes with a short description. In RStudio, enter a clear message in the **Git** pane and select **Commit**. In PowerShell, stage only the files you intend to include, then commit. Example:

   ```powershell
   git add README.md docs/setup-guide.md
   git commit -m "Clarify project setup instructions"
   ```

6. **Push your branch to GitHub.** In RStudio, select **Push** in the **Git** pane. In PowerShell, run `git push -u origin branch-name`, replacing `branch-name` with your branch name. If Git asks you to sign in, use the approved sign-in prompt.
7. **Ask for review.** On GitHub, open the repository. GitHub will usually show a notice for your recently pushed branch; select **Compare & pull request**. Otherwise, select **Pull requests > New pull request**, choose your branch as the source and `main` (or the team's default branch) as the destination, then create the pull request. Explain what changed, mention the checks you ran, and request a teammate review.
8. **After the team merges your pull request,** switch back to `main` and pull again before beginning your next task. This brings the reviewed changes onto your computer.

Before committing, do not include passwords, access tokens, your `.venv` folder, local R package folders, or generated data/results. Do not add the raw CSV unless the team's data-sharing rules say it is allowed. If unsure, stop and ask the project lead before pushing.

## 5. Set up Python

Do this from PowerShell in the project root (the folder containing `requirements.txt`). If you used RStudio to clone the repository, open the **Terminal** tab in RStudio or open PowerShell and change to that same folder.

Create a separate Python environment for this project and install its dependencies:

```powershell
py -3.11 -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

If Windows blocks the activation command, use this workaround in the same PowerShell window, then try activating again:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\.venv\Scripts\Activate.ps1
```

To check the installation, run:

```powershell
python --version
python -m pip check
python -c "import pandas, sklearn, stepmix, pymc, arviz; print('Python packages are ready')"
```

The project requirements are not pinned to exact package versions, so different computers may install slightly different versions. Keep a record of installed versions for each analysis run. Do not copy `.venv` to another computer; each person should create their own environment with the commands above.

## 6. Set up R and check the data

### In RStudio

1. Open the project folder in RStudio. If you cloned using the RStudio instructions, it should already be open. Otherwise, use **File > New Project > Existing Directory** and select the folder containing `README.md`.
2. In the **Console** pane, check that RStudio is using the project folder and can see the data file:

   ```r
   getwd()
   file.exists("data/BankMarketing.csv")
   ```

   The second command should print `TRUE`. If it prints `FALSE`, open the correct project folder or ask the project lead where the approved data file should be placed.
3. In the Console, paste and run this data check:

   ```r
   d <- read.csv("data/BankMarketing.csv", sep = ";", stringsAsFactors = FALSE)
   stopifnot(nrow(d) == 41188L, ncol(d) == 21L)
   stopifnot(all(c("y", "duration", "pdays") %in% names(d)))
   stopifnot(all(d$y %in% c("yes", "no")))
   dim(d)
   table(d$y)
   sum(is.na(d))
   sum(d$pdays == 999, na.rm = TRUE)
   ```

   If the commands finish without an error, the file passed these basic checks. The results show its dimensions, outcome counts, missing-value count, and number of special `pdays` values.

### In PowerShell instead

From the repository root, the same basic check can be run with R's command-line program:

```powershell
Rscript -e 'd <- read.csv("data/BankMarketing.csv", sep=";", stringsAsFactors=FALSE); stopifnot(nrow(d) == 41188L, ncol(d) == 21L, all(c("y", "duration", "pdays") %in% names(d)), all(d$y %in% c("yes", "no"))); print(dim(d)); print(table(d$y)); print(sum(is.na(d))); print(sum(d$pdays == 999, na.rm=TRUE))'
```

These checks use base R, which comes with R; they do not install extra R packages and do not run the analysis.

## 7. R packages and reproducibility

R packages are separate from Python packages. The planned R analysis may need packages such as `dplyr`, `ggplot2`, and `poLCA`, but install packages only when the relevant R scripts are ready to use them. Bayesian packages such as `brms` may also need extra compiler software.

An `renv.lock` file records the R package versions used by a project, in a similar way that a recipe records the ingredients for a meal. This repository does not currently have that lockfile or the R analysis scripts, so `renv::restore()` is not ready to use here. When the R code and agreed package list are available, the project lead should set up `renv`, save the lockfile, and commit it to GitHub. After that, team members can restore the same R packages from the lockfile with `renv::restore()`.

## 8. What can I run now?

The data checks above only confirm that the CSV can be read. This workspace currently has no analysis scripts in `source/` and no R script folder, so segmentation, modelling, and report commands are not available yet. Do not report the pipeline as completed based on setup checks alone.

Before analysis begins, check the [main README](../README.md) for feature and modelling rules. In particular, `y` is the outcome and `duration` is recorded after the call; neither should be used to create segments. Record the software versions, data source, validation results, and any random seeds used in each language's run notes. Review the [analysis decision log](decision-log.md) before changing an agreed project decision.
