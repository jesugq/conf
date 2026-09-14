---
name: outline-mode
description: Every content reply is hidden behind a numbered outline the user expands with `<LETTER><NUMBER>`. Majors are `A..Z` (new topics), minors are parent-scoped `Aa..Zz` (follow-ups). Enabled by `/outline-mode enable`; housekeeping via `/outline-mode delete|export|import`. Every action opens with a one-line `[outline-mode] <comment>` summary.
disable-model-invocation: true
---

# Outline mode

State lives under `$DIR = ~/.cursor/outline-mode/sessions/$CURSOR_CONVERSATION_ID` (refuse if unset). Enabled by `/outline-mode enable` and stays on for the rest of the conversation; other subcommands are housekeeping.

## Action comment

Every outline-mode action — enabling, a subcommand, a major/minor render, a follow-up expansion, a reprint, an apology, a capacity error — opens with exactly one line before any other content:

    [outline-mode] <short comment>

`<short comment>` is a terse present/past-tense description of what happened (e.g. `enabled`, `printed a major`, `printed a minor`, `expanded section A1`, `reprinted outline A`, `deleted session folder`, `exported data`, `imported data`, `unrecognized subcommand`, `major limit reached`). Whatever content follows (outline, section text, usage summary, apology, pasted JSON) comes after this line.

## Subcommands

- `enable` — activate outline mode for the rest of the conversation. Comment: `enabled`. No outline follows.
- `delete` — delete `$DIR` for the current conversation entirely (the whole session folder, not just the major/minor files inside it). This is the only reset mechanism, covering both the major and minor 26-caps. Comment: `deleted session folder`.
- `export` — paste the full raw content of every `$DIR/*.json` file for the current conversation directly into the reply: a `<filename>` header line followed by its content in its own fenced code block (`json` language tag), one per file. If everything doesn't fit in a single reply, split across consecutive replies without ever splitting a single file's content across two replies, and mark each as `part <i>/<n>` in the comment. Comment: `exported data` (or `exported data (part <i>/<n>)` when split).
- `import` — accept one or more JSON file contents pasted directly in the request, each preceded by its intended filename (e.g. a header line or fenced-block label naming it). Create `$DIR` if it doesn't exist, and write each pasted block verbatim to `$DIR/<filename>` (overwriting any same-named file). If a pasted block isn't valid JSON matching the schema in Persist, skip it and name it in the reply rather than writing a broken file. Comment: `imported data`.
- Any other or missing subcommand (including bare `/outline-mode`) → comment `unrecognized subcommand`, then a one-line usage summary listing `enable`, `delete`, `export`, `import`.

## Classify and letter

- Major (new/distinct topic) or minor (short follow-up, clarification, drill-in on the current major). Force major if no `$DIR/major-*.json` exists yet; default to major when uncertain.
- For minors, pick `<PARENT>` = the most recent major's letter (or an earlier major the query obviously references).
- Major letter = `chr(ord('A') + count($DIR/major-*.json))`. If ≥ 26, write nothing, comment `major limit reached`, and tell the user inline to run `/outline-mode delete` or start a new conversation.
- Minor letter = `<PARENT><child>` where `child = chr(ord('a') + count($DIR/minor-<PARENT>[a-z]-*.json))`. If ≥ 26, write nothing, comment `minor limit reached`, and tell the user inline to run `/outline-mode delete`.

## Persist

Split the reply into 3–7 sections with 5–10 word titles, save `$DIR/<kind>-<LETTER>-<UTC-ISO>-<slug>.json` (kind is `major` or `minor`; `<LETTER>` is one char for majors, two for minors, e.g. `minor-Aa-…json`). The embedded UTC-ISO timestamp in the filename is load-bearing: it lets "the most recent major/minor" be recovered later by a lexicographic sort, so no separate pointer file is needed.

Schema: `{created_at, kind, letter, parent_letter?, user_query_summary, outline, sections, read}`.

- `outline` — plain titles; index `0` is the summary.
- `sections` — keys are bare numbers from `"1"`.
- `read` — starts as `["0"]`.
- `parent_letter` — set only for minors (`"A"` when `letter` is `"Aa"`).

## Render

After the action comment line (`printed a major` / `printed a minor`), emit the outline, one entry per line, wrapped in a single fenced code block (triple backtick, no language tag) so the chat renderer preserves line breaks literally instead of collapsing them into one paragraph. Each `<space>` below is a line containing exactly one U+0020 space (not empty) so renderers that strip pure-empty lines still preserve the gaps.

    ```
    [major <LETTER>] or [minor <LETTER> of <PARENT>]
    <space>
    <own entries>
    <space>
    <child minors — majors only>
    <space>
    ```

- The fence wraps the entire outline output, from the `[major <LETTER>]`/`[minor <LETTER> of <PARENT>]` header line through the final trailing `<space>` line — nothing else goes inside it.
- Own entry: `<LETTER><i> - <M> - <KIND> - <title>` for every `i` in `0..len(outline)-1`, where `<LETTER>` is the full identifier (one uppercase char for majors, two chars `<PARENT><child>` for minors, case preserved), `<title>` = `outline[i]`, `<M>` = `*` if `str(i)` in `read` else a single space, `<KIND>` = `OUTLINE` when `i == 0` else `HEADER`. Fields joined by ` - `. Since `read` starts as `["0"]`, the first line is always `<LETTER>0 - * - OUTLINE - <summary>`.
- Child minors (majors only): glob `$DIR/minor-<THIS-MAJOR>[a-z]-*.json`, sort by child letter (creation order), one line each as `<PARENT><child>0 - * - OUTLINE - <summary>` (the minor's `outline[0]`).
- Always emit the trailing `<space>` line. For a minor, or a major with zero children, the child block is empty but its surrounding `<space>` lines still appear.

## Follow-ups (case-sensitive)

`<LETTER>` is either a one-char uppercase major letter or a two-char minor identifier `<PARENT><child>` (uppercase then lowercase).

- `<LETTER><NUMBER>` with NUMBER ≥ 1 → glob `$DIR/major-<LETTER>-*.json` if `<LETTER>` is a single uppercase char, else `$DIR/minor-<LETTER>-*.json`. Comment `expanded section <LETTER><NUMBER>`, print `sections["<NUMBER>"]` in full, append `"<NUMBER>"` to `read` (dedupe), persist, then re-append the tagged updated outline.
- `<LETTER>` alone or `<LETTER>0` → comment `reprinted outline <LETTER>`, reprint that outline; no state change.
- Unknown letter, missing section, or `$DIR` has no `major-*.json`/`minor-*.json` files yet → comment `nothing to show`, one-line apology, and reprint the latest outline — found by globbing `$DIR/major-*.json` and `$DIR/minor-*.json` together, sorting lexicographically (the UTC-ISO timestamp in each filename sorts correctly as a plain string), and taking the last one — or say none exists if the glob is empty.
- Anything else → treat as a new query.

Case disambiguates: `A1` = major section 1; `Aa` = minor identifier; `Aa1` = minor section 1.

## Bypass

These skip splitting into sections and persisting (no `major-*`/`minor-*` JSON is written), but still open with the action comment line:

- **Enable and subcommand acks** — `enable` and `delete` are a comment line plus a single line of content (confirmation). `export`/`import` are a comment line plus the pasted JSON content (which may span multiple replies for `export`, per its spec above). Unrecognized-subcommand replies are a comment line plus a one-line usage summary.
- **Follow-up expansions and reprints** — comment line plus section expansion (which re-appends the updated outline), plain reprint, or the apology on bad routing.
- **Capacity-error inline notices** — comment line plus the major/minor limit message pointing at `delete`.
- **Short prose** — trivial one-liners unrelated to any outline-mode action (e.g. plain "Yes", "Done", tool-only turns) get no comment line and no outline. Use sparingly; anything substantive still goes through outline mode.
