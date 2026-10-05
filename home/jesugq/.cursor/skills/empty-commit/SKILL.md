---
name: empty-commit
description: Run with `/empty-commit <commit name>`. Adds one empty commit whose message is `[ISSUE-ID] <commit name>`. The issue id comes from the branch. Hooks do not run.
disable-model-invocation: true
---

# Empty commit

`/empty-commit <commit name>` adds one commit and stops. The words after `/empty-commit` are the commit name. Do not push. Do not amend. Do not run it twice.

The commit is purely aesthetic and must functionally do nothing but add a commit. Do not call Linear. Do not invent a commit name. The subject is `[ISSUE-ID] <commit name>`:

- Branch matches `^(?:feature/)?(?<issue_id>[a-zA-Z0-9]+-[0-9]+)(?:-.*)?$`. The `feature/` prefix is optional. Anything after the issue id is ignored. Any other name does not match, including `main`.
- Uppercase the issue id. Use the user's commit name exactly as given.
- On `feature/sp-23-add-new-feature`, `/empty-commit Add new feature` → `[SP-23] Add new feature`.

If the user did not provide a commit name, stop. Do not create a commit.

If the branch does not match, stop. Say it doesn't match `<issue-id>`, quote the branch, and do not create a commit.

The commit is empty: no changes. Its tree is `HEAD^{tree}`. When HEAD does not exist yet, its tree is the empty tree `4b825dc642cb6eb9a060e54bf8d69288fbee4904`. `--skip-verify`: hooks must not run. Do not invoke `git commit`, so pre-commit and commit-msg hooks never run.

Do not touch, in any way shape or form, the contents in the staging area. Do not touch the working tree. These are forbidden, including as a fallback or a check: `git add`, `git restore`, `git checkout`, `git switch`, `git rm`, `git mv`, `git stash`, `git update-index`, `git read-tree`, `git apply`, `git commit` (every flag, including `--allow-empty`, `--only`, `--no-verify`, and `--skip-verify`), `sp commit`, `git reset` without `--soft`, `git status`, `git diff`, and `git diff --cached`. `git status` and `git diff` can rewrite the index. `git commit --allow-empty` still records whatever is staged and rewrites the index file.

The only git writes are inside this skill's `scripts/empty-commit`: `git commit-tree` (new commit object only) and `git reset --soft` (moves HEAD; does not touch the index file or the working tree). Do not check the staging area.

Run that script from the repository that should receive the commit. Do not `cd` to the skill directory. Pass the commit name as its only argument.

```
ruby <this skill dir>/scripts/empty-commit "<commit name>"
```

If the script fails, stop. Do not repair it with another git command.

Chat is only:

```
[empty-commit] <sha>
<message>
```

Omit the sha and message lines when no commit was created. On failure, print the script error, then stop.
