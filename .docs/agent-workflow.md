# Library agent workflow

Adapted from the role separation in `push-button-deploy`. These instructions
apply to OrderedCollections; source-repository instructions are reference
material, not authority over this checkout.

## Behavior changes

Use one coordinating main session and delegate bounded work to these roles:

1. **Spec writer:** Own `test/**` and test fixtures. Translate the requested
   behavior into regression tests and meaningful doctest registrations. Do not
   edit production source. Source-embedded doctest edits belong to implementer.
2. **Runner:** Run the new tests against unchanged production code, save the
   actual failing output, and distinguish expected failures from environment
   problems. Own execution evidence; do not edit source or tests.
3. **Reviewer:** Independently inspect tests and red evidence before accepting
   the test contract. Check successful behavior and edge cases. Do not edit
   source or tests.
4. **Implementer:** Own `lib/**`, required build changes, and benchmark scripts.
   Implement the accepted behavior. Do not change accepted tests to accommodate
   defects; route test issues back to the spec writer and reviewer.
5. **Runner:** Run focused tests, full tests, formatting, and required checks.
   Record benchmark commands and results for performance changes.
6. **Reviewer:** Inspect the final diff and full evidence independently. Check
   public compatibility, protocol contracts, doctest execution, dead code, and
   performance claims. Route findings to the responsible owner and repeat checks.

The coordinator may edit guidance and reports but does not edit source or tests
in this pipeline. Documentation-only and configuration-only changes do not need
artificial failing tests; validate links/configuration and review the diff.
If native subagents are unavailable, report that limitation and use explicit
sequential roles; do not claim the review was independent.

## Coordination and evidence

Reuse role agents for follow-up work. Give each a compact handoff containing
expected behavior, owned paths, relevant guidance, validation commands, and
evidence paths. Prefer bounded context. Do not overlap writers on a file. Use
parallel work only when it does not bypass the red/test-acceptance/implementation
sequence. Use native completion events instead of repeated status polling.

Record accepted-test hashes before implementation; compare afterward. Only the
spec writer revises tests, with renewed reviewer acceptance if behavior changes.
Formatting must preserve assertions and be checked before refreshing hashes.
Explicit user instructions, including authorized replacement of obsolete tests,
take precedence; do not invent an additional approval step.

Keep complete commands and outputs in a task-specific temporary directory or
review artifact. Summaries point to that evidence and identify failures, skips,
pending checks, and environmental limits. Never fabricate output. Preserve a
reproducible benchmark script and concise measured report in the repository
when performance is part of the requested work.

## Native agent files

Role definitions live in `.codex/agents/*.toml` and `.claude/agents/*.md`.
They share this workflow and project guidance, inherit the session's model
selection, and do not grant tools or permissions. Use your platform's native
delegation tools; when named roles are unavailable, pass the role instructions
explicitly to a native subagent.

This adaptation installs instruction files only. It does not install hooks,
mutation auditing, model overrides, platform settings, or enforcement scripts.
Role ownership is an instruction contract, not a claim of filesystem isolation.
Do not bypass native sandbox restrictions or existing hooks. Validate native
agent discovery separately in each client; file syntax checks do not prove
that a running client has loaded new roles.

Codex custom-agent format reference:
https://learn.chatgpt.com/docs/agent-configuration/subagents
