"""Add api_keys table

Revision ID: 001_add_api_keys
Revises: 
Create Date: 2024-09-08 23:59:00.000000

"""
from alembic import op
import sqlalchemy as sa
from sqlalchemy.sql import func


# revision identifiers, used by Alembic.
revision = '001_add_api_keys'
down_revision = None
branch_labels = None
depends_on = None


def upgrade():
    # Create api_keys table
    op.create_table(
        'api_keys',
        sa.Column('id', sa.Integer(), primary_key=True, index=True),
        sa.Column('service_name', sa.String(50), nullable=False, index=True),
        sa.Column('api_key', sa.String(255), nullable=False),
        sa.Column('quota_limit', sa.Integer(), nullable=False, default=1000),
        sa.Column('quota_used', sa.Integer(), nullable=False, default=0),
        sa.Column('quota_period', sa.String(20), nullable=False, default='daily'),
        sa.Column('quota_reset_at', sa.DateTime(timezone=True), nullable=True),
        sa.Column('key_name', sa.String(100), nullable=True),
        sa.Column('description', sa.String(255), nullable=True),
        sa.Column('cost_per_request', sa.Numeric(10, 6), nullable=True, default=0.0),
        sa.Column('total_cost', sa.Numeric(10, 2), nullable=False, default=0.0),
        sa.Column('is_active', sa.Boolean(), nullable=False, default=True),
        sa.Column('is_primary', sa.Boolean(), nullable=False, default=False),
        sa.Column('created_at', sa.DateTime(timezone=True), server_default=func.now()),
        sa.Column('updated_at', sa.DateTime(timezone=True), onupdate=func.now()),
        sa.Column('last_used_at', sa.DateTime(timezone=True), nullable=True),
    )
    
    # Insert default CoinGecko API key from config
    op.execute("""
        INSERT INTO api_keys (service_name, api_key, quota_limit, quota_period, key_name, is_primary, is_active)
        VALUES ('coingecko', 'demo-key', 10000, 'monthly', 'Default CoinGecko Key', true, true)
    """)


def downgrade():
    op.drop_table('api_keys')