"""add oilseeds table, rework crop_calendars to reference oilseed

Revision ID: ffd745b0fbe3
Revises: 01121ba72dc9
Create Date: 2026-07-31 15:48:53.651744

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'ffd745b0fbe3'
down_revision: Union[str, Sequence[str], None] = '01121ba72dc9'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.create_table('oilseeds',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('land_id', sa.Integer(), nullable=False),
    sa.Column('crop', sa.Enum('GROUNDNUT', 'SOYBEAN', 'SESAME', 'MUSTARD', 'SUNFLOWER', 'CASTOR', 'SAFFLOWER', 'LINSEED', 'NIGER', name='oilseed_planting_crop'), nullable=False),
    sa.Column('sowing_date', sa.Date(), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
    sa.ForeignKeyConstraint(['land_id'], ['lands.id'], ),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_oilseeds_land_id', 'oilseeds', ['land_id'], unique=False)

    # crop_calendars had no farmer data yet (dev-only table introduced this same
    # session) — drop and recreate with the new shape rather than a column-by-column
    # ALTER, since SQLite batch mode can't drop the old unnamed FK constraint.
    op.drop_table('crop_calendars')
    op.create_table('crop_calendars',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('oilseed_id', sa.Integer(), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
    sa.ForeignKeyConstraint(['oilseed_id'], ['oilseeds.id'], ),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_crop_calendars_oilseed_id', 'crop_calendars', ['oilseed_id'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index('ix_crop_calendars_oilseed_id', table_name='crop_calendars')
    op.drop_table('crop_calendars')

    op.create_table('crop_calendars',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('land_id', sa.Integer(), nullable=False),
    sa.Column('crop', sa.Enum('GROUNDNUT', 'SOYBEAN', 'SESAME', 'MUSTARD', 'SUNFLOWER', 'CASTOR', 'SAFFLOWER', 'LINSEED', 'NIGER', name='crop_calendar_crop'), nullable=False),
    sa.Column('sowing_date', sa.Date(), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
    sa.ForeignKeyConstraint(['land_id'], ['lands.id'], ),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_crop_calendars_land_id', 'crop_calendars', ['land_id'], unique=False)

    op.drop_index('ix_oilseeds_land_id', table_name='oilseeds')
    op.drop_table('oilseeds')
