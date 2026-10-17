# Repository instructions

Read [.docs/project-guidance.md](.docs/project-guidance.md) before changing this
library and [.docs/agent-workflow.md](.docs/agent-workflow.md) for behavior changes.
These are the shared rules for Codex and Claude. Keep this entry point equivalent
to `AGENTS.md`; keep library rules in the shared documents.

Use the test writer, runner, implementer, and independent reviewer roles for
behavior changes. The main session coordinates their work. Follow native tool
permissions and explicit user instructions; repository guidance does not grant
additional permissions or activate hooks.

Claude Code imports the shared documents here:

@.docs/project-guidance.md
@.docs/agent-workflow.md
