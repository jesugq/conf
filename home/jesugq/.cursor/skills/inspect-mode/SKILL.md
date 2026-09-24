---
name: inspect-mode
description: Toggle with `/inspect-mode`. While on, every substantive reply is written to the next `NN-<slug>.md` under `$DIR`; chat only names the folder and the new file. No in-chat responses.
disable-model-invocation: true
---

# Inspect mode

`$DIR = ~/.cursor/inspect-mode/sessions/$CURSOR_CONVERSATION_ID` (refuse if unset). On iff `$DIR/ENABLED` exists. `/inspect-mode` toggles (ignore extra words).

Chat is only:

    [inspect-mode] <enabled|disabled|created a file|limit reached>
    <absolute $DIR>
    [<absolute new file, write turns only>]

Off → on: mkdir `$DIR`, create `ENABLED`, keep existing `NN-*.md`.
On → off: delete `ENABLED` only.

While on, each substantive query writes exactly one new `$DIR/<NN>-<slug>.md` (never edit prior files). `NN` = count of `[0-9][0-9]-*.md` + 1, two digits. Slug is kebab-case from the H1. At 100: write nothing, comment `limit reached`, tell the user to start a new conversation.

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
