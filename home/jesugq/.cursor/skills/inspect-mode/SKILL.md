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
    - <path>: <post-edit line ranges>

    ## Commands
    ```
    <assertion commands actually run>
    ```

Changes: one bullet per written/edited/deleted/renamed file this round (not reads). Relative paths unless the round spans repos. Empty if none. New: `path (new): 1-N`. Deleted: `path (deleted)`. Rename: `old → new: <locations>`.

Commands: tests, lints, typechecks, builds — not discovery, edits, or git used only for Changes. Last run only. Prefix `cd <dir> &&` if not from the init cwd. Empty fence if none.

Skip the file for toggle/cap acks and trivial one-liners ("Yes", "Done", tool-only). Anything substantive still writes a file.
