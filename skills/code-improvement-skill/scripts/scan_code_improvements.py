#!/usr/bin/env python3
"""Scan recent PR files for code-improvement catalog candidates.

The detector is intentionally dependency-free so it can run in local branches
without adding build tooling. It favors high-signal, reviewable candidates over
perfect static analysis.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
from collections import Counter
from dataclasses import dataclass, asdict
from pathlib import Path
from typing import Iterable


DEFAULT_MAX_FILE_LINES = 1000
DEFAULT_MAX_METHOD_LINES = 30
DEFAULT_MAX_PARAMS = 8
DEFAULT_MAX_INDENT_LEVELS = 4
DEFAULT_MAX_DOTS_PER_LINE = 3
DEFAULT_MAX_NESTING_DEPTH = 5
DEFAULT_CLONE_LINES = 10
DEFAULT_MAX_INSTANCE_VARS = 15

GENERIC_VERBS = {"process", "handle", "manage", "doStuff"}
SOURCE_SUFFIXES = {".kt", ".kts", ".java", ".ts", ".tsx", ".js", ".jsx"}
ALLOWED_NUMERIC_LITERALS = {"0", "1", "-1"}
CONSTRUCTOR_WORK_TOKENS = ("for (", "while (", "runBlocking", ".block(", ".subscribe(", ".execute(")
SUMMARY_ORDER = (
    "max-file-lines",
    "max-method-lines",
    "max-params",
    "max-nesting-depth",
    "one-indent-level",
    "one-dot-per-line",
    "max-instance-vars",
    "no-constructor-work",
    "no-static-mutable-state",
    "no-null-returns",
    "no-generic-verbs",
    "no-magic-numbers",
    "no-clones",
)


@dataclass(frozen=True)
class Violation:
    invariant: str
    file: str
    line: int
    detail: str

    @property
    def rank_key(self) -> tuple[int, str, int]:
        try:
            invariant_rank = SUMMARY_ORDER.index(self.invariant)
        except ValueError:
            invariant_rank = len(SUMMARY_ORDER)
        return invariant_rank, self.file, self.line


def run_git(args: list[str]) -> list[str]:
    result = subprocess.run(
        ["git", *args],
        check=True,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    return [line for line in result.stdout.splitlines() if line.strip()]


def recent_pr_commits(count: int) -> list[str]:
    commits = run_git(["log", "--first-parent", "--format=%H%x09%s", "origin/master", f"-{count * 4}"])
    pr_commits = [line.split("\t", 1)[0] for line in commits if "pull request #" in line]
    return pr_commits[:count]


def files_from_commits(commits: Iterable[str]) -> list[Path]:
    files: set[Path] = set()
    for commit in commits:
        changed = run_git(["diff-tree", "--no-commit-id", "--name-only", "-r", commit])
        files.update(Path(path) for path in changed)
    return sorted(path for path in files if path.suffix in SOURCE_SUFFIXES and path.exists())


def files_changed_from(ref: str) -> list[Path]:
    changed = run_git(["diff", "--name-only", f"{ref}..HEAD"])
    return sorted(Path(path) for path in changed if Path(path).suffix in SOURCE_SUFFIXES and Path(path).exists())


def strip_comment(line: str) -> str:
    return line.split("//", 1)[0]


def strip_strings(line: str) -> str:
    return re.sub(r'"(?:\\.|[^"\\])*"', '""', line)


def code_without_strings(line: str) -> str:
    return strip_strings(strip_comment(line))


def is_code_line(line: str) -> bool:
    stripped = line.strip()
    return bool(stripped) and not stripped.startswith(("//", "*", "/*", "package ", "import "))


def dot_count(line: str) -> int:
    return code_without_strings(line).count(".")


def is_dot_scan_candidate(line: str) -> bool:
    stripped = code_without_strings(line).strip()
    return not stripped.startswith(".")


def function_name(line: str) -> str | None:
    match = re.search(r"\bfun\s+([A-Za-z_][A-Za-z0-9_]*)\s*\(", line)
    return match.group(1) if match else None


def class_name(line: str) -> str | None:
    match = re.search(r"\b(?:data\s+)?class\s+([A-Za-z_][A-Za-z0-9_]*)\b", line)
    return match.group(1) if match else None


def indentation(line: str) -> int:
    return (len(line) - len(line.lstrip(" "))) // 4


def brace_delta(line: str) -> int:
    code = code_without_strings(line)
    return code.count("{") - code.count("}")


def primary_constructor_property_count(signature: str) -> int:
    if "(" not in signature or ")" not in signature:
        return 0
    inside = signature[signature.find("(") + 1 : signature.rfind(")")]
    return len(re.findall(r"\b(?:val|var)\s+[A-Za-z_][A-Za-z0-9_]*\s*:", inside))


def parameter_count(signature: str) -> int:
    inside = signature[signature.find("(") + 1 : signature.rfind(")")]
    if not inside.strip():
        return 0
    depth = 0
    params = 1
    for char in inside:
        if char in "(<[":
            depth += 1
        elif char in ")>]":
            depth = max(0, depth - 1)
        elif char == "," and depth == 0:
            params += 1
    return params


def scan_functions(path: Path, lines: list[str]) -> list[Violation]:
    violations: list[Violation] = []
    index = 0
    while index < len(lines):
        line = lines[index]
        name = function_name(line)
        if name is None:
            index += 1
            continue

        start = index
        signature = line.strip()
        while ")" not in signature and index + 1 < len(lines):
            index += 1
            signature += " " + lines[index].strip()

        params = parameter_count(signature) if ")" in signature else 0
        if params > DEFAULT_MAX_PARAMS:
            violations.append(
                Violation("max-params", str(path), start + 1, f"{name} has {params} parameters")
            )
        if name in GENERIC_VERBS:
            violations.append(
                Violation("no-generic-verbs", str(path), start + 1, f"generic function name `{name}`")
            )

        brace_balance = brace_delta(signature)
        body_lines = 1
        max_indent = 0
        max_nesting = max(0, brace_balance)
        cursor = index
        while brace_balance > 0 and cursor + 1 < len(lines):
            cursor += 1
            body_lines += 1
            current = lines[cursor]
            if is_code_line(current):
                max_indent = max(max_indent, indentation(current))
            brace_balance += brace_delta(current)
            max_nesting = max(max_nesting, brace_balance)

        if body_lines > DEFAULT_MAX_METHOD_LINES:
            violations.append(
                Violation("max-method-lines", str(path), start + 1, f"{name} is {body_lines} lines")
            )
        if max_indent > DEFAULT_MAX_INDENT_LEVELS:
            violations.append(
                Violation("one-indent-level", str(path), start + 1, f"{name} reaches indent level {max_indent}")
            )
        if max_nesting > DEFAULT_MAX_NESTING_DEPTH:
            violations.append(
                Violation("max-nesting-depth", str(path), start + 1, f"{name} reaches nesting depth {max_nesting}")
            )
        index = max(cursor + 1, index + 1)
    return violations


def scan_classes(path: Path, lines: list[str]) -> list[Violation]:
    violations: list[Violation] = []
    index = 0
    while index < len(lines):
        line = lines[index]
        name = class_name(line)
        if name is None:
            index += 1
            continue

        start = index
        signature = line.strip()
        while ")" not in signature and "{" not in signature and index + 1 < len(lines):
            index += 1
            signature += " " + lines[index].strip()

        brace_balance = brace_delta(signature)
        cursor = index
        instance_vars = primary_constructor_property_count(signature)
        init_start: int | None = None
        init_balance = 0
        init_has_work = False

        while brace_balance > 0 and cursor + 1 < len(lines):
            cursor += 1
            current = lines[cursor]
            stripped = current.strip()
            class_level_member = indentation(current) == indentation(line) + 1
            if class_level_member and re.search(r"\b(?:private\s+)?(?:val|var)\s+[A-Za-z_][A-Za-z0-9_]*\s*[:=]", stripped):
                instance_vars += 1

            if class_level_member and stripped.startswith("init"):
                init_start = cursor
                init_balance = brace_delta(current)
                init_has_work = False
            elif init_start is not None:
                init_balance += brace_delta(current)
                code = code_without_strings(current)
                if any(token in code for token in CONSTRUCTOR_WORK_TOKENS) or re.search(r"\bif\s*\(", code):
                    init_has_work = True
                if init_balance <= 0:
                    if init_has_work:
                        violations.append(
                            Violation("no-constructor-work", str(path), init_start + 1, f"{name} init block does work")
                        )
                    init_start = None

            brace_balance += brace_delta(current)

        if instance_vars > DEFAULT_MAX_INSTANCE_VARS:
            violations.append(
                Violation("max-instance-vars", str(path), start + 1, f"{name} has {instance_vars} instance variables")
            )
        index = max(cursor + 1, index + 1)
    return violations


def scan_static_mutable_state(path: Path, lines: list[str]) -> list[Violation]:
    violations: list[Violation] = []
    object_depth: int | None = None
    brace_balance = 0
    for number, line in enumerate(lines, start=1):
        code = code_without_strings(line)
        stripped = code.strip()
        if re.search(r"\b(companion object|object\s+[A-Za-z_])\b", stripped):
            object_depth = brace_balance + brace_delta(line)
        if re.search(r"\bvar\s+[A-Za-z_][A-Za-z0-9_]*\s*=", stripped):
            is_top_level = indentation(line) == 0
            is_object_member = object_depth is not None and indentation(line) <= 2
            if is_top_level or is_object_member:
                violations.append(
                    Violation("no-static-mutable-state", str(path), number, "mutable static/global state candidate")
                )
        brace_balance += brace_delta(line)
        if object_depth is not None and brace_balance < object_depth:
            object_depth = None
    return violations


def scan_file(path: Path) -> list[Violation]:
    lines = path.read_text(encoding="utf-8").splitlines()
    violations: list[Violation] = []

    if len(lines) > DEFAULT_MAX_FILE_LINES:
        violations.append(
            Violation("max-file-lines", str(path), 1, f"{len(lines)} lines exceeds {DEFAULT_MAX_FILE_LINES}")
        )

    violations.extend(scan_functions(path, lines))
    violations.extend(scan_classes(path, lines))
    violations.extend(scan_static_mutable_state(path, lines))

    for number, line in enumerate(lines, start=1):
        if not is_code_line(line):
            continue
        dots = dot_count(line)
        if is_dot_scan_candidate(line) and dots > DEFAULT_MAX_DOTS_PER_LINE:
            violations.append(
                Violation("one-dot-per-line", str(path), number, f"{dots} dots on one line")
            )
        code = code_without_strings(line)
        if "return null" in code and "private " not in code:
            violations.append(
                Violation("no-null-returns", str(path), number, "explicit null return")
            )
        for literal in re.findall(r"(?<![A-Za-z0-9_])(-?\d+(?:_\d+)*)(?:[lLfFdD])?(?![A-Za-z0-9_])", code):
            normalized_literal = literal.replace("_", "")
            if normalized_literal not in ALLOWED_NUMERIC_LITERALS and "const val" not in code:
                violations.append(
                    Violation("no-magic-numbers", str(path), number, f"numeric literal `{literal}`")
                )

    clones = Counter(
        "\n".join(strip_comment(line).strip() for line in lines[offset : offset + DEFAULT_CLONE_LINES])
        for offset in range(max(0, len(lines) - DEFAULT_CLONE_LINES + 1))
    )
    for block, seen in clones.items():
        if seen > 1 and block and all(is_code_line(line) for line in block.splitlines()):
            violations.append(
                Violation("no-clones", str(path), 1, f"{seen} repeated {DEFAULT_CLONE_LINES}-line blocks")
            )
            break

    return violations


def print_summary(violations: list[Violation], top: int) -> None:
    by_invariant = Counter(violation.invariant for violation in violations)
    by_file = Counter(violation.file for violation in violations)
    print("\nSummary by invariant")
    for invariant in SUMMARY_ORDER:
        if by_invariant[invariant]:
            print(f"{invariant}: {by_invariant[invariant]}")
    for invariant, count in sorted(by_invariant.items()):
        if invariant not in SUMMARY_ORDER:
            print(f"{invariant}: {count}")

    if top > 0:
        print(f"\nTop {top} files")
        for file, count in by_file.most_common(top):
            print(f"{count}\t{file}")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--recent-pr-count", type=int, default=10)
    parser.add_argument("files", nargs="*")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--summary", action="store_true")
    parser.add_argument("--top", type=int, default=0)
    parser.add_argument("--changed-from")
    args = parser.parse_args()

    if args.files:
        paths = [Path(file) for file in args.files]
    elif args.changed_from:
        paths = files_changed_from(args.changed_from)
    else:
        paths = files_from_commits(recent_pr_commits(args.recent_pr_count))
    existing_paths = [path for path in paths if path.exists()]
    violations = sorted(
        [violation for path in existing_paths for violation in scan_file(path)],
        key=lambda violation: violation.rank_key,
    )

    if args.json:
        print(json.dumps([asdict(violation) for violation in violations], indent=2))
        return

    for violation in violations:
        print(f"{violation.file}:{violation.line}: {violation.invariant}: {violation.detail}")
    if args.summary or args.top:
        print_summary(violations, args.top)


if __name__ == "__main__":
    main()
