#!/usr/bin/env python3

import fnmatch
import os
import sys
from pathlib import Path

import yaml
from rich.console import Console
from rich.panel import Panel
from rich.syntax import Syntax

console = Console()
THEME = {
    "syntax": "monokai",
    "panel": {"border": "bright_green"},
    "messages": {"not_found": "bright_red", "error": "bright_yellow"},
    "highlight": {"variable": "bold cyan", "file": "bold green"},
}


def print_banner():
    if len(sys.argv) == 1:
        console.print(
            f"[bold bright_green]Ansible Varfinder[/bold bright_green]\n[dim]Find ansible variables easily[/dim]\n"
        )


def get_root() -> Path:

    for p in [Path(__file__).resolve().parent, *Path(__file__).resolve().parents]:
        if any((p / d).is_dir() for d in ("roles", "inventory")):
            return p
    return Path.cwd()


def get_var_name() -> str:
    var_name = (
        sys.argv[1]
        if len(sys.argv) > 1
        else console.input("[cyan]Enter variable name: [/cyan]").strip()
    )
    if not var_name:
        console.print(
            f"[{THEME['messages']['error']}]Error: Empty variable name.[/{THEME['messages']['error']}]"
        )
        sys.exit(1)
    return var_name


def build_line_map(lines: list[str]) -> dict[str, int]:
    stack, line_map = [], {}
    for i, line in enumerate(lines):
        if line.strip() and not line.lstrip().startswith("#"):
            indent = len(line) - len(line.lstrip())
            key = line.lstrip().split(":")[0].strip()
            while stack and stack[-1][1] >= indent:
                stack.pop()
            stack.append((key, indent))
            line_map[".".join(k for k, _ in stack)] = i + 1
    return line_map


def load_yaml(file: Path) -> tuple[list[tuple[dict, dict]], dict]:
    try:
        text = file.read_text(encoding="utf-8")
        docs = list(yaml.safe_load_all(text)) or [{}]
        return [
            (doc, build_line_map(text.splitlines())) for doc in docs
        ], build_line_map(text.splitlines())
    except Exception as e:
        console.print(
            f"[{THEME['messages']['error']}]Failed to load {file}: {e}[/{THEME['messages']['error']}]"
        )
        return [({}, {})], {}


def find_var(obj, pattern: str, prefix="") -> list[tuple[str, any]]:
    results = []

    def match(obj, parts, full_prefix=""):
        if not parts:
            results.append((full_prefix.rstrip("."), obj))
            return
        part, *rest = parts
        if isinstance(obj, dict):
            for k, v in obj.items():
                if fnmatch.fnmatch(str(k), part):
                    match(v, rest, f"{full_prefix}{k}.")
        elif isinstance(obj, list):
            for i, v in enumerate(obj):
                if fnmatch.fnmatch(str(i), part) or part == "*":
                    match(v, rest, f"{full_prefix}{i}.")

    match(obj, pattern.split("."))
    return results


def collect_files() -> dict[str, list[Path]]:

    r, i = Path.cwd() / "roles", Path.cwd() / "inventory"
    return {
        "role defaults": list(r.glob("*/defaults/main.yml")),
        "role vars": list(r.glob("*/vars/main.yml")),
        "inventory all": [i / "all.yml"] if (i / "all.yml").is_file() else [],
        "group vars": (
            list((i / "group_vars").rglob("*.yml"))
            if (i / "group_vars").is_dir()
            else []
        ),
        "host vars": (
            list((i / "host_vars").rglob("*.yml")) if (i / "host_vars").is_dir() else []
        ),
    }


def search_var(sections: dict[str, list[Path]], var: str) -> list[tuple]:
    results = []
    for sec, files in sections.items():
        for f in files:
            docs, line_map = load_yaml(f)
            for doc, _ in docs:
                matches = find_var(doc, var)
                if matches:
                    results.append((sec, f, matches, line_map))
    return results


def print_results(results: list, order: list[str], var: str):
    if not results:
        console.print(
            f"[{THEME['messages']['not_found']}]Variable '{var}' not found.[/{THEME['messages']['not_found']}]"
        )
        return

    final = None
    for section in order:
        for sec, f, matches, line_map in filter(lambda r: r[0] == section, results):
            console.print(
                Panel(
                    f"[bold bright_magenta]{section}[/bold bright_magenta]",
                    border_style=THEME["panel"]["border"],
                    expand=True,
                )
            )
            console.print(
                f"[{THEME['highlight']['file']}]File:[/{THEME['highlight']['file']}] {f.relative_to(Path.cwd())}"
            )
            for k, v in matches:
                line_number = line_map.get(k, "?")
                snippet = yaml.dump({k: v}, sort_keys=False).rstrip("\n")
                console.print(f"  [cyan]Line {line_number}[/cyan]:")
                console.print(
                    Syntax(snippet, "yaml", theme=THEME["syntax"], indent_guides=True)
                )
            final = matches[-1] + (f,)

    if final:

        matched_values = []
        for sec, f, matches, line_map in results:
            for k, v in matches:
                line_number = line_map.get(k, "?")
                snippet = yaml.dump({k: v}, sort_keys=False).rstrip("\n")
                matched_values.append((k, v, f, snippet))

        if matched_values:

            for k, v, f, snippet in matched_values:
                console.print(
                    Panel(
                        Syntax(snippet, "yaml", theme=THEME["syntax"]),
                        title=f"Effective value from {f.relative_to(Path.cwd())} (var: {k})",
                        border_style=THEME["panel"]["border"],
                    )
                )


def main():
    print_banner()
    root = get_root()
    os.chdir(root)
    console.print(f"[bright_magenta]Project root:[/bright_magenta] {root}")
    var = get_var_name()
    console.print(
        f"[bold cyan]Searching for variable [bold yellow]{var}[/bold yellow]...[/bold cyan]"
    )
    results = search_var(collect_files(), var)
    print_results(
        results,
        ["role defaults", "inventory all", "group vars", "host vars", "role vars"],
        var,
    )


if __name__ == "__main__":
    main()
