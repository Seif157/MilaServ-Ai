# Downloads — spec for Laravel

> **Implements** architecture §9.3. Tracked as need B12.
> **Status** Draft · 2026-09-21

## Rules

1. **Every answer with a table can be downloaded** as Excel (`.xlsx`) and CSV. Refusals and
   `needs_choice` have no table, so no download
2. **The same rows as the screen.** The file is built from the rows the answer was built from —
   never by running the query again
3. **Same columns, same order, same headers** as the on-screen table: the `labels` for that
   question type in `templates.yaml`, in the answer's language. Coded values (`values` in
   `templates.yaml`) are shown as their labels
4. **Held for 10 minutes, keyed by turn and asker.** Only the asker who made the turn can download
   it, and only within 10 minutes. After that: *"ask again to download"* —
   ar: «اسأل تاني عشان تنزّل الملف.» · en: "Ask again to download."
5. **Nothing is written to disk** — no file cache, no temporary file, no database row. Hold the rows
   in an in-memory store with a 10-minute expiry, and build the file in memory when it is requested
6. **The download request carries no employee ID** — only the turn (L9). The asker comes from the
   session (L1)
7. **No answer values in the turn log** because of a download (turn-log.md)

## File format

- **CSV:** UTF-8 **with a byte-order mark**, so Excel opens Arabic correctly; comma-separated;
  CRLF line ends, as RFC 4180 says
- **Formula injection:** any cell whose text starts with `=`, `+`, `-`, `@`, a tab or a carriage
  return is prefixed with `'`, in both formats — values such as `document_title` are typed by people
- **Numbers and dates** keep their type in `.xlsx`; in CSV they are written as on screen
- **File name:** `hr-assistant-<question_type>-<YYYY-MM-DD>.<xlsx|csv>` — no employee name or number
  in the file name
