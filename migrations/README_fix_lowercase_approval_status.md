# Migration: Fix Lowercase approval_status Values

## Problem
Some users have lowercase `'approved'` instead of uppercase `'APPROVED'` in the `approval_status` column.
The registration management system expects uppercase enum values.

## Solution
This migration normalizes all `approval_status` values to uppercase using the bot's DB connection logic.

## Usage on Production Server

### Step 1: Copy Migration Script to Server
```bash
# On local machine
scp migrations/fix_lowercase_approval_status.py root@v22017074787251509.quicksrv.de:/root/docker-setup/telegram_shop_forge/
```

### Step 2: Run Migration in Docker Container
```bash
# SSH to server
ssh root@v22017074787251509.quicksrv.de

# Navigate to docker setup
cd /root/docker-setup/telegram_shop_forge

# Run migration inside container
docker exec -it shopbot-prod-vpn python /bot/migrations/fix_lowercase_approval_status.py
```

### Step 3: Verify Results
The migration script will output:
- Current distribution of approval_status values
- Number of users that need fixing
- New distribution after fix
- Verification that all values are uppercase

## What the Migration Does

1. **Analyzes** current `approval_status` values and counts
2. **Normalizes** all lowercase values to uppercase using `UPPER()` SQL function
3. **Verifies** that all values are now uppercase
4. **Commits** the transaction

## Expected Output

```
============================================================
FIX LOWERCASE APPROVAL_STATUS MIGRATION
============================================================

Step 1: Analyzing current approval_status values...
📊 Current approval_status distribution:
  ⚠️  'approved': 42 users
  ✅ 'PENDING': 3 users

📊 Total: 45 users, 42 need fixing

Step 2: Normalizing approval_status values to uppercase...
✅ Fixed 42 users

Step 3: Verifying migration...
📊 New approval_status distribution:
  ✅ 'APPROVED': 42 users
  ✅ 'PENDING': 3 users

✅ Transaction committed

============================================================
MIGRATION COMPLETE!
============================================================

Summary:
  • Normalized 42 approval_status values to uppercase
  • Total users: 45
  • All values now conform to ApprovalStatus enum

Valid approval_status values (uppercase):
  • APPROVED - User can access shop
  • PENDING - Waiting for admin approval
  • CLOSED_REGISTRATION - On waitlist
  • REJECTED - Registration denied
```

## Safety Features

- **Read-only analysis first**: Shows what will be changed before making changes
- **Atomic transaction**: All changes committed together or rolled back on error
- **Verification step**: Checks all values are correct before committing
- **Uses bot's DB connection**: Same encryption/cipher settings as the bot
- **Rollback on error**: Database reverted to original state if anything fails

## Troubleshooting

### Error: "file is not a database"
- The script uses the bot's `db.py` connection logic, so this should NOT happen
- If it does: Check that `DB_PASS` in `.env` is correct

### Error: "No such column: approval_status"
- Run the main registration management migration first:
  ```bash
  docker exec -it shopbot-prod-vpn python /bot/migrations/add_registration_management.py
  ```

### Migration shows "0 need fixing"
- All values are already correct, no action needed

## Technical Details

- Uses `UPPER()` SQL function for case normalization
- Works with both encrypted (SQLCipher) and unencrypted SQLite databases
- Compatible with async and sync SQLAlchemy sessions
- Transaction-safe with automatic rollback on errors
