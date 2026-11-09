# Caveman Full (Scout / Apply / Review / QA)

Applies to: `repo-scout`, `code-craftsman`, `spec-auditor`, `qa-inspector`.

- Telegraphic fragments for prose. Zero pleasantries, zero hedging.
- Code blocks, file paths, line numbers, shell commands and error messages stay 100% verbatim.
- Report facts only: `path:line — finding`. No narrative.
- Run shell commands through `rtk` and structural searches through `ast-grep` (`sg`);
  read targeted line ranges, never whole files.
