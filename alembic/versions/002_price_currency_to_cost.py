"""Replace price/currency with cost string column

Revision ID: 002
Revises: 001
Create Date: 2026-03-04

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa

revision: str = "002"
down_revision: Union[str, None] = "001"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.add_column("events", sa.Column("cost", sa.String(200), nullable=True))

    op.execute(
        "UPDATE events SET cost = "
        "CASE WHEN price IS NOT NULL THEN "
        "COALESCE(currency, 'USD') || ' ' || CAST(price AS TEXT) "
        "ELSE NULL END"
    )

    op.drop_column("events", "price")
    op.drop_column("events", "currency")


def downgrade() -> None:
    op.add_column(
        "events",
        sa.Column("price", sa.Numeric(10, 2), nullable=True),
    )
    op.add_column(
        "events",
        sa.Column("currency", sa.String(3), nullable=True),
    )
    op.drop_column("events", "cost")
