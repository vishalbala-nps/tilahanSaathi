"""Admin CLI for viewing and editing government_schemes rows without a code deploy.

Usage (run from the api/ directory):
    uv run python scripts/manage_schemes.py list
    uv run python scripts/manage_schemes.py show pm_kisan
    uv run python scripts/manage_schemes.py add --slug new_scheme --name "..." \\
        --description "..." --eligibility-summary "..." --key-benefit "..." \\
        --url "https://..." --state central
    uv run python scripts/manage_schemes.py update pm_kisan --key-benefit "..."
    uv run python scripts/manage_schemes.py activate pm_kisan
    uv run python scripts/manage_schemes.py deactivate pm_kisan
"""

import argparse
import asyncio
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from sqlalchemy import select

from app.db.session import async_session_maker
from app.models.scheme import GovernmentSchemeInfo


async def list_schemes() -> None:
    async with async_session_maker() as db:
        result = await db.execute(select(GovernmentSchemeInfo).order_by(GovernmentSchemeInfo.slug))
        schemes = result.scalars().all()
        if not schemes:
            print("No schemes in the database yet.")
            return
        for scheme in schemes:
            active = "active" if scheme.is_active else "inactive"
            print(f"{scheme.slug:20} | {scheme.state:15} | {active:8} | {scheme.name}")


async def show_scheme(slug: str) -> None:
    async with async_session_maker() as db:
        scheme = await _get_scheme(db, slug)
        print(f"slug:                {scheme.slug}")
        print(f"name:                {scheme.name}")
        print(f"state:               {scheme.state}")
        print(f"active:              {scheme.is_active}")
        print(f"description:         {scheme.description}")
        print(f"eligibility_summary: {scheme.eligibility_summary}")
        print(f"key_benefit:         {scheme.key_benefit}")
        print(f"url:                 {scheme.url}")
        print(f"updated_at:          {scheme.updated_at}")


async def add_scheme(args: argparse.Namespace) -> None:
    async with async_session_maker() as db:
        existing = await db.execute(
            select(GovernmentSchemeInfo).where(GovernmentSchemeInfo.slug == args.slug)
        )
        if existing.scalar_one_or_none() is not None:
            print(f"Scheme '{args.slug}' already exists. Use 'update' instead.")
            return
        scheme = GovernmentSchemeInfo(
            slug=args.slug,
            name=args.name,
            description=args.description,
            eligibility_summary=args.eligibility_summary,
            key_benefit=args.key_benefit,
            url=args.url,
            state=args.state,
            is_active=True,
        )
        db.add(scheme)
        await db.commit()
        print(f"Added scheme '{args.slug}'.")


async def update_scheme(args: argparse.Namespace) -> None:
    async with async_session_maker() as db:
        scheme = await _get_scheme(db, args.slug)
        if args.name is not None:
            scheme.name = args.name
        if args.description is not None:
            scheme.description = args.description
        if args.eligibility_summary is not None:
            scheme.eligibility_summary = args.eligibility_summary
        if args.key_benefit is not None:
            scheme.key_benefit = args.key_benefit
        if args.url is not None:
            scheme.url = args.url
        if args.state is not None:
            scheme.state = args.state
        await db.commit()
        print(f"Updated scheme '{args.slug}'.")


async def set_active(slug: str, active: bool) -> None:
    async with async_session_maker() as db:
        scheme = await _get_scheme(db, slug)
        scheme.is_active = active
        await db.commit()
        print(f"{'Activated' if active else 'Deactivated'} scheme '{slug}'.")


async def _get_scheme(db, slug: str) -> GovernmentSchemeInfo:
    result = await db.execute(select(GovernmentSchemeInfo).where(GovernmentSchemeInfo.slug == slug))
    scheme = result.scalar_one_or_none()
    if scheme is None:
        print(f"No scheme found with slug '{slug}'.")
        raise SystemExit(1)
    return scheme


def main() -> None:
    parser = argparse.ArgumentParser(description="Manage government_schemes rows.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    subparsers.add_parser("list", help="List all schemes (slug, state, active, name).")

    show_parser = subparsers.add_parser("show", help="Show full details for one scheme.")
    show_parser.add_argument("slug")

    add_parser = subparsers.add_parser("add", help="Add a new scheme.")
    add_parser.add_argument("--slug", required=True)
    add_parser.add_argument("--name", required=True)
    add_parser.add_argument("--description", required=True)
    add_parser.add_argument("--eligibility-summary", required=True)
    add_parser.add_argument("--key-benefit", required=True)
    add_parser.add_argument("--url", default=None, help="Primary official scheme URL (optional)")
    add_parser.add_argument("--state", default="central", help='"central" or a specific state name')

    update_parser = subparsers.add_parser("update", help="Update fields on an existing scheme.")
    update_parser.add_argument("slug")
    update_parser.add_argument("--name")
    update_parser.add_argument("--description")
    update_parser.add_argument("--eligibility-summary")
    update_parser.add_argument("--key-benefit")
    update_parser.add_argument("--url")
    update_parser.add_argument("--state")

    activate_parser = subparsers.add_parser("activate", help="Mark a scheme active.")
    activate_parser.add_argument("slug")

    deactivate_parser = subparsers.add_parser("deactivate", help="Mark a scheme inactive.")
    deactivate_parser.add_argument("slug")

    args = parser.parse_args()

    if args.command == "list":
        asyncio.run(list_schemes())
    elif args.command == "show":
        asyncio.run(show_scheme(args.slug))
    elif args.command == "add":
        asyncio.run(add_scheme(args))
    elif args.command == "update":
        asyncio.run(update_scheme(args))
    elif args.command == "activate":
        asyncio.run(set_active(args.slug, True))
    elif args.command == "deactivate":
        asyncio.run(set_active(args.slug, False))


if __name__ == "__main__":
    main()
