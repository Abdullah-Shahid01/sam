---
description: Enforce coding standards (PEP 8, TypeScript Strict, docstrings with complexity)
---

# Code Style Rule

## Language-Specific Standards

### Python
- Follow **PEP 8** styling
- Use **type hints** for all function signatures
- Maximum line length: 88 characters (Black formatter)
- Use `snake_case` for variables/functions, `PascalCase` for classes

### TypeScript
- Enable **strict mode** in tsconfig
- Use ESLint with recommended rules
- Prefer `interface` over `type` for object shapes
- Use `camelCase` for variables/functions, `PascalCase` for classes/interfaces

### JavaScript
- Use ES6+ features (arrow functions, destructuring, async/await)
- Avoid `var`, prefer `const` > `let`

## Docstrings & Comments

### Required Docstring Format
Every function/method MUST include:
1. **Description**: What it does
2. **Args**: Parameters with types
3. **Returns**: Return value description
4. **Complexity**: Time and space complexity

### Example (Python)
```python
def find_duplicates(items: list[int]) -> list[int]:
    """
    Find duplicate values in a list.

    Args:
        items: List of integers to search

    Returns:
        List of integers that appear more than once

    Complexity:
        Time: O(n) - single pass with hash set
        Space: O(n) - storing seen items
    """
    seen = set()
    duplicates = []
    for item in items:
        if item in seen:
            duplicates.append(item)
        seen.add(item)
    return duplicates
```

## Import Organization
1. Standard library imports
2. Third-party imports
3. Local application imports
4. Blank line between each group
