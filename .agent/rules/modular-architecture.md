---
description: Enforce modular architecture where main is an orchestrator only
---

# Modular Architecture Rule

## Core Principle
The `main` entry point (e.g., `main.py`, `index.ts`, `app.py`) should act as an **orchestrator only**, delegating all logic to feature-specific modules.

## Requirements

### Main File Restrictions
- **MUST** only contain imports and function calls
- **MUST NOT** contain business logic, utility functions, or class definitions
- **SHOULD** read like a high-level recipe of the application

### Module Organization
```
project/
├── main.py                 # Orchestrator only
├── features/
│   ├── auth/              # Authentication feature
│   ├── users/             # User management
│   └── payments/          # Payment processing
├── shared/
│   ├── utils/             # Shared utilities
│   └── constants/         # Shared constants
└── infrastructure/        # External service integrations
```

### Example Main File (Python)
```python
"""Application entry point - orchestrator only."""
from features.auth import initialize_auth
from features.api import create_api_routes
from infrastructure.database import connect_database

def main():
    db = connect_database()
    auth = initialize_auth(db)
    app = create_api_routes(auth)
    app.run()

if __name__ == "__main__":
    main()
```

## Violations to Flag
1. Business logic in main file
2. Helper functions defined in main
3. Class definitions in main
4. More than 50 lines in main file (excluding imports)
