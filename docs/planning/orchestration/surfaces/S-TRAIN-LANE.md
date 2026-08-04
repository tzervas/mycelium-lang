# S-TRAIN-LANE

**Owning repo:** `tzervas/ap-workflows`  
**Package:** `PKG-CI-TRUTH` (https://github.com/tzervas/mycelium-lang/issues/48)  
**Status:** FROZEN (mycelium-lang PR #49, merged 2026-08-04)

## Proposed signature

```rust
NEW file .github/workflows/reusable-train-lane.yml (the missing AGENT-PIPELINE.md deliverable, table row: 'Validate package JSON + comment hub'). workflow_call inputs: package-path (string, required — path to a docs/planning/orchestration/packages/*.json in the calling repo), schema-url (string, default the raw URL of mycelium-lang's work-package.schema.json at a pinned ref — no floating `main` fetch of a schema that could change under a running validation), hub-token (secrets: pass-through app-token for cross-repo issue comments, reusing the existing .github/actions/app-token pattern already in this repo), post-comment (boolean, default true). Job `validate`: fetch schema at the pinned ref, validate package-path against it (required fields per schema: id,title,wp,priority,status,hub_issue,goal,non_goals,surfaces,lanes,blocked_by,unblocks,success_criteria,adversarial_checklist,kickoff_prompt), exit non-zero + ::error on any missing/malformed field (never-silent, matching this repo's own posture). Job `comment-hub` (needs: validate, if: post-comment): posts/updates a single identifiable comment (HTML marker for idempotent update) on the issue named by the package's `hub_issue` field with the validation result.
```

## Rationale

This is the one AGENT-PIPELINE deliverable still missing (confirmed absent: `find .github -iname '*train-lane*'` in ap-workflows returns nothing). Caller lives in mycelium-lang (new .github/workflows/train-lane.yml, on push touching docs/planning/orchestration/packages/**), not in ap-workflows itself — ap-workflows only owns the reusable definition, per the one-repo-per-lane rule.

## Freeze contract

Once frozen, this signature may not be renamed or widened by an implementer lane. A lane that
needs a change must stop and raise it on the package hub — silent divergence here is what the
zipper methodology exists to prevent.
