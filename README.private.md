# Private Repository Configuration

⚠️ **THIS FILE ONLY IN ORIGIN-PRIVATE** - Contains private setup information

## Git Dual-Remote Setup

### Configure Remotes

```bash
# Public GitHub repository
git remote add origin git@github.com-6R1M5L07H:6R1M5L07H/ShopForge.git

# Private server
git remote add origin-private dev-gituser@pausenhalle.de:/opt/git/telegram_shop_forge.git

# Verify
git remote -v
```

### Git Aliases for Dual-Remote Management

Create/extend `~/.gitconfig` with these aliases:

```ini
[alias]
    # Push to both remotes (only for open-source code!)
    pushboth = "!f() { \
        echo '⚠️  WARNING: This pushes to PUBLIC origin!' && \
        read -p 'Confirm no enterprise/VPN features? (yes/no): ' confirm && \
        [ \"$confirm\" = \"yes\" ] && \
        echo '🔄 Pushing to origin...' && \
        git push origin \"$@\" && \
        echo '🔄 Pushing to origin-private...' && \
        git push origin-private \"$@\" && \
        echo '✅ Successfully pushed to both remotes'; \
    }; f"

    # Push ONLY to origin-private (for Enterprise features)
    pushprivate = "!f() { \
        echo '🔒 Pushing ONLY to origin-private (enterprise features)...' && \
        git push origin-private \"$@\" && \
        echo '✅ Successfully pushed to origin-private'; \
    }; f"

    # Push develop branch to both remotes
    pushdevelop = "!git checkout develop && git pushboth develop"

    # Force-push to both (with warning!)
    forceboth = "!f() { \
        echo '⚠️  WARNING: Force push to PUBLIC origin!' && \
        read -p 'Confirm no enterprise/VPN features? (yes/no): ' confirm && \
        [ \"$confirm\" = \"yes\" ] && \
        git push origin \"$@\" --force-with-lease && \
        git push origin-private \"$@\" --force-with-lease; \
    }; f"

    # Sync-Check: Show differences between remotes
    synccheck = "!f() { \
        branch=\"${1:-$(git rev-parse --abbrev-ref HEAD)}\"; \
        git fetch origin && git fetch origin-private && \
        echo '📊 Commits in origin but not in origin-private:' && \
        git log origin-private/$branch..origin/$branch --oneline && \
        echo '' && \
        echo '📊 Commits in origin-private but not in origin:' && \
        git log origin/$branch..origin-private/$branch --oneline; \
    }; f"
```

### Quick Setup Script

```bash
#!/bin/bash
# setup-git-config.sh

cat >> ~/.gitconfig << 'EOF'

[alias]
    pushboth = "!f() { echo '⚠️  WARNING: This pushes to PUBLIC origin!' && read -p 'Confirm no enterprise/VPN features? (yes/no): ' confirm && [ \"$confirm\" = \"yes\" ] && echo '🔄 Pushing to origin...' && git push origin \"$@\" && echo '🔄 Pushing to origin-private...' && git push origin-private \"$@\" && echo '✅ Successfully pushed to both remotes'; }; f"
    pushprivate = "!f() { echo '🔒 Pushing ONLY to origin-private (enterprise features)...' && git push origin-private \"$@\" && echo '✅ Successfully pushed to origin-private'; }; f"
    pushdevelop = "!git checkout develop && git pushboth develop"
    forceboth = "!f() { echo '⚠️  WARNING: Force push to PUBLIC origin!' && read -p 'Confirm no enterprise/VPN features? (yes/no): ' confirm && [ \"$confirm\" = \"yes\" ] && git push origin \"$@\" --force-with-lease && git push origin-private \"$@\" --force-with-lease; }; f"
    synccheck = "!f() { branch=\"${1:-$(git rev-parse --abbrev-ref HEAD)}\"; git fetch origin && git fetch origin-private && echo '📊 Commits in origin but not in origin-private:' && git log origin-private/$branch..origin/$branch --oneline && echo '' && echo '📊 Commits in origin-private but not in origin:' && git log origin/$branch..origin-private/$branch --oneline; }; f"
EOF

echo "✅ Git aliases added to ~/.gitconfig"
```

## Workflow

### Open-Source Features (to both remotes)

```bash
git checkout -b feature/new-thing develop
# ... development ...
git add .
git commit -m "feat: add new thing"
git pushboth feature/new-thing
```

### Enterprise Features (ONLY origin-private)

```bash
git checkout -b enterprise/vpn-feature develop
# ... development ...
git add .
git commit -m "feat(enterprise): add VPN integration"
git pushprivate enterprise/vpn-feature
```

### Synchronize develop

```bash
# Check if clean (no enterprise features)
git log origin/develop..develop

# If clean:
git pushdevelop
```

### Check sync status

```bash
git synccheck develop
```

## Enterprise Features Isolation

### ⛔ NEVER push to origin (GitHub):
- VPN features (`enterprise/vpn-*`, `vpn/*` branches)
- Anonymization features
- Proprietary logic
- Internal tools (e.g., `tools/test_vpn_anonymity.sh`)
- **Any file with `vpn` in the name**:
  - `.env.vpn.template`
  - `docker-compose.vpn.yml`
  - `docs/vpn-setup.md`
  - etc.

### ✅ OK to push to origin (PUBLIC GitHub):
- `.env.template` (generic template without secrets)
- `.env.production` (template with placeholder values)
- `docker-compose.template.yml` (generic Docker setup)
- `docker-compose.production.yml` (generic production setup, no VPN)
- All open-source features

### 🔒 Only push to origin-private:
- All `enterprise/*` branches
- All `vpn/*` branches
- `README.private.md` (this file)
- `.env.vpn.template`
- `docker-compose.vpn.yml`
- `tools/test_vpn_anonymity.sh`
- Any VPN-related documentation

### 🚫 NEVER commit to ANY repo (local/server only):
- `.env` (with real secrets)
- `.env.local`
- `.env.vpn` (with real VPN credentials)
- Any file with actual API keys, passwords, or tokens

## File Naming Convention

To avoid accidents, follow these rules:

| File Pattern | Public (origin) | Private (origin-private) | Never Commit |
|--------------|----------------|--------------------------|--------------|
| `*.template` | ✅ YES | ✅ YES | ❌ |
| `*vpn*` | ⛔ NO | ✅ YES | ❌ |
| `.env` (no suffix) | ⛔ NO | ⛔ NO | ✅ YES |
| `.env.production` | ✅ YES (template) | ✅ YES | ❌ |
| `.env.vpn*` | ⛔ NO | ✅ YES (template) | ✅ YES (actual) |
| `docker-compose.yml` | ✅ YES (generic) | ✅ YES | ❌ |
| `docker-compose.vpn.yml` | ⛔ NO | ✅ YES | ❌ |

## Accident Prevention

If enterprise code accidentally pushed to origin:

```bash
# IMMEDIATELY overwrite with clean version
git push origin <branch> --force-with-lease

# Or delete entire branch
git push origin --delete <branch>

# Check GitHub history and rotate repository secrets if needed
```

### Pre-Push Checklist

Before pushing to origin (GitHub), verify:
- [ ] No files with `vpn` in name
- [ ] No enterprise feature code
- [ ] No internal tool references
- [ ] No proprietary configuration keys
- [ ] Branch is NOT `enterprise/*` or `vpn/*`

## Server-Specific Configuration

### Private Server (pausenhalle.de)
- Host: `dev-gituser@pausenhalle.de`
- Repo path: `/opt/git/telegram_shop_forge.git`
- SSH key: Use separate deploy key for server

### SSH Config (~/.ssh/config)

```
Host pausenhalle.de
    User dev-gituser
    IdentityFile ~/.ssh/id_rsa_pausenhalle
    StrictHostKeyChecking no
```

## .gitignore Strategy

Ensure these patterns are in `.gitignore`:

```gitignore
# Never commit actual secrets
.env
.env.local
.env.vpn

# But allow templates
!.env.template
!.env.production
!.env.vpn.template
```

**Note**: Templates with `vpn` in the name should still only go to origin-private, even though they're committed to git.
