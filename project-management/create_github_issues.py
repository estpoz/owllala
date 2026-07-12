#!/usr/bin/env python3
"""Create only missing GitHub issues from issues.yaml.

This script is intentionally incremental:
- Existing issues are detected by stable issue ID and skipped unchanged.
- Existing Project items, titles, bodies, assignees, milestones, and fields
  are never modified.
- Only newly created issues are added to the GitHub Project, populated with
  Project V2 fields, and linked to their configured parent issue.
- Repository labels are not used. Role and PIC Area are GitHub Project fields.

Requirements:
    python3 -m pip install pyyaml
    gh auth login
    gh auth refresh -s project
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
import time
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_YAML_PATH = SCRIPT_DIR / "issues.yaml"


@dataclass
class RunSummary:
    created: list[str] = field(default_factory=list)
    skipped: list[str] = field(default_factory=list)
    project_added: list[str] = field(default_factory=list)
    parent_linked: list[str] = field(default_factory=list)
    warnings: list[str] = field(default_factory=list)
    failed: list[str] = field(default_factory=list)


def run_gh(
    args: list[str],
    *,
    check: bool = True,
) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        ["gh", *args],
        text=True,
        capture_output=True,
        check=False,
    )
    if check and result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or "GitHub CLI command failed.")
    return result


def normalize(value: str) -> str:
    """Normalize names so hyphens, dashes, spaces, and case do not matter."""
    return re.sub(r"[^a-z0-9]+", "", value.lower())


def load_yaml(path: Path) -> dict[str, Any]:
    try:
        import yaml
    except ImportError:
        raise RuntimeError(
            "PyYAML is missing. Install it with: python3 -m pip install pyyaml"
        )

    data = yaml.safe_load(path.read_text(encoding="utf-8"))
    if not isinstance(data, dict):
        raise ValueError("issues.yaml must contain a YAML mapping.")
    return data


def verify_authentication() -> None:
    result = run_gh(["auth", "status"], check=False)
    if result.returncode != 0:
        raise RuntimeError(
            "GitHub CLI is not authenticated. Run 'gh auth login', then "
            "'gh auth refresh -s project'."
        )


def find_project(repo: str, title: str) -> dict[str, Any]:
    owner = repo.split("/", 1)[0]
    result = run_gh(
        [
            "project", "list",
            "--owner", owner,
            "--format", "json",
            "--limit", "100",
        ],
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(
            result.stderr.strip()
            or "Unable to list projects. Run: gh auth refresh -s project"
        )

    for project in json.loads(result.stdout or "{}").get("projects", []):
        if project.get("title") == title:
            return {
                "id": project["id"],
                "number": str(project["number"]),
                "owner": owner,
                "title": title,
            }

    raise RuntimeError(f"Project '{title}' was not found for owner '{owner}'.")


def get_project_fields(project: dict[str, Any]) -> dict[str, dict[str, Any]]:
    result = run_gh(
        [
            "project", "field-list",
            project["number"],
            "--owner", project["owner"],
            "--format", "json",
            "--limit", "100",
        ]
    )
    fields = json.loads(result.stdout or "{}").get("fields", [])
    return {normalize(field["name"]): field for field in fields}


def get_repository_milestones(repo: str) -> dict[str, str]:
    result = run_gh(
        [
            "api",
            f"repos/{repo}/milestones",
            "--paginate",
            "--method", "GET",
            "-f", "state=all",
        ]
    )
    milestones = json.loads(result.stdout or "[]")
    return {normalize(item["title"]): item["title"] for item in milestones}


def resolve_milestone(
    requested: str | None,
    milestones: dict[str, str],
) -> str | None:
    if not requested:
        return None

    actual = milestones.get(normalize(requested))
    if actual:
        return actual

    available = ", ".join(sorted(milestones.values()))
    raise ValueError(
        f"Milestone '{requested}' was not found. Available milestones: {available}"
    )


def find_existing_issue(repo: str, issue_id: str) -> dict[str, Any] | None:
    result = run_gh(
        [
            "issue", "list",
            "-R", repo,
            "--state", "all",
            "--limit", "1000",
            "--search", f'"{issue_id}" in:title',
            "--json", "number,title,url",
        ]
    )

    exact_id = re.compile(
        rf"(?<![A-Za-z0-9]){re.escape(issue_id)}(?![A-Za-z0-9])",
        re.IGNORECASE,
    )
    for issue in json.loads(result.stdout or "[]"):
        if exact_id.search(str(issue.get("title", ""))):
            return issue
    return None


def resolve_assignees(
    issue: dict[str, Any],
    aliases: dict[str, str],
) -> list[str]:
    raw = issue.get("assignee") or issue.get("assignees")
    if raw is None:
        return []

    values = raw if isinstance(raw, list) else [raw]
    return [str(aliases.get(str(value), value)) for value in values]


def build_issue_body(issue: dict[str, Any]) -> str:
    criteria = issue.get("acceptance_criteria") or []
    if not isinstance(criteria, list):
        criteria = [str(criteria)]

    checklist = "\n".join(f"- [ ] {item}" for item in criteria)
    return f"""## Issue ID
{issue.get("id", "")}

## Description
{str(issue.get("description", "")).strip()}

## Role
{issue.get("role", "")}

## PIC Area
{issue.get("pic_area", "")}

## Priority
{issue.get("priority", "")}

## Start Date
{issue.get("start_date", "")}

## Target Date
{issue.get("target_date", "")}

## Acceptance Criteria
{checklist}
"""


def create_issue(
    repo: str,
    issue: dict[str, Any],
    assignee_aliases: dict[str, str],
    repository_milestones: dict[str, str],
    *,
    dry_run: bool,
) -> str | None:
    issue_id = str(issue["id"])
    title = str(issue["title"])
    assignees = resolve_assignees(issue, assignee_aliases)
    milestone = resolve_milestone(issue.get("milestone"), repository_milestones)

    if dry_run:
        print(f"[DRY RUN] Create {issue_id}: {title}")
        return None

    with tempfile.NamedTemporaryFile(
        "w",
        encoding="utf-8",
        delete=False,
    ) as body_file:
        body_file.write(build_issue_body(issue))
        body_path = Path(body_file.name)

    try:
        args = [
            "issue", "create",
            "-R", repo,
            "--title", title,
            "--body-file", str(body_path),
        ]
        if assignees:
            args.extend(["--assignee", ",".join(assignees)])
        if milestone:
            args.extend(["--milestone", milestone])

        result = run_gh(args, check=False)
        if result.returncode != 0:
            raise RuntimeError(result.stderr.strip() or "Issue creation failed.")
        return result.stdout.strip()
    finally:
        body_path.unlink(missing_ok=True)


def extract_project_item_id(output: str) -> str | None:
    try:
        data = json.loads(output)
    except json.JSONDecodeError:
        return None

    if isinstance(data, dict):
        if isinstance(data.get("id"), str):
            return data["id"]
        item = data.get("item")
        if isinstance(item, dict) and isinstance(item.get("id"), str):
            return item["id"]
    return None


def find_project_item_id(
    project: dict[str, Any],
    issue_url: str,
) -> str | None:
    for _ in range(4):
        result = run_gh(
            [
                "project", "item-list",
                project["number"],
                "--owner", project["owner"],
                "--format", "json",
                "--limit", "1000",
            ],
            check=False,
        )
        if result.returncode == 0:
            for item in json.loads(result.stdout or "{}").get("items", []):
                content = item.get("content") or {}
                if content.get("url") == issue_url:
                    return item.get("id")
        time.sleep(1)
    return None


def add_to_project(
    project: dict[str, Any],
    issue_url: str,
) -> str:
    result = run_gh(
        [
            "project", "item-add",
            project["number"],
            "--owner", project["owner"],
            "--url", issue_url,
            "--format", "json",
        ],
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(
            result.stderr.strip() or "Unable to add issue to project."
        )

    item_id = extract_project_item_id(result.stdout)
    if item_id:
        return item_id

    item_id = find_project_item_id(project, issue_url)
    if item_id:
        return item_id

    raise RuntimeError(
        "The issue was added to the project, but its Project item ID was not found."
    )


def find_single_select_option(
    field_data: dict[str, Any],
    requested: str,
) -> str:
    requested_normalized = normalize(requested)
    for option in field_data.get("options", []):
        if normalize(option["name"]) == requested_normalized:
            return option["id"]

    options = ", ".join(
        str(option["name"]) for option in field_data.get("options", [])
    )
    raise ValueError(
        f"Option '{requested}' was not found for Project field "
        f"'{field_data['name']}'. Available options: {options}"
    )


def set_project_field(
    project: dict[str, Any],
    item_id: str,
    field_data: dict[str, Any],
    value: Any,
) -> None:
    if value in (None, ""):
        return

    args = [
        "project", "item-edit",
        "--id", item_id,
        "--project-id", project["id"],
        "--field-id", field_data["id"],
    ]

    field_type = field_data.get("type", "")
    if field_type == "ProjectV2SingleSelectField":
        option_id = find_single_select_option(field_data, str(value))
        args.extend(["--single-select-option-id", option_id])
    elif normalize(field_data.get("name", "")).endswith("date"):
        args.extend(["--date", str(value)])
    else:
        args.extend(["--text", str(value)])

    result = run_gh(args, check=False)
    if result.returncode != 0:
        raise RuntimeError(
            result.stderr.strip()
            or f"Unable to update Project field '{field_data['name']}'."
        )


def populate_project_fields(
    project: dict[str, Any],
    fields: dict[str, dict[str, Any]],
    item_id: str,
    issue: dict[str, Any],
) -> list[str]:
    mapping = {
        "status": "Status",
        "start_date": "Start Date",
        "target_date": "Target Date",
        "priority": "Priority",
        "role": "Role",
        "pic_area": "PIC Area",
    }
    warnings: list[str] = []

    for yaml_key, project_field_name in mapping.items():
        value = issue.get(yaml_key)
        if value in (None, ""):
            continue

        field_data = fields.get(normalize(project_field_name))
        if not field_data:
            warnings.append(
                f"Project field '{project_field_name}' was not found."
            )
            continue

        try:
            set_project_field(project, item_id, field_data, value)
        except (RuntimeError, ValueError) as exc:
            warnings.append(str(exc))

    return warnings


def issue_number_from_url(issue_url: str) -> int:
    match = re.search(r"/issues/(\d+)$", issue_url)
    if not match:
        raise ValueError(f"Could not read issue number from URL: {issue_url}")
    return int(match.group(1))


def repository_issue_database_id(repo: str, issue_number: int) -> int:
    result = run_gh(
        ["api", f"repos/{repo}/issues/{issue_number}", "--jq", ".id"]
    )
    return int(result.stdout.strip())


def link_to_parent(
    repo: str,
    parent_number: int,
    child_number: int,
) -> None:
    child_database_id = repository_issue_database_id(repo, child_number)
    result = run_gh(
        [
            "api",
            "--method", "POST",
            "-H", "Accept: application/vnd.github+json",
            "-H", "X-GitHub-Api-Version: 2022-11-28",
            f"repos/{repo}/issues/{parent_number}/sub_issues",
            "-F", f"sub_issue_id={child_database_id}",
        ],
        check=False,
    )
    if result.returncode == 0:
        return

    error = result.stderr.strip() or "Unable to create sub-issue relationship."
    if "already" in error.lower():
        return
    raise RuntimeError(error)


def print_summary(summary: RunSummary) -> None:
    print("\n=== Automation summary ===")
    print(f"Created:          {len(summary.created)}")
    print(f"Skipped existing: {len(summary.skipped)}")
    print(f"Added to project: {len(summary.project_added)}")
    print(f"Linked to parent: {len(summary.parent_linked)}")
    print(f"Warnings:         {len(summary.warnings)}")
    print(f"Failed:           {len(summary.failed)}")

    for label, items in (
        ("Created", summary.created),
        ("Skipped existing", summary.skipped),
        ("Warnings", summary.warnings),
        ("Failed", summary.failed),
    ):
        if items:
            print(f"\n{label}:")
            for item in items:
                print(f"  - {item}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Create missing GitHub issues and configure new Project items."
    )
    parser.add_argument(
        "--yaml",
        default=str(DEFAULT_YAML_PATH),
        help="Path to issues.yaml.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show missing issues without creating them.",
    )
    args = parser.parse_args()

    yaml_path = Path(args.yaml).expanduser().resolve()
    if not yaml_path.exists():
        print(f"YAML file not found: {yaml_path}")
        return 1

    try:
        verify_authentication()
        data = load_yaml(yaml_path)

        repo = str(data["repo"])
        project_title = str(data["project_title"])
        assignee_aliases = {
            str(key): str(value)
            for key, value in (data.get("assignees") or {}).items()
        }
        parent_map = data.get("parents") or {}

        project = find_project(repo, project_title)
        fields = get_project_fields(project)
        milestones = get_repository_milestones(repo)
        summary = RunSummary()

        print(f"Repository: {repo}")
        print(f"Project:    {project_title}")
        print(f"YAML:       {yaml_path}")
        print(f"Mode:       {'DRY RUN' if args.dry_run else 'CREATE NEW ONLY'}\n")

        for issue in data.get("issues") or []:
            issue_id = str(issue["id"])

            existing = find_existing_issue(repo, issue_id)
            if existing:
                print(f"Skip existing: {issue_id} — {existing['title']}")
                summary.skipped.append(issue_id)
                continue

            try:
                issue_url = create_issue(
                    repo,
                    issue,
                    assignee_aliases,
                    milestones,
                    dry_run=args.dry_run,
                )
                if args.dry_run:
                    continue
                if not issue_url:
                    raise RuntimeError("GitHub did not return the new issue URL.")

                summary.created.append(issue_id)
                print(f"Created: {issue_id}")
                print(f"  {issue_url}")

                item_id = add_to_project(project, issue_url)
                summary.project_added.append(issue_id)
                print(f"Added to project: {issue_id}")

                for warning in populate_project_fields(
                    project,
                    fields,
                    item_id,
                    issue,
                ):
                    message = f"{issue_id}: {warning}"
                    summary.warnings.append(message)
                    print(f"Warning: {message}")

                parent_key = str(issue.get("parent", "")).strip()
                if parent_key:
                    parent_number = parent_map.get(parent_key)
                    if not parent_number:
                        raise ValueError(
                            f"Parent mapping '{parent_key}' is not defined."
                        )
                    child_number = issue_number_from_url(issue_url)
                    link_to_parent(repo, int(parent_number), child_number)
                    summary.parent_linked.append(issue_id)
                    print(f"Linked to parent #{parent_number}: {issue_id}")

            except Exception as exc:
                message = f"{issue_id}: {exc}"
                summary.failed.append(message)
                print(f"Failed: {message}")

        print_summary(summary)
        return 1 if summary.failed else 0

    except Exception as exc:
        print(f"Fatal error: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
