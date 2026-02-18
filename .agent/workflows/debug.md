---
description: Systematic debugging with ladder of discipline - /debug command
---

# Systematic Debugging Workflow

Trigger this workflow with `/debug` when encountering bugs, errors, or unexpected behavior.

## The Ladder of Discipline

### Step 1: Check Project Memory
// turbo
```
Read ISSUES_LOG.md if it exists to check for:
- Recurring patterns matching current symptoms
- Previous fixes for similar issues
- Known gotchas in this area of code
```

### Step 2: Establish Baseline
Compare the failing state against a known working state:
1. What was the last working version?
2. What changed between then and now?
3. Can the issue be reproduced consistently?

**Gather evidence:**
- Error messages (exact text)
- Stack traces
- Relevant log entries
- Environment differences

### Step 3: Isolate the Problem
Narrow the scope systematically:
1. Is it environment-specific? (dev vs prod, OS, browser)
2. Is it data-specific? (certain inputs trigger it)
3. Is it timing-specific? (race conditions, timeouts)
4. Is it dependency-specific? (version conflicts)

### Step 4: Form Hypothesis
State a clear, testable hypothesis:
```
"I believe [X] is happening because [Y], and if I [Z], the issue should be resolved."
```

### Step 5: Propose Minimal Fix
Create the smallest possible code change:
- One logical change per fix
- Preserve existing behavior
- Add regression test

### Step 6: Document Resolution
Update `ISSUES_LOG.md` with:
```markdown
## [Date] - [Brief Title]

**Symptoms:** [What was observed]

**Root Cause:** [Why it happened]

**Failed Attempts:** [What didn't work and why]

**Solution:** [The fix applied]

**Prevention:** [How to avoid in future]
```

## Emergency Shortcuts
- If production is down: Skip to Step 5, document later
- If regression: Git bisect to find breaking commit
- If third-party issue: Check their status page / changelog
