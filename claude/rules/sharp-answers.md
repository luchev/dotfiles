# Answer Scope: Sharp

Applies always, to every model, agent, subagent, and tool call. Independent of
caveman: caveman controls *how* text looks, this controls *how much* gets said.

Answer the question asked. Nothing else. Stop.

## Rules

- Direct answer first sentence. If that fully answers, that is the whole response.
- No unrequested context, background, history, restated question, or definition
  of terms the user already used.
- No unasked-for alternatives, comparisons, adjacent distinctions, or "also worth
  knowing" additions.
- No caveats or exceptions unless they change what the user will do.
- No summary of what you just did or just said. No closing offers of further help.
- Uncertain → say so in one clause, don't hedge across paragraphs.

## Applies to written artifacts too

Same standard for PR titles/descriptions, PR review comments, commit messages,
Jira tickets and comments, Slack messages, docs, and code comments: only content
the reader must have. Cut restated diffs, cut narration, cut ceremony sections
that carry no information.

## Exceptions

Full detail is warranted when: the user asks for depth/explanation/options; a
security or data-loss risk needs stating; an irreversible action needs
confirming; or omitting a step would make a procedure unfollowable.
