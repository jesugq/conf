---
name: outline-mode
description: Toggle with `/outline-mode`. While on, every substantive reply is written to the next `NN-<slug>.md` under `$DIR`; chat only names the folder and the new file. No in-chat outlines.
disable-model-invocation: true
---

# Outline mode

State lives under `$DIR = ~/.cursor/outline-mode/sessions/$CURSOR_CONVERSATION_ID` (refuse if unset). On is `$DIR/ENABLED` existing (a zero-byte sentinel, not JSON). Folder existence alone is not on — leftover markdown without `ENABLED` is off. `/outline-mode` toggles; extra words after it are ignored.

## Action comment

Every outline-mode action — enabling, disabling, creating a file, hitting the 99-file cap — opens with exactly one line before any other content:

    [outline-mode] <short comment>

`<short comment>` is `enabled`, `disabled`, `created a file`, or `limit reached`. Then print the absolute path of `$DIR` on its own line. A write turn adds the absolute path of the new file on the next line. Nothing else (no titles, outline, or section bodies).

Enable / disable:

    [outline-mode] enabled
    /Users/<you>/.cursor/outline-mode/sessions/<id>

Write:

    [outline-mode] created a file
    /Users/<you>/.cursor/outline-mode/sessions/<id>
    /Users/<you>/.cursor/outline-mode/sessions/<id>/01-what-is-outline-mode.md

## Toggle

- Off → on: create `$DIR` if needed, write `$DIR/ENABLED`, comment `enabled`, print `$DIR`. Keep any existing `NN-*.md`; the next write continues the index.
- On → off: delete only `$DIR/ENABLED`. Leave every markdown file. Comment `disabled`, print `$DIR`.

## Write

While on, each substantive user query creates exactly one new file. Never edit an existing file (follow-ups and revisions are the next index). Ignore leftover `major-*` / `minor-*` / `*.json` names.

- Next index = `count($DIR/[0-9][0-9]-*.md) + 1`, zero-padded to two digits (`01`, `02`, …).
- Path: `$DIR/<NN>-<slug>.md`. `<slug>` is kebab-case from the H1 summary (lowercase, hyphens, no spaces).
- If the next index would be `100`, write nothing, comment `limit reached`, print `$DIR`, and tell the user inline to start a new conversation. Two-digit prefixes only — `100-*.md` would sort before `99-*.md`.

Shape:

    # <5-10 word summary>

    ## <5-10 word title>
    <full section body>

    ## ...

Three to seven `##` sections. No YAML frontmatter. No JSON sidecar.

## Bypass

These skip creating a markdown file but still open with the action comment line when they are outline-mode actions:

- **Toggle acks** — comment plus the `$DIR` line only.
- **Capacity** — comment `limit reached`, `$DIR` line, one-line “start a new conversation.”
- **Short prose** — trivial one-liners unrelated to any outline-mode action (e.g. plain "Yes", "Done", tool-only turns) get no comment line and no file. Use sparingly; anything substantive still goes through outline mode.
