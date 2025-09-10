from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = "20250909_0004"
down_revision = "20250909_0003"
branch_labels = None
depends_on = None


def upgrade() -> None:
    op.create_table(
        "uploads",
        sa.Column("id", sa.String(length=36), primary_key=True),
        sa.Column("object_key", sa.String(length=512), nullable=False, index=True),
        sa.Column("content_type", sa.String(length=255), nullable=True),
        sa.Column("size_bytes", sa.BigInteger, nullable=True),
        sa.Column("verified", sa.Boolean, nullable=False, server_default=sa.text("FALSE")),
        sa.Column("storage", sa.String(length=32), nullable=False, server_default="gcs"),
        sa.Column("created_at", sa.DateTime(timezone=True), server_default=sa.text("NOW()")),
        sa.Column("verified_at", sa.DateTime(timezone=True), nullable=True),
    )
    op.create_index("idx_uploads_object_key", "uploads", ["object_key"])


def downgrade() -> None:
    op.drop_index("idx_uploads_object_key", table_name="uploads")
    op.drop_table("uploads")

