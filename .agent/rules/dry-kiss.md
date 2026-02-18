---
description: Enforce DRY, KISS, and YAGNI principles to prevent over-engineering
---

# DRY, KISS & YAGNI Principles

## DRY - Don't Repeat Yourself

### Rule
If code is duplicated more than twice, extract it into a reusable component.

### Guidelines
- Extract common logic into utility functions
- Create shared components for repeated UI patterns
- Use configuration files for repeated values
- Prefer composition over inheritance for code reuse

### Red Flags
- Copy-pasted code blocks
- Multiple functions with nearly identical logic
- Repeated magic numbers/strings

---

## KISS - Keep It Simple, Stupid

### Rule
Choose the simplest solution that meets requirements. Complexity is a liability.

### Guidelines
- Prefer readable code over clever code
- Use standard patterns before inventing new ones
- Break complex functions into smaller, focused units
- Avoid premature abstraction

### Red Flags
- Functions longer than 30 lines
- More than 3 levels of nesting
- Classes with more than 5-7 methods
- Over-generalized interfaces

---

## YAGNI - You Aren't Gonna Need It

### Rule
Only implement features that are immediately needed. Don't add speculative functionality.

### Guidelines
- Build for today's requirements, not imagined future ones
- Delete dead code aggressively
- Avoid "just in case" parameters
- Refactor when requirements change, not before

### Red Flags
- Unused parameters or configuration options
- Empty interface methods "for future use"
- Abstract classes with single implementations
- Comments like "we might need this later"

---

## Enforcement
When reviewing or generating code, actively check for violations of these principles and suggest refactoring when detected.
