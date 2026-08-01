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
    # ALTER. crop_calendar_activities.calendar_id has a real FK constraint pointing
    # at it (Postgres enforces this and blocks the drop; SQLite doesn't check FKs
    # by default so this went unnoticed there) — drop and recreate that table too,
    # unchanged in shape, so its FK points at the new crop_calendars.
    op.drop_index('ix_crop_calendar_activities_calendar_id', table_name='crop_calendar_activities')
    op.drop_table('crop_calendar_activities')
    op.drop_table('crop_calendars')
    op.create_table('crop_calendars',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('oilseed_id', sa.Integer(), nullable=False),
    sa.Column('created_at', sa.DateTime(timezone=True), server_default=sa.text('(CURRENT_TIMESTAMP)'), nullable=False),
    sa.ForeignKeyConstraint(['oilseed_id'], ['oilseeds.id'], ),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_crop_calendars_oilseed_id', 'crop_calendars', ['oilseed_id'], unique=False)
    op.create_table('crop_calendar_activities',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('calendar_id', sa.Integer(), nullable=False),
    sa.Column('activity_key', sa.String(length=100), nullable=False),
    sa.Column('stage', sa.String(length=100), nullable=False),
    sa.Column('title', sa.String(length=255), nullable=False),
    sa.Column('category', sa.Enum('CROP_ESTABLISHMENT', 'FIELD_MONITORING', 'NUTRIENT_MANAGEMENT', 'IRRIGATION', 'WEED_MANAGEMENT', 'CROP_MONITORING', 'PEST_MONITORING', 'HARVEST_PREPARATION', 'HARVEST', 'POST_HARVEST', name='activity_category'), nullable=False),
    sa.Column('priority', sa.Enum('LOW', 'MEDIUM', 'HIGH', 'CRITICAL', name='activity_priority'), nullable=False),
    sa.Column('description', sa.String(length=500), nullable=False),
    sa.Column('guidance', sa.String(length=500), nullable=False),
    sa.Column('start_date', sa.Date(), nullable=False),
    sa.Column('end_date', sa.Date(), nullable=False),
    sa.Column('completed_at', sa.DateTime(timezone=True), nullable=True),
    sa.ForeignKeyConstraint(['calendar_id'], ['crop_calendars.id'], ),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_crop_calendar_activities_calendar_id', 'crop_calendar_activities', ['calendar_id'], unique=False)


def downgrade() -> None:
    """Downgrade schema."""
    op.drop_index('ix_crop_calendar_activities_calendar_id', table_name='crop_calendar_activities')
    op.drop_table('crop_calendar_activities')
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
    op.create_table('crop_calendar_activities',
    sa.Column('id', sa.Integer(), nullable=False),
    sa.Column('calendar_id', sa.Integer(), nullable=False),
    sa.Column('activity_key', sa.String(length=100), nullable=False),
    sa.Column('stage', sa.String(length=100), nullable=False),
    sa.Column('title', sa.String(length=255), nullable=False),
    sa.Column('category', sa.Enum('CROP_ESTABLISHMENT', 'FIELD_MONITORING', 'NUTRIENT_MANAGEMENT', 'IRRIGATION', 'WEED_MANAGEMENT', 'CROP_MONITORING', 'PEST_MONITORING', 'HARVEST_PREPARATION', 'HARVEST', 'POST_HARVEST', name='activity_category'), nullable=False),
    sa.Column('priority', sa.Enum('LOW', 'MEDIUM', 'HIGH', 'CRITICAL', name='activity_priority'), nullable=False),
    sa.Column('description', sa.String(length=500), nullable=False),
    sa.Column('guidance', sa.String(length=500), nullable=False),
    sa.Column('start_date', sa.Date(), nullable=False),
    sa.Column('end_date', sa.Date(), nullable=False),
    sa.Column('completed_at', sa.DateTime(timezone=True), nullable=True),
    sa.ForeignKeyConstraint(['calendar_id'], ['crop_calendars.id'], ),
    sa.PrimaryKeyConstraint('id')
    )
    op.create_index('ix_crop_calendar_activities_calendar_id', 'crop_calendar_activities', ['calendar_id'], unique=False)

    op.drop_index('ix_oilseeds_land_id', table_name='oilseeds')
    op.drop_table('oilseeds')
