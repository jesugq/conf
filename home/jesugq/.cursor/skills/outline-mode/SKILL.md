---
name: outline-mode
description: >-
  Toggle a per-conversation "outline mode" that hides full responses behind a
  numbered outline (~20 visible lines) and expands each section on demand when
  the user replies with `<LETTER><NUMBER>`. Triggered only by the exact
  commands `/outline-mode start`, `/outline-mode stop`, `/outline-mode clear`,
  and `/outline-mode purge`.
disable-model-invocation: true
---

# Outline mode

## Subcommands

Each subcommand replies with a single line of confirmation and nothing else. Let `$CID = $CURSOR_CONVERSATION_ID` (refuse if unset) and `$ROOT = ~/.cursor/outline-mode`.

- `/outline-mode start` → `mkdir -p $ROOT/sessions/$CID && touch $ROOT/sessions/$CID/ACTIVE`. Reply: `outline-mode: started for this conversation.`
- `/outline-mode stop` → `rm -f $ROOT/sessions/$CID/ACTIVE`. Reply: `outline-mode: stopped for this conversation.` Response JSONs remain on disk.
- `/outline-mode clear` → this-session wipe: delete `$ROOT/sessions/$CID/response-*.json` and `latest.json`. Resets the letter counter to `A`; recovery path for the 26-letter limit. Reply: `outline-mode: cleared response JSONs for this conversation.`
- `/outline-mode purge` → global purge: delete `$ROOT/sessions/*/response-*.json` and `$ROOT/sessions/*/latest.json` across all sessions. Reply: `outline-mode: purged response JSONs across all sessions.`

Any other `/outline-mode ...` message → one-line usage summary listing the four subcommands.

## Response workflow (while `$ROOT/sessions/$CID/ACTIVE` exists)

1. Compose the full response internally. Split into 3–7 sections, each with a 5–10 word title.
2. Assign this response's letter: count existing `$ROOT/sessions/$CID/response-*.json` files as `N`. If `N < 26`, letter = `chr(ord('A') + N)`. If `N >= 26`, write nothing and reply inline with exactly:

   ```
   outline-mode: 26 letters (A–Z) exhausted for this conversation. Please run `/outline-mode clear` (this-conversation reset) or start a new conversation to continue.
   ```

3. Write `$ROOT/sessions/$CID/response-<LETTER>-<UTC-ISO>-<slug>.json` and mirror it to `latest.json`. Schema: `{created_at, letter, user_query_summary, outline: ["<LETTER>0 - Title", ...], sections: {"1": "...", "2": "..."}}`. Letter lives only at the top level; section keys stay as bare numbers; `outline` entries embed the letter prefix.
4. Reply with ONLY the outline block (≤ 20 lines, one entry per line).

## Handling follow-up input

- `<LETTER><NUMBER>` (case-insensitive, e.g. `A2`, `i0`) → glob `$ROOT/sessions/$CID/response-<LETTER>-*.json`, print `sections["<NUMBER>"]` in full, then append that response's outline for re-navigation. Works across responses: typing `A2` from outline `I0` still resolves to A's section 2.
- `<LETTER>` alone or `<LETTER>0` → print only that response's outline.
- Unknown letter, missing section, or missing `latest.json` → one-line apology + reprint latest outline (or say none exists).
- Anything else → treat as a new query and run the response workflow.

## Bypass

Reply inline (no outline) for short answers, tool output, or `/outline-mode` subcommand acknowledgements.
