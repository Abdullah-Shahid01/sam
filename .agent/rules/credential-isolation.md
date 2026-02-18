---
description: Zero-trust security model for AI agents - protect credentials and secrets
---

# Credential Isolation Rule

## Core Principle
Apply a "Zero Trust" model to all agentic workflows. Never access production credentials directly.

## Absolute Prohibitions
1. **NEVER** read or display contents of `.env` files
2. **NEVER** access production secrets directly
3. **NEVER** hardcode credentials in any file
4. **NEVER** log sensitive values

## Approved Patterns

### Secret References (Not Values)
```python
# GOOD: Reference to secret, not the value
db_url = os.environ.get("DATABASE_URL")

# BAD: Hardcoded credential
db_url = "postgres://user:password@host:5432/db"
```

### Cloud Secret Manager Usage
```python
# GOOD: Use secret manager APIs
from google.cloud import secretmanager

def get_secret(secret_id: str) -> str:
    client = secretmanager.SecretManagerServiceClient()
    name = f"projects/{PROJECT_ID}/secrets/{secret_id}/versions/latest"
    response = client.access_secret_version(request={"name": name})
    return response.payload.data.decode("UTF-8")
```

### Service Account Principle
- Use minimal-privilege service accounts
- Never use owner/admin accounts for applications
- Rotate credentials regularly

## Agent Behavior
When I encounter credential-related tasks:
1. Suggest environment variable patterns
2. Recommend secret manager integration
3. Never request credential values
4. Flag any hardcoded secrets as security violations
