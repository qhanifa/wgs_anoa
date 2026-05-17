#!/usr/bin/env python3
"""
Genomic Analysis Logbook
------------------------
CLI tool to log dry lab genomic analysis runs.
Everything is stored in one file: genomic_logbook.json

  { "entries": [...], "todos": [...] }

Usage:
    python genomic_logbook.py add                        # Quick entry (6 fields)
    python genomic_logbook.py add --full                 # Detailed entry (all fields)
    python genomic_logbook.py list                       # List log entries
    python genomic_logbook.py view <id>                  # View full entry
    python genomic_logbook.py update <id> [options]      # Update entry fields
    python genomic_logbook.py search <keyword>           # Search entries
    python genomic_logbook.py export                     # Export entries to CSV

    python genomic_logbook.py todo add                   # Add a to-do item
    python genomic_logbook.py todo list                  # List to-do items
    python genomic_logbook.py todo done <id>             # Mark to-do as done
    python genomic_logbook.py todo remove <id>           # Delete a to-do

    python genomic_logbook.py migrate                    # Merge old separate JSON files into one
"""

import json
import csv
import argparse
import os
import sys
from datetime import datetime
from pathlib import Path

LOGBOOK_FILE = Path("genomic_logbook.json")

# ANSI colors (disabled if not a tty)
USE_COLOR = sys.stdout.isatty()

def c(text, code):
    return f"\033[{code}m{text}\033[0m" if USE_COLOR else text

BOLD   = lambda t: c(t, "1")
GREEN  = lambda t: c(t, "32")
CYAN   = lambda t: c(t, "36")
YELLOW = lambda t: c(t, "33")
RED    = lambda t: c(t, "31")
DIM    = lambda t: c(t, "2")

# ── Storage ───────────────────────────────────────────────────────────────────

def load_data():
    """Load the unified logbook file. Returns (entries, todos)."""
    if not LOGBOOK_FILE.exists():
        return [], []
    with open(LOGBOOK_FILE) as f:
        data = json.load(f)
    # Unified format: {"entries": [...], "todos": [...]}
    if isinstance(data, dict):
        return data.get("entries", []), data.get("todos", [])
    # Legacy format: bare list of entries (no todos yet)
    return data, []

def save_data(entries, todos):
    with open(LOGBOOK_FILE, "w") as f:
        json.dump({"entries": entries, "todos": todos}, f, indent=2)

def next_id(items):
    return max((i["id"] for i in items), default=0) + 1

# ── Prompt helpers ────────────────────────────────────────────────────────────

def prompt(label, default=None, required=False):
    suffix = f" [{default}]" if default else ""
    suffix += " *" if required else ""
    while True:
        val = input(f"  {label}{suffix}: ").strip()
        if not val and default is not None:
            return default
        if not val and required:
            print(RED("  This field is required."))
            continue
        return val or ""

def prompt_multiline(label):
    print(f"  {label} (blank line to finish):")
    lines = []
    while True:
        line = input("    ")
        if line == "":
            break
        lines.append(line)
    return "\n".join(lines)

def prompt_list(label, hint="comma-separated"):
    raw = input(f"  {label} ({hint}): ").strip()
    return [x.strip() for x in raw.split(",") if x.strip()]

def choose(label, options):
    print(f"  {label}")
    for i, opt in enumerate(options, 1):
        print(f"    {DIM(str(i))}. {opt}")
    while True:
        val = input("  Choice: ").strip()
        if val.isdigit() and 1 <= int(val) <= len(options):
            return options[int(val) - 1]
        print(RED("  Invalid choice."))

# ── Log commands ──────────────────────────────────────────────────────────────

def cmd_add(args):
    entries, todos = load_data()
    entry_id = next_id(entries)
    now = datetime.now().isoformat(timespec="seconds")

    if args.full:
        print(BOLD(f"\n-- New Entry #{entry_id} (detailed) --"))
    else:
        print(BOLD(f"\n-- New Entry #{entry_id} --"))
        print(DIM("  Quick mode - only essential fields. Use --full for all fields.\n"))

    entry = {
        "id":         entry_id,
        "timestamp":  now,
        "date":       now[:10],
        "analyst":    os.environ.get("USER", ""),
        "title":      prompt("Title / short description", required=True),
        "tool":       prompt("Tool / pipeline (e.g. BWA-MEM2, GATK, DESeq2)", required=True),
        "output_dir": prompt("Output directory"),
        "status":     choose("Status", ["completed", "failed", "running", "pending"]),
        "notes":      prompt("Notes / results (one line)"),
        "tags":       prompt_list("Tags (e.g. QC, variant-calling, RNA-seq)"),
    }

    if args.full:
        print(DIM("\n  -- Extra details --"))
        date_input = prompt("Date (YYYY-MM-DD, leave blank for today)", default=now[:10])
        try:
            datetime.strptime(date_input, "%Y-%m-%d")
            entry["date"] = date_input
            entry["timestamp"] = date_input + now[10:]
        except ValueError:
            print(YELLOW("  Invalid date format, using today."))

        entry["analyst"]      = prompt("Analyst name", default=entry["analyst"])
        entry["project"]      = prompt("Project / cohort name")
        entry["sample_ids"]   = prompt_list("Sample IDs")
        entry["organism"]     = prompt("Organism", default="Homo sapiens")
        entry["tool_version"] = prompt("Tool version")
        entry["script"]       = prompt("Script or workflow file path")
        entry["command"]      = prompt_multiline("Command(s) or key steps")
        entry["job_id"]       = prompt("SLURM/PBS job ID")
        entry["cluster"]      = prompt("Cluster / partition")
        entry["cpus"]         = prompt("CPUs requested")
        entry["mem"]          = prompt("Memory requested (e.g. 64G)")
        entry["walltime"]     = prompt("Wall time requested")
        entry["input_files"]  = prompt_multiline("Input file paths")
        entry["ref_genome"]   = prompt("Reference genome (e.g. GRCh38)")
        entry["results"]      = prompt_multiline("Key results / observations")

    entries.append(entry)
    save_data(entries, todos)
    print(GREEN(f"\n✓ Entry #{entry_id} saved to {LOGBOOK_FILE}\n"))


def cmd_update(args):
    entries, todos = load_data()
    matches = [e for e in entries if e["id"] == args.id]
    if not matches:
        print(RED(f"No entry with ID {args.id}"))
        return

    e = matches[0]
    changed = []

    if args.status:
        valid = ["completed", "failed", "running", "pending"]
        if args.status not in valid:
            print(RED(f"Invalid status. Choose from: {', '.join(valid)}"))
            return
        e["status"] = args.status
        changed.append(f"status -> {args.status}")

    if args.notes:
        e["notes"] = args.notes
        changed.append("notes updated")

    if args.append_notes:
        existing = e.get("notes", "")
        e["notes"] = (existing + "\n" + args.append_notes).strip()
        changed.append("notes appended")

    if args.results:
        e["results"] = args.results
        changed.append("results updated")

    if args.job_id:
        e["job_id"] = args.job_id
        changed.append(f"job_id -> {args.job_id}")

    if not changed:
        print(YELLOW("Nothing to update. Use --status, --notes, --append-notes, --results, or --job-id."))
        return

    save_data(entries, todos)
    print(GREEN(f"\n✓ Entry #{args.id} updated:"))
    for ch in changed:
        print(f"  {ch}")
    print()



def cmd_delete(args):
    entries, todos = load_data()
    match = next((e for e in entries if e["id"] == args.id), None)
    if not match:
        print(RED(f"No entry with ID {args.id}"))
        return
    print(f"  #{match['id']}  {match['date']}  {match['title']}")
    confirm = input(YELLOW("  Delete this entry? (y/N): ")).strip().lower()
    if confirm != 'y':
        print(DIM("  Cancelled."))
        return
    entries = [e for e in entries if e["id"] != args.id]
    save_data(entries, todos)
    print(GREEN(f"✓ Entry #{args.id} deleted.\n"))

def cmd_list(args):
    entries, _ = load_data()
    if not entries:
        print(YELLOW("No entries yet. Use `add` to create one."))
        return

    if args.tag:
        entries = [e for e in entries if args.tag.lower() in [t.lower() for t in e.get("tags", [])]]
    if args.status:
        entries = [e for e in entries if e.get("status", "").lower() == args.status.lower()]

    entries.sort(key=lambda e: e.get("date", ""), reverse=True)

    print(BOLD(f"\n{'ID':<5} {'Date':<12} {'Status':<11} {'Tool':<20} {'Title'}"))
    print("-" * 80)
    for e in entries:
        status = e.get("status", "")
        color = GREEN if status == "completed" else (RED if status == "failed" else YELLOW)
        print(
            f"{DIM(str(e['id'])):<5} "
            f"{e['date']:<12} "
            f"{color(status):<11} "
            f"{e.get('tool','')[:18]:<20} "
            f"{e.get('title','')[:50]}"
        )
    print(f"\n{DIM(str(len(entries)) + ' entries')}\n")


def cmd_view(args):
    entries, _ = load_data()
    matches = [e for e in entries if e["id"] == args.id]
    if not matches:
        print(RED(f"No entry with ID {args.id}"))
        return

    e = matches[0]
    sep = "-" * 60

    def row(k, v):
        if v:
            print(f"  {CYAN(k+':'):<22} {v}")

    print(BOLD(f"\n-- Entry #{e['id']}: {e.get('title','')} --"))
    print(sep)
    row("Timestamp",    e.get("timestamp"))
    row("Analyst",      e.get("analyst"))
    row("Project",      e.get("project"))
    row("Organism",     e.get("organism"))
    row("Sample IDs",   ", ".join(e.get("sample_ids", [])))
    print(sep)
    row("Tool",         e.get("tool"))
    row("Tool version", e.get("tool_version"))
    row("Script",       e.get("script"))
    row("Reference",    e.get("ref_genome"))
    if e.get("command"):
        print(f"  {CYAN('Command(s):')}")
        for line in e["command"].splitlines():
            print(f"    {line}")
    print(sep)
    row("Job ID",       e.get("job_id"))
    row("Cluster",      e.get("cluster"))
    row("CPUs",         e.get("cpus"))
    row("Memory",       e.get("mem"))
    row("Wall time",    e.get("walltime"))
    print(sep)
    row("Output dir",   e.get("output_dir"))
    if e.get("input_files"):
        print(f"  {CYAN('Input files:')}")
        for line in e["input_files"].splitlines():
            print(f"    {line}")
    print(sep)
    row("Status",       e.get("status"))
    if e.get("results"):
        print(f"  {CYAN('Results:')}")
        for line in e["results"].splitlines():
            print(f"    {line}")
    if e.get("notes"):
        print(f"  {CYAN('Notes:')}")
        for line in e["notes"].splitlines():
            print(f"    {line}")
    row("Tags",         ", ".join(e.get("tags", [])))
    print()


def cmd_search(args):
    entries, _ = load_data()
    kw = args.keyword.lower()
    fields = ["title", "tool", "project", "sample_ids", "tags",
              "results", "notes", "command", "output_dir", "job_id"]
    hits = []
    for e in entries:
        for f in fields:
            val = e.get(f, "")
            if isinstance(val, list):
                val = " ".join(val)
            if kw in val.lower():
                hits.append(e)
                break
    if not hits:
        print(YELLOW(f"No entries matching '{args.keyword}'"))
        return
    print(BOLD(f"\nFound {len(hits)} match(es) for '{args.keyword}':"))
    for e in hits:
        print(f"  #{e['id']}  {DIM(e['date'])}  {e.get('title','')}  {DIM('['+e.get('status','')+']')}")
    print()


def cmd_export(args):
    entries, _ = load_data()
    if not entries:
        print(YELLOW("No entries to export."))
        return
    outfile = args.output or "genomic_logbook.csv"
    flat_fields = [
        "id", "timestamp", "date", "title", "analyst", "project",
        "organism", "tool", "tool_version", "script", "ref_genome",
        "job_id", "cluster", "cpus", "mem", "walltime",
        "output_dir", "status", "tags",
    ]
    with open(outfile, "w", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=flat_fields, extrasaction="ignore")
        writer.writeheader()
        for e in entries:
            row = dict(e)
            row["tags"] = ", ".join(e.get("tags", []))
            row["sample_ids"] = ", ".join(e.get("sample_ids", []))
            writer.writerow(row)
    print(GREEN(f"✓ Exported {len(entries)} entries to {outfile}"))


# ── Todo commands ─────────────────────────────────────────────────────────────

def cmd_todo(args):
    dispatch = {
        "add":    todo_add,
        "list":   todo_list,
        "done":   todo_done,
        "remove": todo_remove,
    }
    if args.todo_command in dispatch:
        dispatch[args.todo_command](args)
    else:
        print(YELLOW("Usage: todo add | todo list | todo done <id> | todo remove <id>"))


def todo_add(args):
    entries, todos = load_data()
    todo_id = next_id(todos)
    now = datetime.now().isoformat(timespec="seconds")

    print(BOLD(f"\n-- New To-Do #{todo_id} --"))
    task     = prompt("Task description", required=True)
    category = choose("Category", ["pending-analysis", "follow-up", "other"])
    priority = choose("Priority", ["high", "medium", "low"])
    due      = prompt("Due date (YYYY-MM-DD, optional)")
    ref_id   = prompt("Related log entry ID (optional)")

    todos.append({
        "id":       todo_id,
        "created":  now,
        "task":     task,
        "category": category,
        "priority": priority,
        "due":      due,
        "ref_id":   ref_id,
        "done":     False,
        "done_at":  None,
    })
    save_data(entries, todos)
    print(GREEN(f"\n✓ To-do #{todo_id} saved to {LOGBOOK_FILE}\n"))


def todo_list(args):
    _, todos = load_data()
    if not todos:
        print(YELLOW("No to-dos yet. Use `todo add` to create one."))
        return

    pending = [t for t in todos if not t["done"]]
    done    = [t for t in todos if t["done"]]
    priority_order = {"high": 0, "medium": 1, "low": 2}
    pending.sort(key=lambda t: (priority_order.get(t["priority"], 9), t.get("due") or "9999"))

    def priority_color(p):
        return RED(p) if p == "high" else (YELLOW(p) if p == "medium" else DIM(p))

    if pending:
        print(BOLD(f"\n-- Pending ({len(pending)}) --"))
        print(f"  {'ID':<5} {'Pri':<8} {'Due':<12} {'Category':<20} Task")
        print("  " + "-" * 72)
        for t in pending:
            ref = f" [log #{t['ref_id']}]" if t.get("ref_id") else ""
            print(
                f"  {DIM(str(t['id'])):<5} "
                f"{priority_color(t['priority']):<8} "
                f"{(t.get('due') or '-'):<12} "
                f"{t.get('category','')[:18]:<20} "
                f"{t['task'][:50]}{ref}"
            )

    if done:
        print(BOLD(f"\n-- Done ({len(done)}) --"))
        for t in done:
            print(f"  {DIM('#'+str(t['id'])):<6} {DIM(t['task'][:60])}")

    if not pending and not done:
        print(YELLOW("No to-dos found."))
    print()


def todo_done(args):
    entries, todos = load_data()
    matches = [t for t in todos if t["id"] == args.todo_id]
    if not matches:
        print(RED(f"No to-do with ID {args.todo_id}"))
        return
    t = matches[0]
    if t["done"]:
        print(YELLOW(f"To-do #{args.todo_id} is already marked done."))
        return
    t["done"]    = True
    t["done_at"] = datetime.now().isoformat(timespec="seconds")
    save_data(entries, todos)
    print(GREEN(f"✓ To-do #{args.todo_id} marked as done: {t['task']}\n"))


def todo_remove(args):
    entries, todos = load_data()
    before = len(todos)
    todos = [t for t in todos if t["id"] != args.todo_id]
    if len(todos) == before:
        print(RED(f"No to-do with ID {args.todo_id}"))
        return
    save_data(entries, todos)
    print(GREEN(f"✓ To-do #{args.todo_id} removed.\n"))


# ── Migration ─────────────────────────────────────────────────────────────────

def cmd_migrate(args):
    """Merge old genomic_todos.json into genomic_logbook.json."""
    old_todo_file = Path("genomic_todos.json")

    if not old_todo_file.exists():
        print(YELLOW("No genomic_todos.json found — nothing to migrate."))
        return

    entries, existing_todos = load_data()

    with open(old_todo_file) as f:
        old_todos = json.load(f)

    if existing_todos:
        print(YELLOW(f"Logbook already has {len(existing_todos)} to-dos. Skipping migration to avoid duplicates."))
        print(YELLOW("Delete the 'todos' key from genomic_logbook.json first if you want to re-migrate."))
        return

    save_data(entries, old_todos)
    print(GREEN(f"✓ Migrated {len(old_todos)} to-dos into {LOGBOOK_FILE}"))
    print(DIM(f"  You can now delete genomic_todos.json safely.\n"))


# ── Main ──────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(
        description="Genomic Analysis Logbook",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    sub = parser.add_subparsers(dest="command")

    p_add = sub.add_parser("add", help="Add a new log entry (quick by default)")
    p_add.add_argument("--full", action="store_true", help="Ask all fields")

    p_list = sub.add_parser("list", help="List entries")
    p_list.add_argument("--tag", help="Filter by tag")
    p_list.add_argument("--status", help="Filter by status")

    p_view = sub.add_parser("view", help="View a full entry")
    p_view.add_argument("id", type=int)

    p_delete = sub.add_parser("delete", help="Delete a log entry")
    p_delete.add_argument("id", type=int, help="Entry ID to delete")

    p_update = sub.add_parser("update", help="Update fields of an existing entry")
    p_update.add_argument("id", type=int, help="Entry ID to update")
    p_update.add_argument("--status", help="New status (completed/failed/running/pending)")
    p_update.add_argument("--notes", help="Replace notes")
    p_update.add_argument("--append-notes", dest="append_notes", help="Append to existing notes")
    p_update.add_argument("--results", help="Replace results")
    p_update.add_argument("--job-id", dest="job_id", help="Set SLURM job ID")

    p_search = sub.add_parser("search", help="Search entries by keyword")
    p_search.add_argument("keyword")

    p_export = sub.add_parser("export", help="Export entries to CSV")
    p_export.add_argument("-o", "--output", help="Output CSV filename")

    p_todo = sub.add_parser("todo", help="Manage to-do items")
    todo_sub = p_todo.add_subparsers(dest="todo_command")
    todo_sub.add_parser("add",  help="Add a to-do")
    todo_sub.add_parser("list", help="List to-dos")
    p_td = todo_sub.add_parser("done",   help="Mark a to-do as done")
    p_td.add_argument("todo_id", type=int)
    p_tr = todo_sub.add_parser("remove", help="Delete a to-do")
    p_tr.add_argument("todo_id", type=int)

    sub.add_parser("migrate", help="Merge old genomic_todos.json into the logbook file")

    args = parser.parse_args()

    dispatch = {
        "add":     cmd_add,
        "list":    cmd_list,
        "view":    cmd_view,
        "update":  cmd_update,
        "delete":  cmd_delete,
        "search":  cmd_search,
        "export":  cmd_export,
        "todo":    cmd_todo,
        "migrate": cmd_migrate,
    }

    if args.command in dispatch:
        dispatch[args.command](args)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
