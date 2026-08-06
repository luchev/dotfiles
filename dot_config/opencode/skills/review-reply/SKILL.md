---
name: review-reply
description: Receive and act on code review feedback — verify each item against the codebase before implementing, push back with technical reasoning when a suggestion is wrong, and reply in-thread. Use when review comments land on a PR or diff, when the user says "address the review", "respond to the reviewer", "the reviewer says X", or pastes review feedback. The counterpart to /review, which produces feedback.
---

# /review-reply — Act on Review Feedback

Review is a technical exchange. Evaluate, then implement. Do not perform agreement.

## The Loop

1. **Read** all feedback before reacting.
2. **Understand** each item — restate the requirement in your own words.
3. **Clarify** anything unclear *before* implementing anything.
4. **Verify** each item against the codebase.
5. **Decide** implement or push back.
6. **Implement** one item at a time, testing each.
7. **Reply** in-thread, per item.

## Step 3: Clarify First, Implement Nothing

If any item is unclear, stop and ask about that item before starting on the
others. Items are often related; a partial reading produces the wrong change.

```
❌ Implement 1,2,3,6 now, ask about 4,5 after
✅ "Understand 1,2,3,6. Need clarification on 4 and 5 before starting."
```

## Step 4: Verify Before Implementing

A reviewer sees the diff, not the codebase. Before acting on any item:

- Is it correct for *this* codebase, not the general case?
- Does it break existing behavior? (grep the callers)
- Is there a reason the current code is the way it is? (`git log -S`, blame)
- Does the reviewer have the context that motivated the current shape?

Cannot verify? Say so and ask: `"Can't verify this without <X> — investigate,
or proceed as suggested?"`

**YAGNI check.** When a reviewer asks for a feature to be "done properly",
grep for real usage first. Unused → propose deleting it instead of building it out.

## Step 5: Push Back When Warranted

Push back when the suggestion breaks behavior, misses context, violates
YAGNI, is wrong for this stack, exists for compatibility reasons, or
contradicts an architectural decision already made.

Push back with evidence — the failing case, the caller, the test, the commit
that introduced it. Not with defensiveness.

Escalate to the user rather than deciding alone when the item conflicts with
a decision they made.

## Step 6: Implementation Order

1. Blocking — breakage, security, data loss
2. Simple — typos, imports, naming
3. Complex — refactors, logic changes

Test each individually. Verify no regressions before moving on.

## Step 7: Replying

One reply per thread, at the comment it answers — not a top-level summary comment.

```bash
gh api repos/{owner}/{repo}/pulls/{pr}/comments/{comment_id}/replies \
  -f body='Fixed in <sha> — <what changed>.'
```

Content rules (these are the `sharp-answers` rules applied to review):

```
✅ "Fixed in a1b2c3d — moved the nil check above the deref."
✅ "Not changing this: <reason>, see <file:line>."
✅ "Can't verify without <X>. Investigate or proceed?"

❌ "You're absolutely right!"
❌ "Great point!" / "Good catch!" / "Thanks for catching that!"
❌ "Let me implement that now" (before verifying)
❌ Any gratitude expression
```

If you pushed back and were wrong, state it once and move on:
`"Checked — you're right, <X> does <Y>. Fixing."` No apology, no defense of
the pushback, no re-litigating.

## Common Mistakes

| Mistake | Fix |
|---|---|
| Performative agreement | State the requirement, or just act |
| Implementing before verifying | Check against the codebase first |
| Batching fixes, testing once at the end | One at a time, test each |
| Assuming the reviewer is right | Check whether it breaks something |
| Avoiding pushback to stay agreeable | Technical correctness beats comfort |
| Implementing the clear items, asking about the rest later | Clarify everything first |
| Can't verify, proceeding anyway | State the limitation, ask |
| Top-level comment summarizing all replies | Reply in each thread |
