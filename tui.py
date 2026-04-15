#!/usr/bin/env python3
import curses
import subprocess
from pathlib import Path

SCRIPTS_DIR = Path(__file__).parent / "scripts"

# Helpers


def get_categories() -> list[Path]:
    return sorted([d for d in SCRIPTS_DIR.iterdir() if d.is_dir()])


def get_scripts(category: Path) -> list[Path]:
    return sorted(category.glob("*.sh"))


def format_name(name: str) -> str:
    return name.replace("-", " ").replace("_", " ").title()

def run_script(script: Path):
    curses.endwin()
    print(f"\n▶ Running: {script.name}\n")
    result = subprocess.run(["bash", str(script)])
    print()
    if result.returncode == 0:
        print("Selesai.")
    else:
        print(f"Exit code: {result.returncode}")
    input("\nPress Enter to return to the menu...")

