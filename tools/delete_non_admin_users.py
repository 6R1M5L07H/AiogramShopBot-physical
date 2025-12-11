#!/usr/bin/env python3
"""
User Deletion Tool with Admin Protection

This script safely deletes non-admin users from the database with comprehensive
safety checks and cascade handling.

Features:
- Admin protection: Never deletes users in ADMIN_ID_LIST
- Optional filtering: Delete specific users by telegram_id or username
- Safety confirmations: Multiple prompts before deletion
- Cascade deletion: Handles all related data (orders, cart, deposits, etc.)
- Dry-run mode: Preview what would be deleted without making changes

Usage:
    # Delete ALL non-admin users (with safety prompts)
    python tools/delete_non_admin_users.py --all

    # Delete specific users by telegram_id
    python tools/delete_non_admin_users.py --telegram-id 123456789 987654321

    # Delete specific users by username
    python tools/delete_non_admin_users.py --username john_doe jane_smith

    # Dry-run mode (preview only)
    python tools/delete_non_admin_users.py --all --dry-run

    # Skip confirmation prompts (DANGEROUS!)
    python tools/delete_non_admin_users.py --all --yes
"""

import sys
import asyncio
import argparse
from pathlib import Path
from typing import List

# Add project root to path
project_root = Path(__file__).parent.parent
sys.path.insert(0, str(project_root))

import config
from db import get_db_session, session_execute, session_commit
from sqlalchemy import text, delete, select, func, or_, update
from models.user import User
from models.cart import Cart
from models.order import Order
from models.deposit import Deposit
from models.user_strike import UserStrike
from models.referral_usage import ReferralUsage
from models.referral_discount import ReferralDiscount


def get_admin_ids() -> List[int]:
    """Get list of admin IDs from config (these users are PROTECTED)"""
    return config.ADMIN_ID_LIST


async def get_users_to_delete(
    session,
    telegram_ids: List[int] = None,
    usernames: List[str] = None,
    delete_all: bool = False
) -> List[tuple]:
    """
    Get list of users to delete with admin protection.

    Returns: List of (id, telegram_id, telegram_username, is_admin) tuples
    """
    admin_ids = get_admin_ids()

    if delete_all:
        # Get ALL non-admin users using SQLAlchemy ORM (works with sync and async)
        stmt = select(User.id, User.telegram_id, User.telegram_username).where(
            User.telegram_id.not_in(admin_ids)
        ).order_by(User.id)
        result = await session_execute(stmt, session)
        users = [(row[0], row[1], row[2], False) for row in result.fetchall()]

    elif telegram_ids:
        # Get specific users by telegram_id using SQLAlchemy ORM
        stmt = select(User.id, User.telegram_id, User.telegram_username).where(
            User.telegram_id.in_(telegram_ids)
        ).order_by(User.id)
        result = await session_execute(stmt, session)
        users = []
        for row in result.fetchall():
            is_admin = row[1] in admin_ids
            users.append((row[0], row[1], row[2], is_admin))

    elif usernames:
        # Get specific users by username using SQLAlchemy ORM
        stmt = select(User.id, User.telegram_id, User.telegram_username).where(
            User.telegram_username.in_(usernames)
        ).order_by(User.id)
        result = await session_execute(stmt, session)
        users = []
        for row in result.fetchall():
            is_admin = row[1] in admin_ids
            users.append((row[0], row[1], row[2], is_admin))

    else:
        users = []

    return users


async def get_user_data_stats(session, user_id: int) -> dict:
    """Get statistics about user's related data (for cascade preview)"""
    stats = {}

    # Orders - use SQLAlchemy ORM
    stmt = select(func.count()).select_from(Order).where(Order.user_id == user_id)
    result = await session_execute(stmt, session)
    stats['orders'] = result.scalar() or 0

    # Cart items - use SQLAlchemy ORM
    stmt = select(func.count()).select_from(Cart).where(Cart.user_id == user_id)
    result = await session_execute(stmt, session)
    stats['cart_items'] = result.scalar() or 0

    # Deposits - use SQLAlchemy ORM
    stmt = select(func.count()).select_from(Deposit).where(Deposit.user_id == user_id)
    result = await session_execute(stmt, session)
    stats['deposits'] = result.scalar() or 0

    # Strikes - use SQLAlchemy ORM
    stmt = select(func.count()).select_from(UserStrike).where(UserStrike.user_id == user_id)
    result = await session_execute(stmt, session)
    stats['strikes'] = result.scalar() or 0

    # Referrals given - use SQLAlchemy ORM
    stmt = select(func.count()).select_from(User).where(User.referred_by_user_id == user_id)
    result = await session_execute(stmt, session)
    stats['referrals_given'] = result.scalar() or 0

    # Referral usages - use SQLAlchemy ORM
    stmt = select(func.count()).select_from(ReferralUsage).where(
        or_(
            ReferralUsage.used_by_user_id == user_id,
            ReferralUsage.referral_owner_user_id == user_id
        )
    )
    result = await session_execute(stmt, session)
    stats['referral_usages'] = result.scalar() or 0

    return stats


async def delete_user_cascade(session, user_id: int, dry_run: bool = False) -> dict:
    """
    Delete user and ALL related data (CASCADE).

    Returns: Dict with deletion counts per table
    """
    counts = {}

    if dry_run:
        print(f"  [DRY-RUN] Would delete user {user_id} and related data")
        return await get_user_data_stats(session, user_id)

    # Delete related data first (to avoid foreign key violations)
    # Use SQLAlchemy ORM for dual-mode compatibility

    # 1. Cart items
    stmt = delete(Cart).where(Cart.user_id == user_id)
    result = await session_execute(stmt, session)
    counts['cart_items'] = result.rowcount

    # 2. Orders (and related buyItems via CASCADE)
    stmt = delete(Order).where(Order.user_id == user_id)
    result = await session_execute(stmt, session)
    counts['orders'] = result.rowcount

    # 3. Deposits
    stmt = delete(Deposit).where(Deposit.user_id == user_id)
    result = await session_execute(stmt, session)
    counts['deposits'] = result.rowcount

    # 4. User strikes
    stmt = delete(UserStrike).where(UserStrike.user_id == user_id)
    result = await session_execute(stmt, session)
    counts['strikes'] = result.rowcount

    # 5. Referral usages
    stmt = delete(ReferralUsage).where(
        or_(
            ReferralUsage.used_by_user_id == user_id,
            ReferralUsage.referral_owner_user_id == user_id
        )
    )
    result = await session_execute(stmt, session)
    counts['referral_usages'] = result.rowcount

    # 6. Referral discounts
    stmt = delete(ReferralDiscount).where(ReferralDiscount.user_id == user_id)
    result = await session_execute(stmt, session)
    counts['referral_discounts'] = result.rowcount

    # 7. Update referred_by_user_id for users who were referred by this user
    stmt = update(User).where(User.referred_by_user_id == user_id).values(referred_by_user_id=None)
    result = await session_execute(stmt, session)
    counts['referrals_updated'] = result.rowcount

    # 8. Finally, delete the user
    stmt = delete(User).where(User.id == user_id)
    result = await session_execute(stmt, session)
    counts['user'] = result.rowcount

    return counts


def print_user_summary(users: List[tuple]):
    """Print summary of users to be deleted"""
    print("\n" + "=" * 70)
    print("USERS TO DELETE")
    print("=" * 70)

    admin_users = [u for u in users if u[3]]  # u[3] = is_admin
    non_admin_users = [u for u in users if not u[3]]

    if non_admin_users:
        print(f"\n✅ Non-Admin Users ({len(non_admin_users)}):")
        for user_id, telegram_id, username, _ in non_admin_users:
            username_str = f"@{username}" if username else "(no username)"
            print(f"  • User #{user_id}: {username_str} (telegram_id: {telegram_id})")

    if admin_users:
        print(f"\n⚠️  PROTECTED Admin Users ({len(admin_users)}) - WILL NOT BE DELETED:")
        for user_id, telegram_id, username, _ in admin_users:
            username_str = f"@{username}" if username else "(no username)"
            print(f"  • User #{user_id}: {username_str} (telegram_id: {telegram_id}) 🛡️")

    print("\n" + "=" * 70)


async def preview_deletion_impact(session, users: List[tuple]):
    """Show what data will be deleted (cascade preview)"""
    print("\n" + "=" * 70)
    print("DELETION IMPACT (CASCADE PREVIEW)")
    print("=" * 70)

    total_stats = {
        'orders': 0,
        'cart_items': 0,
        'deposits': 0,
        'strikes': 0,
        'referrals_given': 0,
        'referral_usages': 0
    }

    non_admin_users = [u for u in users if not u[3]]

    for user_id, telegram_id, username, _ in non_admin_users:
        stats = await get_user_data_stats(session, user_id)
        username_str = f"@{username}" if username else "(no username)"

        print(f"\nUser #{user_id} ({username_str}):")
        print(f"  • Orders: {stats['orders']}")
        print(f"  • Cart items: {stats['cart_items']}")
        print(f"  • Deposits: {stats['deposits']}")
        print(f"  • Strikes: {stats['strikes']}")
        print(f"  • Referrals given: {stats['referrals_given']}")
        print(f"  • Referral usages: {stats['referral_usages']}")

        for key in total_stats:
            total_stats[key] += stats[key]

    print("\n" + "-" * 70)
    print("TOTAL IMPACT:")
    print(f"  • Users to delete: {len(non_admin_users)}")
    print(f"  • Orders to delete: {total_stats['orders']}")
    print(f"  • Cart items to delete: {total_stats['cart_items']}")
    print(f"  • Deposits to delete: {total_stats['deposits']}")
    print(f"  • Strikes to delete: {total_stats['strikes']}")
    print(f"  • Referral links to break: {total_stats['referrals_given']}")
    print(f"  • Referral usages to delete: {total_stats['referral_usages']}")
    print("=" * 70)


def confirm_deletion(skip_confirmation: bool = False) -> bool:
    """Ask user for confirmation before deletion"""
    if skip_confirmation:
        return True

    print("\n⚠️  WARNING: This action CANNOT be undone!")
    print("All user data and related records will be PERMANENTLY deleted.\n")

    response = input("Type 'DELETE' (in uppercase) to confirm: ")
    return response == "DELETE"


async def main():
    parser = argparse.ArgumentParser(
        description="Delete non-admin users with safety checks and cascade handling",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )

    # Selection mode
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--all', action='store_true', help='Delete ALL non-admin users')
    group.add_argument('--telegram-id', nargs='+', type=int, help='Delete users by telegram_id')
    group.add_argument('--username', nargs='+', help='Delete users by username')

    # Options
    parser.add_argument('--dry-run', action='store_true', help='Preview only, do not delete')
    parser.add_argument('--yes', action='store_true', help='Skip confirmation prompts (DANGEROUS!)')

    args = parser.parse_args()

    print("=" * 70)
    print("USER DELETION TOOL")
    print("=" * 70)
    print(f"\nAdmin IDs (PROTECTED): {config.ADMIN_ID_LIST}")

    if args.dry_run:
        print("\n🔍 DRY-RUN MODE: No changes will be made\n")

    async with get_db_session() as session:
        try:
            # Step 1: Get users to delete
            print("\nStep 1: Identifying users...")
            users = await get_users_to_delete(
                session,
                telegram_ids=args.telegram_id,
                usernames=args.username,
                delete_all=args.all
            )

            if not users:
                print("\n✅ No users found matching criteria.")
                return

            # Step 2: Print summary
            print_user_summary(users)

            # Filter out admin users
            non_admin_users = [u for u in users if not u[3]]
            admin_users = [u for u in users if u[3]]

            if admin_users:
                print(f"\n⚠️  Skipping {len(admin_users)} admin user(s) - they are PROTECTED!")

            if not non_admin_users:
                print("\n✅ No non-admin users to delete.")
                return

            # Step 3: Preview deletion impact
            print("\nStep 2: Analyzing deletion impact...")
            await preview_deletion_impact(session, users)

            # Step 4: Confirmation
            if not args.dry_run:
                if not confirm_deletion(args.yes):
                    print("\n❌ Deletion cancelled by user.")
                    return

            # Step 5: Delete users
            print("\nStep 3: Deleting users...")
            total_deleted = 0

            for user_id, telegram_id, username, is_admin in non_admin_users:
                if is_admin:
                    continue

                username_str = f"@{username}" if username else "(no username)"
                print(f"\n  Deleting user #{user_id} ({username_str})...")

                counts = await delete_user_cascade(session, user_id, dry_run=args.dry_run)

                if not args.dry_run:
                    print(f"    ✅ Deleted:")
                    print(f"       • User: {counts.get('user', 0)}")
                    print(f"       • Orders: {counts.get('orders', 0)}")
                    print(f"       • Cart items: {counts.get('cart_items', 0)}")
                    print(f"       • Deposits: {counts.get('deposits', 0)}")
                    print(f"       • Strikes: {counts.get('strikes', 0)}")
                    print(f"       • Referral usages: {counts.get('referral_usages', 0)}")
                    print(f"       • Referral links updated: {counts.get('referrals_updated', 0)}")
                    total_deleted += 1

            # Step 6: Commit
            if not args.dry_run:
                await session_commit(session)
                print("\n" + "=" * 70)
                print("DELETION COMPLETE")
                print("=" * 70)
                print(f"\n✅ Successfully deleted {total_deleted} user(s) and all related data.")
            else:
                print("\n" + "=" * 70)
                print("DRY-RUN COMPLETE")
                print("=" * 70)
                print("\n✅ No changes were made (dry-run mode).")
                print("Run without --dry-run to perform actual deletion.")

        except Exception as e:
            print(f"\n❌ Error: {e}")
            import traceback
            traceback.print_exc()
            await session.rollback()
            sys.exit(1)


if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("\n\n❌ Deletion cancelled by user (Ctrl+C)")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Fatal error: {e}")
        sys.exit(1)
