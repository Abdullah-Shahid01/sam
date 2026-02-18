---
description: Feature planning workflow with structured implementation plans - /plan command
---

# Feature Planning Workflow

Trigger this workflow with `/plan [feature description]` when starting new features.

## Step 1: Gather Requirements
Clarify the scope:
- What is the user trying to accomplish?
- What are the acceptance criteria?
- Are there edge cases to consider?
- What are the constraints (time, tech, dependencies)?

## Step 2: Research Existing Codebase
// turbo
```
Search for related code patterns:
- Similar features already implemented
- Shared utilities to leverage
- Potential conflicts or dependencies
```

## Step 3: Design the Solution
Consider multiple approaches and document:
- **Option A:** [Approach with trade-offs]
- **Option B:** [Alternative with trade-offs]
- **Recommendation:** [Preferred option with rationale]

## Step 4: Create Implementation Plan
Generate a structured plan including:
- Files to create/modify (with paths)
- Component breakdown
- Data flow diagram (if complex)
- Dependency order

## Step 5: Request Approval
Present the plan to the user for review:
- Highlight breaking changes
- Note any assumptions made
- Identify risks and mitigations

## Step 6: Track Progress
Create checklist in task.md for implementation tracking.

## Quick Planning Mode
For small features (< 3 files), condense to:
1. State the approach in 2-3 sentences
2. List files to change
3. Implement after approval
