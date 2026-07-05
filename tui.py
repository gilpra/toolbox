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
        print("✓ Selesai.")
    else:
        print(f"✗ Exit code: {result.returncode}")
    input("\nPress Enter to return to the menu...")


# Core UI


def draw_menu(stdscr, title: str, items: list[str], selected: int, hint: str = ""):
    h, w = stdscr.getmaxyx()

    box_y = 2
    box_x = 4
    box_h = h - 6
    box_w = w - 8

    stdscr.erase()
    stdscr.refresh()

    win = curses.newwin(box_h, box_w, box_y, box_x)
    win.erase()
    win.bkgd(" ", curses.color_pair(1))
    win.border()

    # Judul di tengah garis atas border
    title_str = f"  {title}  "
    title_x = max(1, (box_w - len(title_str)) // 2)
    win.addstr(0, title_x, title_str, curses.color_pair(1) | curses.A_BOLD)

    # Items
    max_visible = box_h - 4
    start = max(0, selected - max_visible + 1)

    for i, item in enumerate(items[start : start + max_visible]):
        actual_i = i + start
        y = i + 2
        item_text = f"  {item}".ljust(box_w - 2)[: box_w - 2]

        if actual_i == selected:
            win.addstr(y, 1, item_text, curses.color_pair(2) | curses.A_BOLD)
        else:
            win.addstr(y, 1, item_text, curses.color_pair(1))

    win.refresh()

    # Hint di bawah box
    if hint:
        hint_x = max(0, (w - len(hint)) // 2)
        stdscr.addstr(box_y + box_h + 1, hint_x, hint, curses.color_pair(4))
        stdscr.refresh()


def navigate(stdscr, title: str, items: list[str], hint: str = "") -> int | None:
    selected = 0
    while True:
        draw_menu(stdscr, title, items, selected, hint)
        key = stdscr.getch()

        if key == curses.KEY_UP:
            selected = (selected - 1) % len(items)
        elif key == curses.KEY_DOWN:
            selected = (selected + 1) % len(items)
        elif key in (curses.KEY_ENTER, 10, 13):
            return selected
        elif key in (ord("q"), 27):
            return None


# Screens


def screen_categories(stdscr):
    while True:
        categories = get_categories()

        if not categories:
            stdscr.clear()
            h, w = stdscr.getmaxyx()
            msg = f"No categories yet in:: {SCRIPTS_DIR}"
            stdscr.addstr(h // 2, max(0, (w - len(msg)) // 2), msg)
            stdscr.addstr(h // 2 + 1, max(0, (w - 22) // 2), "Press [q] to quit.")
            stdscr.refresh()
            if stdscr.getch() in (ord("q"), 27):
                return
            continue

        labels = [format_name(cat.name) for cat in categories]
        hint = "[↑↓] navigate   [Enter] select   [q] quit"
        choice = navigate(stdscr, "Script Runner", labels, hint)

        if choice is None:
            break

        screen_scripts(stdscr, categories[choice])


def screen_scripts(stdscr, category: Path):
    while True:
        scripts = list(get_scripts(category))

        if not scripts:
            stdscr.clear()
            h, w = stdscr.getmaxyx()
            msg = f"There are no scripts in the folder '{category.name}'."
            stdscr.addstr(h // 2, max(0, (w - len(msg)) // 2), msg)
            stdscr.addstr(h // 2 + 1, max(0, (w - 22) // 2), "Press [q] to back.")
            stdscr.refresh()
            if stdscr.getch() in (ord("q"), 27):
                return
            continue

        labels = [format_name(s.stem) for s in scripts]
        hint = "[↑↓] navigate   [Enter] select   [q] quit"
        choice = navigate(stdscr, format_name(category.name), labels, hint)

        if choice is None:
            return

        screen_confirm(stdscr, scripts[choice])


def screen_confirm(stdscr, script: Path):
    items = [f"▶  Running  {format_name(script.stem)}", "✕  Batal"]
    hint = "[↑↓] navigate   [Enter] select   [q] cancel"
    choice = navigate(stdscr, "Confirmation", items, hint)

    if choice == 0:
        run_script(script)


# Entry point


def main(stdscr):
    curses.curs_set(0)
    curses.start_color()
    curses.use_default_colors()

    curses.init_pair(1, curses.COLOR_WHITE, curses.COLOR_BLACK)  # normal
    curses.init_pair(2, curses.COLOR_BLACK, curses.COLOR_WHITE)  # selected
    curses.init_pair(3, curses.COLOR_WHITE, curses.COLOR_BLACK)  # judul
    curses.init_pair(4, curses.COLOR_WHITE, curses.COLOR_BLACK)  # hint

    screen_categories(stdscr)


if __name__ == "__main__":
    curses.wrapper(main)
