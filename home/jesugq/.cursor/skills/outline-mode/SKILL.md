---
name: outline-mode
description: Every content reply is hidden behind a numbered outline the user expands with `<LETTER><NUMBER>`. Cursor tags each reply as major (`A..Z`) for new topics or minor (`a..z`) for follow-ups on the current major, marking each section with `*` once it's been read. Only activates via `/outline-mode start|stop|clear|close|purge`.
disable-model-invocation: true
---

# Outline mode

State lives under `$DIR = ~/.cursor/outline-mode/sessions/$CID` where `$CID = $CURSOR_CONVERSATION_ID` (refuse if unset). Outline mode is active while `$DIR/ACTIVE` exists. Every subcommand replies with a single confirmation line and nothing else.

## Subcommands

- `start` — create `$DIR/ACTIVE`.
- `stop` — remove `$DIR/ACTIVE`; response JSONs stay on disk.
- `clear` — wipe only `$DIR/minor-*.json` (bash-clear: only minor topics). Resets the minor counter to `a`; recovery path for the minor 26-cap.
- `close` — wipe `$DIR/major-*.json` + `$DIR/minor-*.json` + `$DIR/latest.json` (close-the-window). Resets both counters; recovery path for the major 26-cap.
- `purge` — wipe major and minor JSONs across all sessions under `~/.cursor/outline-mode/sessions/*` (database purge).

Any other `/outline-mode …` message → one-line usage summary of the five subcommands.

## Response workflow (while `ACTIVE`)

1. Classify the query as **major** (new/distinct topic) or **minor** (short follow-up, clarification, or drill-in on the current major). If no `$DIR/major-*.json` exists yet, force major. When uncertain, default to major.
2. Compose the reply internally, then split it into 3–7 sections with 5–10 word titles.
3. Assign a letter and (for minors) a parent:
   - Major: count `$DIR/major-*.json` as `N`. Letter = `chr(ord('A') + N)`. If `N >= 26`, write nothing and tell the user inline to run `/outline-mode close` or start a new conversation.
   - Minor: count `$DIR/minor-*.json` as `N`. Letter = `chr(ord('a') + N)`. If `N >= 26`, write nothing and tell the user inline to run `/outline-mode clear` or `/outline-mode close`. Set `parent_letter` to the most recent major's letter (or an earlier major if the query obviously references it).
4. Save `$DIR/<kind>-<LETTER>-<UTC-ISO>-<slug>.json` (where `<kind>` is `major` or `minor`) and mirror to `$DIR/latest.json`. Schema: `{created_at, kind, letter, parent_letter?, user_query_summary, outline, sections, read}`. `outline` is plain titles (index `0` is the summary); `sections` keys are bare numbers from `"1"`; `read` starts as `["0"]`. `parent_letter` is set only for minors.
5. Reply with only the rendered outline, one entry per line. Prepend a tag line — `[major]` or `[minor of <PARENT>]` (uppercase parent letter). Render this response's own entries as `<LETTER><i> <M> - <title>` where `<M>` is `*` if `str(i)` in `read` else a single space, preserving letter case (upper for major, lower for minor). For a major, then append one line per child minor found by globbing `$DIR/minor-*.json` and keeping those with `parent_letter == this letter`, sorted by minor letter (creation order), formatted `<letter>0 * - <summary>` (the minor's `outline[0]`).

## Follow-ups (case-sensitive routing)

- `<LETTER><NUMBER>` with NUMBER ≥ 1 → glob `$DIR/major-<LETTER>-*.json` if `<LETTER>` is uppercase, else `$DIR/minor-<LETTER>-*.json`. Print `sections["<NUMBER>"]` in full, append `"<NUMBER>"` to that response's `read` (dedupe), persist, then re-append the tagged updated outline.
- `<LETTER>` alone or `<LETTER>0` → reprint only that response's tagged outline; no state change.
- Unknown letter, missing section, or no `latest.json` → one-line apology and reprint the latest tagged outline (or say none exists). Anything else → treat as a new query.

## Bypass

Only subcommand acknowledgements and follow-up expansions/reprints skip the new-outline workflow; they operate on existing outlines or emit a single confirmation line.
