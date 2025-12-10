#!/usr/bin/env python3
"""
Migration: Fix Lowercase approval_status Values
Date: 2025-12-11

This migration fixes a data inconsistency where some users have lowercase 'approved'
instead of uppercase 'APPROVED' in the approval_status column.

The registration management system expects uppercase enum values:
- APPROVED (not 'approved')
- PENDING (not 'pending')
- CLOSED_REGISTRATION (not 'closed_registration')
- REJECTED (not 'rejected')

This script normalizes all approval_status values to uppercase.

Usage:
    python migrations/fix_lowercase_approval_status.py
"""

import sys
import os
import asyncio
import logging

# Add parent directory to path for imports
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from sqlalchemy import text
from db import get_db_session, session_commit, session_execute

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


async def run_migration():
    """Execute the approval_status normalization migration."""
    logger.info("=" * 60)
    logger.info("FIX LOWERCASE APPROVAL_STATUS MIGRATION")
    logger.info("=" * 60)
    logger.info("")

    async with get_db_session() as session:
        try:
            # Step 1: Check current state
            logger.info("Step 1: Analyzing current approval_status values...")

            result = await session_execute(
                text("""
                    SELECT
                        approval_status,
                        COUNT(*) as count
                    FROM users
                    GROUP BY approval_status
                    ORDER BY count DESC
                """),
                session
            )
            status_counts = result.fetchall()

            logger.info("📊 Current approval_status distribution:")
            total_users = 0
            needs_fix = 0
            for status, count in status_counts:
                total_users += count
                is_lowercase = status and status != status.upper()
                marker = "⚠️ " if is_lowercase else "✅"
                logger.info(f"  {marker} '{status}': {count} users")
                if is_lowercase:
                    needs_fix += count

            logger.info(f"\n📊 Total: {total_users} users, {needs_fix} need fixing")
            logger.info("")

            if needs_fix == 0:
                logger.info("✅ All approval_status values are already correct!")
                logger.info("=" * 60)
                return

            # Step 2: Normalize to uppercase
            logger.info("Step 2: Normalizing approval_status values to uppercase...")

            # Use UPPER() function to normalize all values
            result = await session_execute(
                text("""
                    UPDATE users
                    SET approval_status = UPPER(approval_status)
                    WHERE approval_status != UPPER(approval_status)
                """),
                session
            )

            # Get the actual row count (SQLite3 specific)
            fixed_count = result.rowcount if hasattr(result, 'rowcount') else needs_fix
            logger.info(f"✅ Fixed {fixed_count} users")
            logger.info("")

            # Step 3: Verify fix
            logger.info("Step 3: Verifying migration...")

            result = await session_execute(
                text("""
                    SELECT
                        approval_status,
                        COUNT(*) as count
                    FROM users
                    GROUP BY approval_status
                    ORDER BY count DESC
                """),
                session
            )
            new_status_counts = result.fetchall()

            logger.info("📊 New approval_status distribution:")
            all_uppercase = True
            for status, count in new_status_counts:
                is_uppercase = status == status.upper()
                marker = "✅" if is_uppercase else "❌"
                logger.info(f"  {marker} '{status}': {count} users")
                if not is_uppercase:
                    all_uppercase = False

            if not all_uppercase:
                raise Exception("Verification failed: Still found lowercase values!")

            # Step 4: Commit transaction
            await session_commit(session)
            logger.info("")
            logger.info("✅ Transaction committed")
            logger.info("")
            logger.info("=" * 60)
            logger.info("MIGRATION COMPLETE!")
            logger.info("=" * 60)
            logger.info("")
            logger.info("Summary:")
            logger.info(f"  • Normalized {fixed_count} approval_status values to uppercase")
            logger.info(f"  • Total users: {total_users}")
            logger.info(f"  • All values now conform to ApprovalStatus enum")
            logger.info("")
            logger.info("Valid approval_status values (uppercase):")
            logger.info("  • APPROVED - User can access shop")
            logger.info("  • PENDING - Waiting for admin approval")
            logger.info("  • CLOSED_REGISTRATION - On waitlist")
            logger.info("  • REJECTED - Registration denied")
            logger.info("")

        except Exception as e:
            logger.error(f"❌ Migration failed: {e}", exc_info=True)
            await session.rollback()
            raise


if __name__ == "__main__":
    try:
        asyncio.run(run_migration())
        sys.exit(0)
    except KeyboardInterrupt:
        logger.info("\n❌ Migration cancelled by user")
        sys.exit(1)
    except Exception as e:
        logger.error(f"❌ Migration failed: {e}")
        sys.exit(1)
