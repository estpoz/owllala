#!/usr/bin/env python3
"""Create missing GitHub issues and synchronize feature-based parent relationships.

Behavior:
- Existing issues are located by stable issue ID in the title.
- Existing issue metadata is preserved unchanged.
- Existing issues may only have their parent relationship changed.
- Missing issues are created from issues.yaml, added to the GitHub Project,
  populated with Project V2 fields, and linked to their configured parent.
- Parent relationships are synchronized after all issues have been resolved.
- Obsolete organizational parents can be closed in migration mode.

Requirements:
    python3 -m pip install pyyaml
    gh auth login
    gh auth refresh -s project

Examples:
    python3 create_github_issues.py --dry-run
    python3 create_github_issues.py --migrate-parents --dry-run
    python3 create_github_issues.py --migrate-parents
    python3 create_github_issues.py --sync
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
class ResolvedIssue:
    issue_id: str
    number: int
    title: str
    url: str
    created: bool


@dataclass
class RunSummary:
    created: list[str] = field(default_factory=list)
    existing: list[str] = field(default_factory=list)
    project_added: list[str] = field(default_factory=list)
    parent_moved: list[str] = field(default_factory=list)
    parent_unchanged: list[str] = field(default_factory=list)
    parent_planned: list[str] = field(default_factory=list)
    obsolete_parents_closed: list[str] = field(default_factory=list)
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
    """Normalize names so punctuation, whitespace, and case do not matter."""
    return re.sub(r"[^a-z0-9]+", "", value.lower())


def load_yaml(path: Path) -> dict[str, Any]:
    try:
        import yaml
    except ImportError as exc:
        raise RuntimeError(
            "PyYAML is missing. Install it with: python3 -m pip install pyyaml"
        ) from exc

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
            "project",
            "list",
            "--owner",
            owner,
            "--format",
            "json",
            "--limit",
            "100",
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
            "project",
            "field-list",
            project["number"],
            "--owner",
            project["owner"],
            "--format",
            "json",
            "--limit",
            "100",
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
            "--method",
            "GET",
            "-f",
            "state=all",
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
            "issue",
            "list",
            "-R",
            repo,
            "--state",
            "all",
            "--limit",
            "1000",
            "--search",
            f'"{issue_id}" in:title',
            "--json",
            "number,title,url,state",
        ]
    )

    exact_id = re.compile(
        rf"(?<![A-Za-z0-9]){re.escape(issue_id)}(?![A-Za-z0-9])",
        re.IGNORECASE,
    )
    matches = [
        issue
        for issue in json.loads(result.stdout or "[]")
        if exact_id.search(str(issue.get("title", "")))
    ]

    if len(matches) > 1:
        numbers = ", ".join(f"#{item['number']}" for item in matches)
        raise RuntimeError(
            f"Stable issue ID '{issue_id}' matches multiple issues: {numbers}"
        )

    return matches[0] if matches else None


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
) -> str:
    title = str(issue["title"])
    assignees = resolve_assignees(issue, assignee_aliases)
    milestone = resolve_milestone(issue.get("milestone"), repository_milestones)

    with tempfile.NamedTemporaryFile(
        "w",
        encoding="utf-8",
        delete=False,
    ) as body_file:
        body_file.write(build_issue_body(issue))
        body_path = Path(body_file.name)

    try:
        args = [
            "issue",
            "create",
            "-R",
            repo,
            "--title",
            title,
            "--body-file",
            str(body_path),
        ]
        if assignees:
            args.extend(["--assignee", ",".join(assignees)])
        if milestone:
            args.extend(["--milestone", milestone])

        result = run_gh(args, check=False)
        if result.returncode != 0:
            raise RuntimeError(result.stderr.strip() or "Issue creation failed.")

        issue_url = result.stdout.strip()
        if not issue_url:
            raise RuntimeError("GitHub did not return the created issue URL.")
        return issue_url
    finally:
        body_path.unlink(missing_ok=True)


def issue_number_from_url(issue_url: str) -> int:
    match = re.search(r"/issues/(\d+)/?$", issue_url)
    if not match:
        raise ValueError(f"Could not read issue number from URL: {issue_url}")
    return int(match.group(1))


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
        "project",
        "item-edit",
        "--id",
        item_id,
        "--project-id",
        project["id"],
        "--field-id",
        field_data["id"],
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


def get_current_parent_number(
    repo: str,
    child_number: int,
) -> int | None:
    result = run_gh(
        [
            "api",
            "--method",
            "GET",
            "-H",
            "Accept: application/vnd.github+json",
            "-H",
            "X-GitHub-Api-Version: 2022-11-28",
            f"repos/{repo}/issues/{child_number}/parent",
        ],
        check=False,
    )

    if result.returncode == 0:
        data = json.loads(result.stdout or "{}")
        number = data.get("number")
        return int(number) if number is not None else None

    combined_error = f"{result.stdout}\n{result.stderr}".lower()
    if "404" in combined_error or "not found" in combined_error:
        return None

    raise RuntimeError(
        result.stderr.strip()
        or f"Unable to read the parent of issue #{child_number}."
    )


def set_parent_relationship(
    repo: str,
    child_number: int,
    expected_parent_number: int,
) -> None:
    result = run_gh(
        [
            "issue",
            "edit",
            str(child_number),
            "-R",
            repo,
            "--parent",
            str(expected_parent_number),
        ],
        check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(
            result.stderr.strip()
            or (
                f"Unable to set issue #{expected_parent_number} as the parent "
                f"of issue #{child_number}."
            )
        )


def sync_parent_relationship(
    repo: str,
    child_number: int,
    expected_parent_number: int,
    *,
    dry_run: bool,
) -> str:
    if child_number == expected_parent_number:
        raise ValueError(
            f"Issue #{child_number} cannot be configured as its own parent."
        )

    current_parent_number = get_current_parent_number(repo, child_number)

    if current_parent_number == expected_parent_number:
        return "unchanged"

    if dry_run:
        old_parent = (
            f"#{current_parent_number}" if current_parent_number else "no parent"
        )
        print(
            f"[DRY RUN] Move issue #{child_number}: "
            f"{old_parent} -> #{expected_parent_number}"
        )
        return "planned"

    set_parent_relationship(
        repo,
        child_number,
        expected_parent_number,
    )
    return "moved"


def get_issue_state(repo: str, issue_number: int) -> str:
    result = run_gh(
        [
            "issue",
            "view",
            str(issue_number),
            "-R",
            repo,
            "--json",
            "state",
            "--jq",
            ".state",
        ]
    )
    return result.stdout.strip().upper()


def close_obsolete_parent(
    repo: str,
    issue_number: int,
    *,
    dry_run: bool,
) -> bool:
    state = get_issue_state(repo, issue_number)
    if state == "CLOSED":
        return False

    if dry_run:
        print(f"[DRY RUN] Comment on and close obsolete parent #{issue_number}")
        return True

    comment = (
        "This organizational parent issue has been superseded by the "
        "feature-based issue hierarchy."
    )
    comment_result = run_gh(
        [
            "issue",
            "comment",
            str(issue_number),
            "-R",
            repo,
            "--body",
            comment,
        ],
        check=False,
    )
    if comment_result.returncode != 0:
        raise RuntimeError(
            comment_result.stderr.strip()
            or f"Unable to comment on obsolete parent #{issue_number}."
        )

    close_result = run_gh(
        [
            "issue",
            "close",
            str(issue_number),
            "-R",
            repo,
            "--reason",
            "not planned",
        ],
        check=False,
    )
    if close_result.returncode != 0:
        raise RuntimeError(
            close_result.stderr.strip()
            or f"Unable to close obsolete parent #{issue_number}."
        )

    return True


def validate_parent_keys(
    issues: list[dict[str, Any]],
    static_parent_map: dict[str, int],
) -> None:
    issue_ids = {str(issue["id"]) for issue in issues}

    for issue in issues:
        parent_key = str(issue.get("parent", "")).strip()
        if not parent_key:
            continue
        if parent_key not in issue_ids and parent_key not in static_parent_map:
            raise ValueError(
                f"Issue '{issue['id']}' references undefined parent "
                f"'{parent_key}'."
            )


def print_summary(summary: RunSummary) -> None:
    print("\n=== Automation summary ===")
    print(f"Created:                  {len(summary.created)}")
    print(f"Existing preserved:       {len(summary.existing)}")
    print(f"Added to project:         {len(summary.project_added)}")
    print(f"Parent moved:             {len(summary.parent_moved)}")
    print(f"Parent unchanged:         {len(summary.parent_unchanged)}")
    print(f"Parent changes planned:   {len(summary.parent_planned)}")
    print(f"Obsolete parents closed:  {len(summary.obsolete_parents_closed)}")
    print(f"Warnings:                 {len(summary.warnings)}")
    print(f"Failed:                   {len(summary.failed)}")

    for label, items in (
        ("Created", summary.created),
        ("Existing preserved", summary.existing),
        ("Parent moved", summary.parent_moved),
        ("Parent changes planned", summary.parent_planned),
        ("Obsolete parents closed", summary.obsolete_parents_closed),
        ("Warnings", summary.warnings),
        ("Failed", summary.failed),
    ):
        if items:
            print(f"\n{label}:")
            for item in items:
                print(f"  - {item}")


def main() -> int:
    parser = argparse.ArgumentParser(
        description=(
            "Create missing GitHub issues and synchronize feature-based "
            "parent relationships."
        )
    )
    parser.add_argument(
        "--yaml",
        default=str(DEFAULT_YAML_PATH),
        help="Path to issues.yaml.",
    )

    mode_group = parser.add_mutually_exclusive_group()
    mode_group.add_argument(
        "--sync",
        action="store_true",
        help=(
            "Create missing issues and synchronize parent relationships. "
            "This is the default mode."
        ),
    )
    mode_group.add_argument(
        "--migrate-parents",
        action="store_true",
        help=(
            "Create missing issues, synchronize parent relationships, and "
            "close obsolete organizational parents after a successful run."
        ),
    )

    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show intended changes without modifying GitHub.",
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
        issues = data.get("issues") or []
        if not isinstance(issues, list):
            raise ValueError("'issues' must be a YAML list.")

        assignee_aliases = {
            str(key): str(value)
            for key, value in (data.get("assignees") or {}).items()
        }
        static_parent_map = {
            str(key): int(value)
            for key, value in (data.get("parents") or {}).items()
        }

        validate_parent_keys(issues, static_parent_map)

        project = find_project(repo, project_title)
        fields = get_project_fields(project)
        milestones = get_repository_milestones(repo)
        summary = RunSummary()

        migrate_mode = bool(args.migrate_parents)
        mode_name = "MIGRATE PARENTS" if migrate_mode else "SYNC"

        print(f"Repository: {repo}")
        print(f"Project:    {project_title}")
        print(f"YAML:       {yaml_path}")
        print(
            f"Mode:       {mode_name}"
            f"{' (DRY RUN)' if args.dry_run else ''}\n"
        )

        resolved: dict[str, ResolvedIssue] = {}
        resolved_numbers: dict[str, int] = dict(static_parent_map)

        # Phase 1: find every existing issue and create only missing issues.
        for issue in issues:
            issue_id = str(issue["id"])

            try:
                existing = find_existing_issue(repo, issue_id)
                if existing:
                    resolved_issue = ResolvedIssue(
                        issue_id=issue_id,
                        number=int(existing["number"]),
                        title=str(existing["title"]),
                        url=str(existing["url"]),
                        created=False,
                    )
                    resolved[issue_id] = resolved_issue
                    resolved_numbers[issue_id] = resolved_issue.number
                    summary.existing.append(issue_id)
                    print(
                        f"Preserve existing: {issue_id} "
                        f"(#{resolved_issue.number})"
                    )
                    continue

                if args.dry_run:
                    print(
                        f"[DRY RUN] Create {issue_id}: "
                        f"{issue.get('title', '')}"
                    )
                    # A real number is unavailable in dry-run. Parent actions for
                    # this issue are reported by stable key in Phase 2.
                    continue

                issue_url = create_issue(
                    repo,
                    issue,
                    assignee_aliases,
                    milestones,
                )
                issue_number = issue_number_from_url(issue_url)

                resolved_issue = ResolvedIssue(
                    issue_id=issue_id,
                    number=issue_number,
                    title=str(issue["title"]),
                    url=issue_url,
                    created=True,
                )
                resolved[issue_id] = resolved_issue
                resolved_numbers[issue_id] = issue_number
                summary.created.append(issue_id)

                print(f"Created: {issue_id} (#{issue_number})")
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

            except Exception as exc:
                message = f"{issue_id}: {exc}"
                summary.failed.append(message)
                print(f"Failed: {message}")

        # Do not migrate relationships after issue-resolution failures.
        if summary.failed:
            print(
                "\nParent synchronization skipped because one or more issues "
                "failed to resolve or create."
            )
            print_summary(summary)
            return 1

        # Phase 2: synchronize parent relationships for existing and new issues.
        for issue in issues:
            issue_id = str(issue["id"])
            parent_key = str(issue.get("parent", "")).strip()
            if not parent_key:
                continue

            try:
                if args.dry_run and (
                    issue_id not in resolved_numbers
                    or parent_key not in resolved_numbers
                ):
                    message = f"{issue_id} -> {parent_key}"
                    summary.parent_planned.append(message)
                    print(
                        f"[DRY RUN] Link {issue_id} to parent {parent_key} "
                        "after missing issues are created."
                    )
                    continue

                child_number = resolved_numbers[issue_id]
                parent_number = resolved_numbers[parent_key]

                result = sync_parent_relationship(
                    repo,
                    child_number,
                    parent_number,
                    dry_run=args.dry_run,
                )

                message = (
                    f"{issue_id} (#{child_number}) -> "
                    f"{parent_key} (#{parent_number})"
                )

                if result == "unchanged":
                    summary.parent_unchanged.append(message)
                    print(f"Parent unchanged: {message}")
                elif result == "planned":
                    summary.parent_planned.append(message)
                else:
                    summary.parent_moved.append(message)
                    print(f"Parent synchronized: {message}")

            except Exception as exc:
                message = f"{issue_id}: {exc}"
                summary.failed.append(message)
                print(f"Failed: {message}")

        # Phase 3: close obsolete organizational parents only in migration mode,
        # and only after all parent relationships have synchronized successfully.
        if migrate_mode and not summary.failed:
            migration = data.get("migration") or {}
            action = str(
                migration.get("obsolete_parent_action", "none")
            ).strip().lower()

            if action == "close":
                obsolete_numbers = migration.get(
                    "obsolete_parent_issue_numbers",
                    [],
                )
                for raw_number in obsolete_numbers:
                    issue_number = int(raw_number)
                    try:
                        changed = close_obsolete_parent(
                            repo,
                            issue_number,
                            dry_run=args.dry_run,
                        )
                        if changed:
                            summary.obsolete_parents_closed.append(
                                f"#{issue_number}"
                            )
                            if not args.dry_run:
                                print(
                                    f"Closed obsolete parent: #{issue_number}"
                                )
                        else:
                            print(
                                f"Obsolete parent already closed: "
                                f"#{issue_number}"
                            )
                    except Exception as exc:
                        message = f"Obsolete parent #{issue_number}: {exc}"
                        summary.failed.append(message)
                        print(f"Failed: {message}")
            elif action not in {"none", ""}:
                summary.warnings.append(
                    "Unsupported migration obsolete_parent_action: "
                    f"'{action}'."
                )

        print_summary(summary)
        return 1 if summary.failed else 0

    except Exception as exc:
        print(f"Fatal error: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
