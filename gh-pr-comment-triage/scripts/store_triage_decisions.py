#!/usr/bin/env python3
import argparse
import json
import sqlite3
import sys
from pathlib import Path

ALLOWED_DECISIONS = {
    "already fixed",
    "should be fixed",
    "should not be fixed",
}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Persist PR triage decisions into a SQLite database. "
            "Reads a JSON array from stdin."
        )
    )
    parser.add_argument("--pr-number", type=int, required=True)
    parser.add_argument(
        "--db-path",
        type=Path,
        default=Path(__file__).resolve().parent.parent / "data" / "triage_decisions.db",
    )
    return parser.parse_args()


def require_string(item: dict, key: str) -> str:
    value = item.get(key)
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{key} must be a non-empty string")
    return value.strip()


def load_items(raw: str) -> list[dict]:
    try:
        payload = json.loads(raw)
    except json.JSONDecodeError as exc:
        raise ValueError(f"invalid JSON input: {exc}") from exc

    if not isinstance(payload, list):
        raise ValueError("input JSON must be an array")

    rows: list[dict] = []
    for idx, item in enumerate(payload, start=1):
        if not isinstance(item, dict):
            raise ValueError(f"item {idx} must be an object")

        comment_id = require_string(item, "comment_id")
        author_name = require_string(item, "author_name")
        decision = require_string(item, "decision")
        minimal_comment_summary = require_string(item, "minimal_comment_summary")

        if decision not in ALLOWED_DECISIONS:
            raise ValueError(
                f"item {idx} has invalid decision '{decision}'. "
                f"Allowed: {', '.join(sorted(ALLOWED_DECISIONS))}"
            )

        rows.append(
            {
                "comment_id": comment_id,
                "author_name": author_name,
                "decision": decision,
                "minimal_comment_summary": minimal_comment_summary,
            }
        )

    return rows


def ensure_schema(conn: sqlite3.Connection) -> None:
    conn.execute(
        """
        CREATE TABLE IF NOT EXISTS pr_comment_triage (
            pr_number INTEGER NOT NULL,
            comment_id TEXT NOT NULL,
            author_name TEXT NOT NULL,
            decision TEXT NOT NULL,
            minimal_comment_summary TEXT NOT NULL,
            created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (pr_number, comment_id)
        )
        """
    )


def upsert_rows(conn: sqlite3.Connection, pr_number: int, rows: list[dict]) -> int:
    for row in rows:
        conn.execute(
            """
            INSERT INTO pr_comment_triage (
                pr_number,
                comment_id,
                author_name,
                decision,
                minimal_comment_summary
            ) VALUES (?, ?, ?, ?, ?)
            ON CONFLICT(pr_number, comment_id) DO UPDATE SET
                author_name = excluded.author_name,
                decision = excluded.decision,
                minimal_comment_summary = excluded.minimal_comment_summary,
                updated_at = CURRENT_TIMESTAMP
            """,
            (
                pr_number,
                row["comment_id"],
                row["author_name"],
                row["decision"],
                row["minimal_comment_summary"],
            ),
        )
    return len(rows)


def main() -> int:
    args = parse_args()

    if args.pr_number <= 0:
        print("--pr-number must be a positive integer", file=sys.stderr)
        return 1

    raw = sys.stdin.read().strip()
    if not raw:
        print("no JSON input provided on stdin", file=sys.stderr)
        return 1

    try:
        rows = load_items(raw)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    args.db_path.parent.mkdir(parents=True, exist_ok=True)

    with sqlite3.connect(args.db_path) as conn:
        ensure_schema(conn)
        count = upsert_rows(conn, args.pr_number, rows)
        conn.commit()

    print(
        f"Stored {count} triage decision(s) for PR #{args.pr_number} in {args.db_path}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
