---
name: mermaid-mode
description: Toggle with `/mermaid-mode`. While on, every substantive reply is written to the next `NN-<slug>.md` under `$DIR` as a printed mermaid graph; chat only names the folder and the new file. No in-chat graphs or mermaid source.
disable-model-invocation: true
---

# Mermaid mode

Shared with outline-mode, takeoff-mode, and handoff-mode. `$NAME` is `<local YYYY-MM-DD>-<$CURSOR_CONVERSATION_ID>`: the date, one hyphen, then the conversation id, with no spaces. `$DIR = ~/.cursor/dynamic-mode/$NAME` (refuse if the conversation id is unset). Example: `~/.cursor/dynamic-mode/2026-09-24-<id>`. All four modes use this one folder and the same `NN-*.md` sequence. The date is the local calendar date at the start of the turn; the same day and conversation always resolve to the same `$DIR`.

On iff `$DIR/MERMAID` exists (zero-byte sentinel). `$DIR/OUTLINE` means outline-mode is on instead. `$DIR/TAKEOFF` means takeoff-mode is on instead. `$DIR/HANDOFF` means handoff-mode is on instead. Neither sentinel means off — a folder or leftover markdown alone is off. The four sentinels are mutually exclusive. `/mermaid-mode` toggles this mode (ignore extra words). `/outline-mode`, `/takeoff-mode`, and `/handoff-mode` belong to the other skills: do not write a file and do not print a mermaid-mode comment for them.

Enabling while `OUTLINE`, `TAKEOFF`, or `HANDOFF` exists swaps. Delete those sentinels, create `MERMAID`, keep every `NN-*.md`, and continue that index. The next substantive reply uses mermaid-mode’s shape.

Chat is only:

    [mermaid-mode] <enabled|disabled|created a file|limit reached>
    <absolute $DIR>
    [<absolute new file, write turns only>]
    [mmdc is not installed]

On `/mermaid-mode`, run `command -v mmdc`. If it is missing, append that last line after `$DIR`. If `mmdc` is on `PATH`, omit the line. Toggle still proceeds.

Off → on: mkdir `$DIR` if needed, create `MERMAID`, keep existing `NN-*.md`. If `OUTLINE`, `TAKEOFF`, or `HANDOFF` is present, delete it first (swap).
On → off: delete `MERMAID` only.

While `MERMAID` exists, each substantive query writes exactly one new `$DIR/<NN>-<slug>.md` (never edit prior files, including ones outline-mode, takeoff-mode, or handoff-mode wrote). `NN` = count of `[0-9][0-9]-*.md` + 1, two digits. Slug is kebab-case from the H1. At 100: write nothing, comment `limit reached`, tell the user to start a new conversation.

    # <5-10 word summary>

    ## Response

    <the full chat reply>

    ## Mermaid

    <the printed mermaid graph>

    ## <5-10 word title>

    <full section body>

    ## ...

Include Response and Mermaid only when that section has content. Omit the heading when it would be empty. Add further `##` sections when the reply has distinct topics those two do not cover. As many `##` sections as the reply needs. Each extra title is 5–10 words.

The H1 starts the file (no blank line before it). Blank line after every heading, including `#`. Blank line before every `##`.

## Printed graph

`## Mermaid` is the rendered diagram, never the source that would render it. The output file must not contain ` ```mermaid ` fences, `:::mermaid` blocks, `.mmd` listings, mermaid.ink URLs, or raw mermaid syntax. Draft mermaid only in a temp file outside `$DIR`.

Print with this skill’s `scripts/print-graph` (stdin: mermaid source; stdout: cropped SVG). Embed that SVG inline under `## Mermaid`. Do not leave the temp source, artefact `.svg`, or `mmdc` markdown image refs (`![diagram](./…svg)`) in `$DIR`. `$DIR` gains only the new `NN-*.md`.

Tighten layout. Mermaid’s defaults pad too much — `print-graph` already applies `scripts/config.json` and crops the SVG to its content box. Do not wrap the graph in extra blockquotes, tables, or padded HTML. Prefer the smallest diagram type that answers the prompt.

Skip the file for toggle/cap acks and trivial one-liners ("Yes", "Done", tool-only). Anything substantive still writes a file.
