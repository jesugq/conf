---
name: inspect-mode
description: Toggle with `/inspect-mode`. While on, every substantive reply is written to the next `NN-<slug>.md` under `$DIR`; chat only names the folder and the new file. No in-chat responses.
disable-model-invocation: true
---

# Inspect mode

Shared with outline-mode. `$NAME` is `<local YYYY-MM-DD>-<$CURSOR_CONVERSATION_ID>`: the date, one hyphen, then the conversation id, with no spaces. `$DIR = ~/.cursor/agent-mode/$NAME` (refuse if the conversation id is unset). Example: `~/.cursor/agent-mode/2026-09-24-<id>`. Both modes use this one folder and the same `NN-*.md` sequence. The date is the local calendar date at the start of the turn; the same day and conversation always resolve to the same `$DIR`.

On iff `$DIR/INSPECT` exists (zero-byte sentinel). `$DIR/OUTLINE` means outline-mode is on instead. Neither sentinel means off — a folder or leftover markdown alone is off. The two sentinels are mutually exclusive. `/inspect-mode` toggles this mode (ignore extra words). `/outline-mode` belongs to the other skill: do not write a file and do not print an inspect-mode comment for it.

Enabling while `OUTLINE` exists swaps. Delete `OUTLINE`, create `INSPECT`, keep every `NN-*.md`, and continue that index. The next substantive reply uses inspect-mode’s shape.

Chat is only:

    [inspect-mode] <enabled|disabled|created a file|limit reached>
    <absolute $DIR>
    [<absolute new file, write turns only>]

Off → on: mkdir `$DIR` if needed, create `INSPECT`, keep existing `NN-*.md`. If `OUTLINE` is present, delete it first (swap).
On → off: delete `INSPECT` only.

While `INSPECT` exists, each substantive query writes exactly one new `$DIR/<NN>-<slug>.md` (never edit prior files, including ones outline-mode wrote). `NN` = count of `[0-9][0-9]-*.md` + 1, two digits. Slug is kebab-case from the H1. At 100: write nothing, comment `limit reached`, tell the user to start a new conversation.

    # <5-10 word summary>

    ## Response

    <the full chat reply>

    ## Changes

    - <file>
      - <absolute path>
      - <path relative to the repository; omit a leading simplepractice/>
      - <comma-separated post-edit line ranges>

    ## Commands

    ```
    <assertion commands actually run>
    ```

    ## <5-10 word title>
    <full section body>

    ## ...

Include Response, Changes, and Commands only when that section has content. Omit the heading when it would be empty. Add further `##` sections when the reply has distinct topics those three do not cover. Up to seven `##` sections. Each extra title is 5–10 words.

Blank line before and after every heading except the H1, which starts the file. Changes: one parent bullet per written/edited/deleted/renamed file this round (not reads). Parent is the filename. Children, in order: absolute path, path relative to the repository (no `simplepractice/` prefix), then comma-separated line ranges (`10-21, 45-48`). New: filename `(new)`, ranges `1-N`. Deleted: filename `(deleted)`, no line child. Rename: `old → new` as the parent, then both paths and the new file’s ranges.

Commands: tests, lints, typechecks, builds — not discovery, edits, or git used only for Changes. Last run only. Prefix `cd <dir> &&` if not from the init cwd.

Skip the file for toggle/cap acks and trivial one-liners ("Yes", "Done", tool-only). Anything substantive still writes a file.
