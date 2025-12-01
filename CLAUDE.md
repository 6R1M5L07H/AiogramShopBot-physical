# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AiogramShopBot is a Telegram shop bot built with Aiogram3 and SQLAlchemy for automated sales of digital and physical goods with cryptocurrency payment support (Bitcoin, Litecoin, Solana, Ethereum, BNB).

## Development Commands

### Running the Bot

**First-Time Setup:**
```bash
# Copy template files (only needed once)
cp docker-compose.dev.yml.template docker-compose.dev.yml
cp docker-compose.prod.yml.template docker-compose.prod.yml
cp .env.dev.template .env  # or .env.prod.template for production
```

**Local Development (Redis only):**
```bash
# Start Redis in Docker
docker-compose -f docker-compose.dev.yml up -d

# Run bot locally (separate terminal)
python run.py
```

**Production Deployment:**
```bash
# Start all services (bot + Redis + Caddy)
docker-compose -f docker-compose.prod.yml up -d
```

**Production Deployment with VPN (Anonymous Operation):**
```bash
# Prerequisites:
# 1. Get AirVPN credentials from https://airvpn.org/
# 2. Download OpenVPN config from https://airvpn.org/generator/
# 3. Save config as ./vpn/airvpn.conf
# 4. Copy environment template: cp .env.prod-vpn.template .env
# 5. Fill in AIRVPN_USERNAME and AIRVPN_PASSWORD in .env

# Start all services (bot + Redis + Gluetun VPN + external Caddy)
docker-compose -f docker-compose.prod-vpn.yml up -d

# Check VPN connection
docker-compose -f docker-compose.prod-vpn.yml exec gluetun wget -qO- https://api.ipify.org

# Get forwarded port for webhooks
docker-compose -f docker-compose.prod-vpn.yml exec gluetun cat /tmp/gluetun/forwarded_port
```

**Development with VPN:**
```bash
# Prerequisites: Same as production VPN setup above
# Copy environment template: cp .env.dev-vpn.template .env

# Start development environment with VPN
docker-compose -f docker-compose.dev-vpn.yml up -d

# Check VPN status
docker-compose -f docker-compose.dev-vpn.yml logs -f gluetun
```

**Important Notes:**
- Docker Compose files (`docker-compose.{dev,prod}.yml`) are gitignored - only templates are committed
- This prevents local customizations from being overwritten during git operations
- On this machine, you must never start ngrok.
- VPN setup routes ALL bot API traffic through AirVPN (Telegram sees only VPN IP)
- Port forwarding is automatically configured by AirVPN for webhook reception
- See `vpn/README.md` for detailed VPN setup instructions

### Testing
```bash
# Run safe tests (no database mutations)
python tests/run_safe_tests.py

# Manual test simulations
python tests/payment/manual/simulate_payment_webhook.py
python tests/cart/manual/simulate_stock_race_condition.py
```

### Database
- SQLite with optional SQLCipher encryption
- Migrations in `migrations/` directory
- Database file stored in `data/` directory (gitignored)

## Architecture

### Layered Architecture Pattern

The codebase follows a strict 4-layer architecture:

**1. Handlers Layer** (`handlers/`)
- User-facing handlers: `handlers/user/` (cart, order, profile, shipping)
- Admin-facing handlers: `handlers/admin/` (inventory, user management, shipping management, statistics)
- FSM states defined in separate `*_states.py` files
- Handlers use callback-based navigation with numbered levels (level 0, 1, 2, etc.)

**2. Services Layer** (`services/`)
- Business logic and orchestration
- Service classes contain static methods (no instance state)
- Key services: `OrderService`, `PaymentService`, `CartService`, `NotificationService`
- Services call repositories and handle complex workflows

**3. Repositories Layer** (`repositories/`)
- Database access layer (CRUD operations only)
- Repository classes contain static async methods
- Each repository corresponds to one model (e.g., `ItemRepository` → `Item`)
- NO business logic in repositories

**4. Models Layer** (`models/`)
- SQLAlchemy ORM models (database tables)
- DTOs for data transfer between layers
- Models inherit from `Base` (defined in `models/base.py`)

### Key Architectural Rules

1. **Data Flow**: Handlers → Services → Repositories → Models
2. **Never skip layers**: Handlers should NOT call repositories directly
3. **Dual Session Support**: All repository/service methods accept `AsyncSession | Session` for optional SQLCipher support
4. **FSM for Multi-Step Flows**: Use Aiogram FSM states for user input workflows (e.g., address collection, admin order cancellation)

### Navigation System

Callback-based navigation uses numbered levels:
```python
# Example from OrderCallback
level=0  # Create order
level=1  # Show order details
level=2  # Re-enter shipping address
level=3  # Payment processing
level=4  # Cancel order (confirmation)
level=5  # Execute cancellation
```

Each handler has a navigation router that maps levels to functions.

### Critical Workflows

**Order Flow**:
1. Cart → Order Creation (reserve items)
2. Shipping Address (if physical items)
3. Payment Processing (wallet + crypto)
4. Order Completion (mark items sold, create Buy records)

**Payment Flow**:
- Wallet balance used first
- Remaining amount via cryptocurrency (KryptoExpress API)
- Webhook handles payment confirmations
- Underpayment retry logic (one retry, then penalty)
- Late payment penalty (5% default)

**Strike System**:
- 3 strikes = automatic ban (configurable)
- Strike triggers: late order cancellation, payment timeout
- Admins exempt from bans (configurable)
- Unban via wallet top-up threshold

**Data Retention**:
- Shipping addresses deleted after 30 days (GDPR compliance)
- Referral data retained 365 days
- Automated cleanup job in `jobs/data_retention_cleanup_job.py`

## Important Patterns

### Session Management
```python
# Always use db.session_* wrappers for dual mode support
from db import session_commit, session_execute, session_flush

await session_commit(session)  # Works for both async and sync
```

### Invoice/Order System
- Orders have timeout (30 min default)
- Grace period for free cancellation (5 min default)
- Stock reservation during order creation
- Stock restoration on cancellation

### Localization
- Translations in `l10n/de.json` and `l10n/en.json`
- Access via `Localizator.get_text(BotEntity.USER, "key")`
- Three entity types: USER, ADMIN, COMMON

### Notification System
- User notifications via `NotificationService.send_to_user()`
- Admin notifications via `NotificationService.send_to_admins()`
- Build message strings BEFORE database mutations for transactional safety

## Configuration

Environment variables in `.env` (see `.env.template`):
- `RUNTIME_ENVIRONMENT`: "dev" (ngrok) or "prod" (Caddy reverse proxy)
- `DB_ENCRYPTION`: Enable SQLCipher ("true"/"false")
- Payment config: timeouts, penalties, retry logic
- Strike system config: max strikes, admin exemption, unban amount

## Code Style

- German for user-facing messages in conversations with user
- English for code, docstrings, commit messages
- No Claude references in any commits or code
- Functional descriptions in changelogs (user-focused benefits)
- Professional, concise commit messages without emojis

## Testing Strategy

- Unit tests in `tests/*/unit/`
- Manual test scripts in `tests/*/manual/`
- Safe tests run without database mutations
- Use `test_config_patch.py` for test environment setup

## Lessons Learned - Security & Code Quality

### Security Best Practices

**1. Config Validation: Fail-Fast at Startup**
- Critical secrets must be validated before bot starts
- Use `utils/config_validator.py` pattern for startup validation
- Never use empty string defaults for secrets (e.g., `os.getenv('SECRET', '')`)
- Provide clear error messages with generation commands

**2. HTML Injection Prevention**
- Always escape user-controllable data before HTML rendering
- Use `utils/html_escape.safe_html()` for all user input in messages
- Audit locations: usernames, shipping addresses, custom reasons, ban reasons
- Test with malicious input: `<script>`, `</b><a href="evil">`, etc.

**3. Development Security**
- Use HTTPS even in dev environments (ngrok with `bind_tls=True`)
- Separate `.env.dev.template` and `.env.prod.template` with secure defaults
- Never log secrets (use `LOG_MASK_SECRETS=true`)

**4. Admin Security: Defense-in-Depth**
- Use hash-based admin verification alongside plaintext IDs
- Document design decisions (see `docs/security/ADMIN_SECURITY_CLARIFICATION.md`)
- Remember: Telegram API requires plaintext IDs for notifications

**5. Rate Limiting is Mandatory**
- Implement rate limiting for all user-facing operations
- Use Redis-based tracking with configurable limits
- Pattern: `RateLimitOperation` enum for type-safe operation names

### Code Quality Best Practices

**6. Eliminate Code Duplication Immediately**
- Duplication >3 locations = refactor required
- Example: Invoice formatting reduced from 546→194 lines (64%)
- Benefits: Single source of truth, bugs fixed once

**7. Strict Layered Architecture**
- Always follow: Handler → Service → Repository → Database
- Never skip layers (handlers calling repositories directly)
- Services contain business logic, handlers manage UI/routing
- Repositories only do CRUD, no business logic

**8. Function Length Limits**
- Functions >100 lines must be split into helpers
- Extract clear, focused helper functions with descriptive names
- Main function shows high-level flow, helpers implement details
- Example: `create_order()` reduced from 133→67 lines (50%)

**9. N+1 Query Prevention**
- Always use `selectinload()` for relationships
- Implement eager loading in repositories, not services
- Example: 201→4 queries (98% reduction) for 100 orders
- Test with production-size data to catch N+1 issues

**10. Consistent Error Handling**
- Services: Raise custom exceptions (from `exceptions/`)
- Handlers: Catch and show localized user messages
- Repositories: Let SQLAlchemy exceptions bubble up
- Use `utils/error_handler.py` for centralized handling

**11. No Magic Strings**
- Convert string literals to Enums when used as "types"
- Example: `"order_create"` → `RateLimitOperation.ORDER_CREATE`
- Benefits: Type safety, IDE autocomplete, refactoring safety

**12. Floating-Point Precision in Finance**
- Never use direct float comparisons for money/crypto
- Use `normalize_crypto_amount()` with configurable precision
- BTC: 8 decimals, ETH: 18 decimals, configurable via env vars

**13. SQL Logging Configuration**
- Only log SQL queries in DEBUG mode (`LOG_LEVEL=DEBUG`)
- Use conditional `echo=sql_echo` in SQLAlchemy engine
- Keep production logs clean for error debugging

**14. No Side-Effects at Import Time**
- Never execute side-effects during module import
- Use explicit initialization functions (e.g., `initialize_webhook_config()`)
- Enables safe imports in tests without triggering network calls

**15. Singleton Pattern for Shared Resources**
- Use singleton for Bot, DB Engine, Redis connections
- Prevents multiple sessions and resource waste
- Example: `bot_instance.py` with `get_bot()` function

**16. Environment-Specific Configuration**
- Maintain separate templates: `.env.dev.template`, `.env.prod.template`
- Dev: Relaxed limits, DEBUG logging, no encryption
- Prod: Strict security, INFO logging, backups enabled

**17. Localization from Day One**
- All user-facing strings in `l10n/*.json` files
- Use `Localizator.get_text(BotEntity.USER, "key")` everywhere
- Never hardcode text in German or English in code

**18. Test Before Refactoring**
- Write comprehensive test suite before major refactors
- Verify all tests pass before and after changes
- Gives confidence that behavior is preserved

**19. Dual-Mode Database Pattern (CRITICAL)**
- **ALWAYS use `db.py` wrapper functions for ALL database operations**
- Never use direct `await session.execute()` - use `await session_execute(stmt, session)`
- Never use direct `await session.commit()` - use `await session_commit(session)`
- Never use direct `await session.flush()` - use `await session_flush(session)`
- **Why?** The codebase supports two modes:
  - AsyncSession (default, no encryption)
  - Session (SQLCipher encrypted mode)
- Wrappers handle both modes transparently with `isinstance()` checks
- **Applies to:** Repositories (mandatory), Services, Jobs, Tests
- **Exception:** Migration scripts can use direct calls (they create own engines)
- **Verification:** Check original ilyarolf code - it uses wrappers consistently
- **Impact:** Code breaking SQLCipher mode discovered during test implementation

### Quick Reference Checklist for New Features

**Security:**
- [ ] User input escaped (HTML, SQL, Command Injection)
- [ ] Secrets validated at startup (>32 chars)
- [ ] HTTPS in dev and prod
- [ ] Rate limiting implemented

**Code Quality:**
- [ ] Layered architecture (Handler→Service→Repo)
- [ ] No code duplication (>3 = refactor)
- [ ] Functions <100 lines
- [ ] No N+1 queries (eager loading)
- [ ] Custom exceptions (no `return None`)
- [ ] Enums instead of magic strings
- [ ] DB operations use `session_execute/commit/flush` wrappers (not direct calls)

**Testing:**
- [ ] Unit tests for services
- [ ] Integration tests for flows
- [ ] Security tests for user input
- [ ] Manual test checklist documented

**Documentation:**
- [ ] Design decisions documented
- [ ] `.env.template` updated
- [ ] README updated if needed
- [ ] Localization keys added

## Custom Commands

Use `/finalize` to complete a feature branch:
1. Updates CHANGELOG.md
2. Moves TODO to done/
3. Creates professional commit message
4. Verifies no Claude references
5. Squashes commits
6. Creates PR on develop
7. Cleans up branches post-merge
- TODOs werden erst in Done verschieben, wenn der User die Freigabe gegeben hat
- sei mit emojis sparsam. Messages in Telegram können mit Emojis aufgelockert werden, aber in technische Dokus und Commit-Messages, Pull Requests oder changelog-einträgen haben die nichts verloren
- bitte nicht jeden Satz mit "Perfekt!" beginnen - das nervt tierisch
- hör auf mit diesem "Perfekt!" Quatsch zu Beginn eines jeden Satzes.
- lokale tests dürfen durchgeführt werden, solange ngrok nicht gestartet wird. Es darf auf dieser Maschine kein Docker-Prozess für dieses Projekt gestartet werden. Tests werden auf einer separaten Testmaschine gemacht.
- programmieren und dokumentieren auf englisch, kommunizieren mit dem user auf deutsch
- keine direkten Pushes auf Develop, außer, der User ordnet es so an; Develop-branch ist an das Hauptverzeichnis gebunden; feature branches sind an working trees gebunden und leben nur so lange, wie der branch existiert
- kein push direkt auf develop - immer über PR!