"""Add unique constraint on (agent_id, title, start_at, lat, lng) to prevent duplicate events

Revision ID: 003
Revises: 002
Create Date: 2026-03-05

"""
from typing import Sequence, Union

from alembic import op

revision: str = "003"
down_revision: Union[str, None] = "002"
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    op.create_unique_constraint(
        "uq_event_natural_key",
        "events",
        ["agent_id", "title", "start_at", "lat", "lng"],
    )


def downgrade() -> None:
    op.drop_constraint("uq_event_natural_key", "events", type_="unique")
