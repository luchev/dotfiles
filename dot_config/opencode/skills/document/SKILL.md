---
name: document
description: >
  Generate comprehensive documentation: README, API docs, inline comments, ADRs, changelogs, guides.
  Use when code needs documentation or user wants docs generated.
  Trigger when user says "document this", "write docs", "create a README", "add docstrings",
  "document the API", "write a changelog", or "create an onboarding guide".
---

# Document Command

Generate clear documentation for code, APIs, and systems.

## When to Use

- Documenting a public API
- Creating or restructuring a README
- Recording an architecture decision
- Writing a changelog entry
- Adding docstrings
- Writing a guide or onboarding doc

## Step 1: Pick the type

Each type has its own template. Read only the one you need — they are separate
files so the rest stay out of context.

| Type | Read | When |
|---|---|---|
| README | [references/readme.md](references/readme.md) | Project entry point: what it is, install, quick start, usage |
| API docs | [references/api-docs.md](references/api-docs.md) | Endpoints, exported symbols, request/response shapes, errors |
| ADR | [references/adr.md](references/adr.md) | A decision with consequences worth recording — including alternatives rejected |
| Inline comments | [references/inline-comments.md](references/inline-comments.md) | Docstrings and in-code explanation |
| Changelog | [references/changelog.md](references/changelog.md) | Release notes, Keep a Changelog format |
| User guide | [references/user-guides.md](references/user-guides.md) | Task-oriented tutorial with steps and troubleshooting |

If the request does not map cleanly onto one, ask which before writing. Docs
written to the wrong shape get rewritten, not edited.

## Step 2: Read the code first

Documentation asserted from names and signatures is how wrong docs get written.
Read the implementation. Where behaviour differs from what the name suggests,
that difference is the most valuable line in the doc.

For anything with a runnable example: run it before including it. An example
that does not work is worse than no example, because it costs the reader their
trust and their afternoon.

## Step 3: Write

**Match the audience.** A README addresses someone who has never seen the
project. An ADR addresses a maintainer two years from now who is wondering why.
Same facts, different starting knowledge.

**Explain why, not what.** The code already says what. Docs earn their place by
carrying intent, constraints, and the reasoning that is not recoverable from
reading the source.

**Show expected output.** A command without its output leaves the reader unable
to tell success from failure.

**Cover the error paths.** Most doc failures are not wrong happy paths; they are
missing troubleshooting for the failure the reader actually hit.

**No walls of text.** Headings, short paragraphs, tables where the content is
tabular.

Avoid: assumed prior knowledge, vague description, partial examples, jargon
introduced without definition, and documenting implementation details that will
change.

## Step 4: Check before publishing

- [ ] Every code example was run and works
- [ ] Every link resolves
- [ ] Prerequisites stated
- [ ] Error scenarios and troubleshooting covered
- [ ] Version numbers and paths current
- [ ] Security notes where relevant
- [ ] Cross-references to related docs
- [ ] No stale content left from a prior version

## Maintenance

Update docs in the same change as the code, not afterwards — a separate docs
pass is a pass that does not happen. When behaviour changes, the affected doc is
part of the diff.

Track known gaps explicitly as a TODO list in the doc itself rather than leaving
them implicit. An acknowledged gap is a smaller problem than a confident
omission.

## After

- `/verify` — docs are one of its ten categories
- `/publish` — the PR description is documentation too
