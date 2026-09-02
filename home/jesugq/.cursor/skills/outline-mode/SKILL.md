---
name: outline-mode
description: Every content reply is hidden behind a numbered outline the user expands with `<LETTER><NUMBER>`. Majors are `A..Z` (new topics), minors are parent-scoped `Aa..Zz` (follow-ups). Activated by bare `/outline-mode`; housekeeping via `/outline-mode clear|close|purge`.
disable-model-invocation: true
---

# Outline mode

State lives under `$DIR = ~/.cursor/outline-mode/sessions/$CURSOR_CONVERSATION_ID` (refuse if unset). Activated by bare `/outline-mode` and stays on for the rest of the conversation; other subcommands are housekeeping and reply with a single confirmation line.

## Subcommands

- `/outline-mode` (no subcommand):
  - **First activation** (`$DIR` does not exist) — activate outline mode for the rest of the conversation. Reply with the single line `[outline-mode] activated`.
  - **Subsequent invocations** (`$DIR` exists) — treat as a signal that outline mode was not respected for the latest assistant response. Prepend the single line `[outline-mode] not respected for previous response; re-running workflow`, then run **Classify and letter** / **Persist** / **Render** against the previous turn: classify using the previous **user query** (major vs minor), split the previous **assistant response** into 3–7 sections, persist under the resulting letter, and render normally.
- `clear` — wipe `$DIR/minor-*.json`. Resets every parent's minor counter to `a`; recovery for the minor 26-cap.
- `close` — wipe `$DIR/major-*.json`, `$DIR/minor-*.json`, `$DIR/latest.json`. Resets both counters; recovery for the major 26-cap.
- `purge` — wipe all major/minor JSONs across `~/.cursor/outline-mode/sessions/*`.
- Any other `/outline-mode <subcommand>` → one-line usage summary of the three housekeeping subcommands.

## Classify and letter

- Major (new/distinct topic) or minor (short follow-up, clarification, drill-in on the current major). Force major if no `$DIR/major-*.json` exists yet; default to major when uncertain.
- For minors, pick `<PARENT>` = the most recent major's letter (or an earlier major the query obviously references).
- Major letter = `chr(ord('A') + count($DIR/major-*.json))`. If ≥ 26, write nothing and tell the user inline to run `/outline-mode close` or start a new conversation.
- Minor letter = `<PARENT><child>` where `child = chr(ord('a') + count($DIR/minor-<PARENT>[a-z]-*.json))`. If ≥ 26, write nothing and tell the user inline to run `/outline-mode clear` or `/outline-mode close`.

## Persist

Split the reply into 3–7 sections with 5–10 word titles, save `$DIR/<kind>-<LETTER>-<UTC-ISO>-<slug>.json` (kind is `major` or `minor`; `<LETTER>` is one char for majors, two for minors, e.g. `minor-Aa-…json`), and mirror to `$DIR/latest.json`.

Schema: `{created_at, kind, letter, parent_letter?, user_query_summary, outline, sections, read}`.

- `outline` — plain titles; index `0` is the summary.
- `sections` — keys are bare numbers from `"1"`.
- `read` — starts as `["0"]`.
- `parent_letter` — set only for minors (`"A"` when `letter` is `"Aa"`).

## Render

Emit only the outline, one entry per line. Each `<space>` below is a line containing exactly one U+0020 space (not empty) so renderers that strip pure-empty lines still preserve the gaps.

    [major] or [minor of <PARENT>]
    <space>
    <own entries>
    <space>
    <child minors — majors only>
    <space>

- Own entry: `<LETTER><i> - <M> - <KIND> - <title>` for every `i` in `0..len(outline)-1`, where `<LETTER>` is the full identifier (one uppercase char for majors, two chars `<PARENT><child>` for minors, case preserved), `<title>` = `outline[i]`, `<M>` = `*` if `str(i)` in `read` else a single space, `<KIND>` = `OUTLINE` when `i == 0` else `HEADER`. Fields joined by ` - `. Since `read` starts as `["0"]`, the first line is always `<LETTER>0 - * - OUTLINE - <summary>`.
- Child minors (majors only): glob `$DIR/minor-<THIS-MAJOR>[a-z]-*.json`, sort by child letter (creation order), one line each as `<PARENT><child>0 - * - OUTLINE - <summary>` (the minor's `outline[0]`).
- Always emit the trailing `<space>` line. For a minor, or a major with zero children, the child block is empty but its surrounding `<space>` lines still appear.

## Follow-ups (case-sensitive)

`<LETTER>` is either a one-char uppercase major letter or a two-char minor identifier `<PARENT><child>` (uppercase then lowercase).

- `<LETTER><NUMBER>` with NUMBER ≥ 1 → glob `$DIR/major-<LETTER>-*.json` if `<LETTER>` is a single uppercase char, else `$DIR/minor-<LETTER>-*.json`. Print `sections["<NUMBER>"]` in full, append `"<NUMBER>"` to `read` (dedupe), persist, then re-append the tagged updated outline.
- `<LETTER>` alone or `<LETTER>0` → reprint that outline; no state change.
- Unknown letter, missing section, or no `latest.json` → one-line apology and reprint the latest outline (or say none exists).
- Anything else → treat as a new query.

Case disambiguates: `A1` = major section 1; `Aa` = minor identifier; `Aa1` = minor section 1.

## Bypass

These skip the outline workflow and emit raw text:

- **Activation and subcommand acks** — first-time bare `/outline-mode` (activation) and `/outline-mode clear|close|purge` (housekeeping) reply with a single confirmation line. Subsequent bare `/outline-mode` does **not** bypass — it runs the full outline workflow against the previous turn (see Subcommands).
- **Follow-up expansions and reprints** — section expansions (which re-append the updated outline), plain reprints, and the one-line apology on bad routing.
- **Capacity-error inline notices** — major or minor 26-cap message pointing at `close`/`clear`.
- **Short prose** — trivial one-liners (e.g. "Yes", "Done", tool-only turns). Use sparingly; anything substantive still gets an outline.
