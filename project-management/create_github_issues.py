#!/usr/bin/env python3
"""Create GitHub issues from issues.yaml.

The script uses the authenticated local GitHub CLI session. It is safe to
rerun: existing repository labels and milestones are reused, and issues are
skipped when the issue ID already appears in an existing issue title.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_YAML_PATH = SCRIPT_DIR / "issues.yaml"


def run_gh(args: list[str], *, check: bool = True) -> subprocess.CompletedProcess[str]:
    command = ["gh", *args]
    return subprocess.run(
        command,
        check=check,
        text=True,
        capture_output=True,
    )


def normalize(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "", value.lower())


def load_yaml_source(path: Path) -> dict[str, Any]:
    try:
        import yaml
    except ImportError:
        print("Missing dependency: PyYAML. Install it with: python3 -m pip install pyyaml")
        sys.exit(1)

    text = path.read_text(encoding="utf-8")
    data = yaml.safe_load(text)
    if not isinstance(data, dict):
        raise ValueError(f"{path} must contain a YAML mapping at the top level.")
    return data


def choose_yaml_path(cli_path: str | None) -> Path:
    if cli_path:
        return Path(cli_path).expanduser().resolve()
    return DEFAULT_YAML_PATH


def existing_label_names(repo: str) -> set[str]:
    result = run_gh(["label", "list", "-R", repo, "--limit", "1000", "--json", "name"])
    labels = json.loads(result.stdout)
    return {label["name"] for label in labels}


def verify_labels(repo: str, labels: list[dict[str, Any]]) -> set[str]:
    existing = existing_label_names(repo)
    for label in labels:
        name = str(label["name"])

        if name in existing:
            print(f"Using existing label: {name}")
            continue

        print(f"Missing label warning: {name}")
    return existing


def existing_milestone_titles(repo: str) -> set[str]:
    result = run_gh(
        [
            "api",
            f"repos/{repo}/milestones",
            "--paginate",
            "--method",
            "GET",
            "-f",
            "state=all",
        ]
    )
    milestones = json.loads(result.stdout or "[]")
    return {milestone["title"] for milestone in milestones}


def verify_milestones(repo: str, milestones: list[dict[str, Any]]) -> set[str]:
    existing = existing_milestone_titles(repo)
    for milestone in milestones:
        title = str(milestone["title"])

        if title in existing:
            print(f"Using existing milestone: {title}")
            continue

        print(f"Missing milestone warning: {title}")
    return existing


def find_project(repo: str, project_title: str | None) -> dict[str, Any] | None:
    if not project_title:
        return None

    owner = repo.split("/", 1)[0]
    result = run_gh(
        ["project", "list", "--owner", owner, "--format", "json", "--limit", "100"],
        check=False,
    )
    if result.returncode != 0:
        print(f"Project warning: could not list projects for {owner}.")
        if result.stderr.strip():
            print(f"  {result.stderr.strip()}")
        return None

    projects = json.loads(result.stdout or "{}").get("projects", [])
    for project in projects:
        if project.get("title") == project_title:
            print(f"Using project: {project_title}")
            return {
                "id": project["id"],
                "number": str(project["number"]),
                "owner": owner,
                "title": project_title,
            }

    print(f"Project warning: project '{project_title}' was not found for owner '{owner}'.")
    return None


def project_fields(project: dict[str, Any]) -> dict[str, dict[str, Any]]:
    result = run_gh(
        [
            "project",
            "field-list",
            project["number"],
            "--owner",
            project["owner"],
            "--format",
            "json",
            "--limit",
            "100",
        ],
        check=False,
    )
    if result.returncode != 0:
        print("Project field warning: could not list project fields.")
        if result.stderr.strip():
            print(f"  {result.stderr.strip()}")
        return {}

    fields = json.loads(result.stdout or "{}").get("fields", [])
    return {normalize(field["name"]): field for field in fields}


def extract_project_item_id(output: str) -> str | None:
    if not output.strip():
        return None

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


def find_project_item_id(project: dict[str, Any], issue_url: str) -> str | None:
    for _ in range(3):
        result = run_gh(
            [
                "project",
                "item-list",
                project["number"],
                "--owner",
                project["owner"],
                "--format",
                "json",
                "--limit",
                "1000",
            ],
            check=False,
        )
        if result.returncode == 0:
            items = json.loads(result.stdout or "{}").get("items", [])
            for item in items:
                content = item.get("content") or {}
                if content.get("url") == issue_url:
                    return item.get("id")
        time.sleep(1)
    return None


def add_issue_to_project(project: dict[str, Any] | None, issue_url: str, issue_id: str) -> str | None:
    if not project:
        return None

    result = run_gh(
        [
            "project",
            "item-add",
            project["number"],
            "--owner",
            project["owner"],
            "--url",
            issue_url,
            "--format",
            "json",
        ],
        check=False,
    )
    if result.returncode != 0:
        print(
            f"Project-add warning for {issue_id}: issue was created, but it could not be "
            f"added to project '{project['title']}'."
        )
        if result.stderr.strip():
            print(f"  {result.stderr.strip()}")
        return None

    item_id = extract_project_item_id(result.stdout)
    if item_id:
        print(f"Added to project: {issue_id}")
        return item_id

    item_id = find_project_item_id(project, issue_url)
    if item_id:
        print(f"Added to project: {issue_id}")
        return item_id

    print(f"Project-add warning for {issue_id}: issue was added, but project item ID was not found.")
    return None


def single_select_option_id(field: dict[str, Any], value: str) -> str | None:
    wanted = normalize(value)
    aliases = {
        "inprogress": "inprogress",
        "inreview": "inreview",
    }
    wanted = aliases.get(wanted, wanted)

    for option in field.get("options", []):
        if normalize(option["name"]) == wanted:
            return option["id"]
    return None


def edit_project_field(
    project: dict[str, Any],
    item_id: str,
    field: dict[str, Any],
    value: Any,
    issue_id: str,
) -> None:
    if value in (None, ""):
        return

    args = [
        "project",
        "item-edit",
        "--id",
        item_id,
        "--project-id",
        project["id"],
        "--field-id",
        field["id"],
    ]

    field_type = field.get("type", "")
    if field_type == "ProjectV2SingleSelectField":
        option_id = single_select_option_id(field, str(value))
        if not option_id:
            print(
                f"Project field warning for {issue_id}: option '{value}' was not found "
                f"for field '{field['name']}'."
            )
            return
        args.extend(["--single-select-option-id", option_id])
    elif normalize(field.get("name", "")).endswith("date"):
        args.extend(["--date", str(value)])
    else:
        args.extend(["--text", str(value)])

    result = run_gh(args, check=False)
    if result.returncode != 0:
        print(
            f"Project field warning for {issue_id}: could not update field "
            f"'{field['name']}' with value '{value}'."
        )
        if result.stderr.strip():
            print(f"  {result.stderr.strip()}")


def update_project_fields(
    project: dict[str, Any] | None,
    fields: dict[str, dict[str, Any]],
    item_id: str | None,
    issue: dict[str, Any],
) -> None:
    if not project or not item_id:
        return

    field_mapping = {
        "status": "Status",
        "start_date": "Start Date",
        "target_date": "Target Date",
        "priority": "Priority",
        "role": "Role",
        "pic_area": "PIC Area",
    }

    issue_id = str(issue["id"])
    for yaml_key, project_field_name in field_mapping.items():
        field = fields.get(normalize(project_field_name))
        if not field:
            print(
                f"Project field warning for {issue_id}: field '{project_field_name}' "
                "was not found."
            )
            continue
        edit_project_field(project, item_id, field, issue.get(yaml_key), issue_id)


def find_existing_issue(repo: str, issue_id: str) -> dict[str, Any] | None:
    result = run_gh(
        [
            "issue",
            "list",
            "-R",
            repo,
            "--state",
            "all",
            "--limit",
            "100",
            "--search",
            f"{issue_id} in:title",
            "--json",
            "number,title,url",
        ]
    )

    issues = json.loads(result.stdout or "[]")
    for issue in issues:
        if issue_id in issue.get("title", ""):
            return issue

    return None

def rename_existing_issue_if_needed(repo: str, existing_issue: dict[str, Any], new_title: str, issue_id: str) -> None:
    current_title = existing_issue.get("title", "")
    issue_number = existing_issue.get("number")

    if not issue_number:
        print(f"Rename warning for {issue_id}: issue number was not found.")
        return

    if current_title == new_title:
        print(f"Existing issue title already correct: {issue_id}")
        return

    result = run_gh(
        [
            "issue",
            "edit",
            str(issue_number),
            "-R",
            repo,
            "--title",
            new_title,
        ],
        check=False,
    )

    if result.returncode != 0:
        print(f"Rename warning for {issue_id}: could not update issue title.")
        if result.stderr.strip():
            print(f"  {result.stderr.strip()}")
        return

    print(f"Renamed issue: {issue_id}")
    print(f"  From: {current_title}")
    print(f"  To:   {new_title}")


def checklist(items: list[str]) -> str:
    return "\n".join(f"- [ ] {item}" for item in items)


def build_issue_body(issue: dict[str, Any]) -> str:
    criteria = issue.get("acceptance_criteria") or []
    if not isinstance(criteria, list):
        criteria = [str(criteria)]

    return f"""## Issue ID
{issue.get("id", "")}

## Description
{issue.get("description", "").strip()}

## Role
{issue.get("role", "")}

## PIC Area
{issue.get("pic_area", "")}

## Status
{issue.get("status", "")}

## Priority
{issue.get("priority", "")}

## Start Date
{issue.get("start_date", "")}

## Target Date
{issue.get("target_date", "")}

## Acceptance Criteria
{checklist([str(item) for item in criteria])}
"""


def create_issue(
    repo: str,
    project: dict[str, Any] | None,
    fields: dict[str, dict[str, Any]],
    existing_labels: set[str],
    existing_milestones: set[str],
    assignees: dict[str, Any],
    issue: dict[str, Any],
) -> None:
    issue_id = str(issue["id"])
    title = str(issue["title"])
    raw_assignees = issue.get("assignee") or issue.get("assignees")

    if raw_assignees is None:
        issue_assignees = []
    elif isinstance(raw_assignees, list):
        issue_assignees = raw_assignees
    else:
        issue_assignees = [raw_assignees]

    resolved_assignees = []
    for assignee in issue_assignees:
        assignee = str(assignee)
        resolved_assignees.append(str(assignees.get(assignee, assignee)))
    requested_labels = [str(label) for label in (issue.get("labels") or [])]
    labels = [label for label in requested_labels if label in existing_labels]
    for label in requested_labels:
        if label not in existing_labels:
            print(f"Missing label warning for {issue_id}: omitting '{label}'.")
    milestone = issue.get("milestone")
    if milestone and str(milestone) not in existing_milestones:
        print(f"Missing milestone warning for {issue_id}: omitting '{milestone}'.")
        milestone = None
    body = build_issue_body(issue)

    existing_issue = find_existing_issue(repo, issue_id)
    if existing_issue:
        rename_existing_issue_if_needed(repo, existing_issue, title, issue_id)
        print(f"Skipped duplicate issue: {issue_id} — {title}")
        return

    with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as body_file:
        body_file.write(body)
        body_path = body_file.name

    args = [
        "issue",
        "create",
        "-R",
        repo,
        "--title",
        title,
        "--body-file",
        body_path,
    ]

    if resolved_assignees:
        args.extend(["--assignee", ",".join(resolved_assignees)])
    if labels:
        args.extend(["--label", ",".join(str(label) for label in labels)])
    if milestone:
        args.extend(["--milestone", str(milestone)])
    result = run_gh(args, check=False)

    Path(body_path).unlink(missing_ok=True)

    if result.returncode != 0:
        print(f"Failed to create issue: {issue_id} — {title}")
        print(result.stderr.strip())
        return

    created_url = result.stdout.strip()
    print(f"Created issue: {issue_id} — {title}")
    if created_url:
        print(f"  {created_url}")

    item_id = add_issue_to_project(project, created_url, issue_id) if created_url else None
    update_project_fields(project, fields, item_id, issue)


def main() -> int:
    parser = argparse.ArgumentParser(description="Create GitHub issues from issues.yaml.")
    parser.add_argument("--yaml", dest="yaml_path", help="Path to issues.yaml")
    args = parser.parse_args()

    yaml_path = choose_yaml_path(args.yaml_path)
    if not yaml_path.exists():
        print(f"YAML file not found: {yaml_path}")
        return 1

    data = load_yaml_source(yaml_path)
    repo = str(data["repo"])
    project_title = data.get("project_title")

    print(f"Repository: {repo}")
    print(f"YAML: {yaml_path}")
    if project_title:
        print(f"Project title: {project_title}")

    existing_labels = verify_labels(repo, data.get("labels") or [])
    existing_milestones = verify_milestones(repo, data.get("milestones") or [])

    project = find_project(repo, str(project_title) if project_title else None)
    fields = project_fields(project) if project else {}
    assignees = data.get("assignees") or {}
    for issue in data.get("issues") or []:
        create_issue(repo, project, fields, existing_labels, existing_milestones, assignees, issue)

    print("Done.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
