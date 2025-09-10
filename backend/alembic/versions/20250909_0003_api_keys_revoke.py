from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "20250909_0003"
down_revision = "20250909_0002"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.add_column("api_keys", sa.Column("revoked_at", sa.DateTime(timezone=True), nullable=True))
    op.add_column("api_keys", sa.Column("revocation_reason", sa.Text, nullable=True))


def downgrade() -> None:
    op.drop_column("api_keys", "revocation_reason")
    op.drop_column("api_keys", "revoked_at")

