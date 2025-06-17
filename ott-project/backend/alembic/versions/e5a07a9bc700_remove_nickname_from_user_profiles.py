"""Remove nickname from user_profiles

Revision ID: e5a07a9bc700
Revises: ad59ab1fad87
Create Date: 2025-06-12 10:24:35.676520

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = 'e5a07a9bc700'
down_revision: Union[str, None] = 'ad59ab1fad87'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Upgrade schema."""
    op.drop_column('user_profiles', 'nickname')


def downgrade() -> None:
    """Downgrade schema."""
    op.add_column('user_profiles', sa.Column('nickname', sa.String(length=100), nullable=True))
