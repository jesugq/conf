# User-wide agent instructions

## Outline mode auto-activation

At the start of every conversation, unconditionally:

1. Load and follow `~/.cursor/skills/outline-mode/SKILL.md` for the rest of the
   conversation, treating it as if the user had just typed `/outline-mode start`
   (create `$DIR/ACTIVE` where
   `$DIR = ~/.cursor/outline-mode/sessions/$CURSOR_CONVERSATION_ID`).
   If `CURSOR_CONVERSATION_ID` is unset, skip activation silently.
2. On your first reply of the conversation, prepend a single notification line
   exactly:

       [outline-mode] activated

   Place it above the outline's `[major]` tag line. Do not emit this notice on
   any subsequent reply.

No sentinel/gate file is consulted — activation is always on.
