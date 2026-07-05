# GitHub Issue Upload Automation

This folder contains a small automation script for creating GitHub issues from `issues.yaml`.

The script uses the authenticated local GitHub CLI session. It does not store or hardcode private tokens.

## Install Dependencies

Install GitHub CLI if needed:

```bash
brew install gh
```

Install the Python YAML dependency:

```bash
python3 -m pip install pyyaml
```

## Login to GitHub CLI

Authenticate with GitHub:

```bash
gh auth login
```

If you want the script to add issues to GitHub Projects, refresh the Project scope:

```bash
gh auth refresh -s project
```

Check that authentication works:

```bash
gh auth status
```

## Run the Script

From the repository root:

```bash
python3 project-management/create_github_issues.py
```

By default, the script reads:

```text
project-management/issues.yaml
```

If your YAML file is in another location, pass it explicitly:

```bash
python3 project-management/create_github_issues.py --yaml path/to/issues.yaml
```

## What the Script Does

- Checks labels from the `labels` section and uses the labels that already exist in the repository.
- Checks milestones from the `milestones` section and uses the milestones that already exist in the repository.
- Warns and omits a label or milestone if it is referenced in YAML but missing in GitHub.
- Creates issues from the `issues` section.
- Adds title, body, assignee, labels, and milestone.
- Adds each created issue to the existing GitHub Project named by `project_title`.
- Tries to update existing GitHub Project fields from YAML:
  - `status` -> `Status`
  - `start_date` -> `Start Date`
  - `target_date` -> `Target Date`
  - `priority` -> `Priority`
  - `role` -> `Role`
  - `pic_area` -> `PIC Area`
- Skips duplicate issues when the issue ID already appears in an existing issue title.
- Prints existing or missing labels and milestones.
- Prints created issues and skipped duplicate issues.
- Prints a warning if adding an issue to GitHub Projects or updating Project fields fails.

The script does not create labels or milestones. Create or update them in GitHub first, then run the script.

## Verify Issues Were Created

List repository issues:

```bash
gh issue list -R estpoz/CVDApp --state all --limit 100
```

Check labels:

```bash
gh label list -R estpoz/CVDApp
```

Check milestones:

```bash
gh api repos/estpoz/CVDApp/milestones --paginate -f state=all
```

Open the GitHub Project:

```bash
gh project view 1 --owner estpoz --web
```

## Known Limitation

The script attempts to update GitHub Project custom fields with `gh project item-edit`. If GitHub CLI or GraphQL limitations prevent a field update, the script prints a warning and continues. Status, Start Date, Target Date, Priority, Role, and PIC Area are still kept in the issue body so they can be filled manually if needed.
