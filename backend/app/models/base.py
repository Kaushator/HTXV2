"""
Base model for SQLAlchemy declarative models.
Single source of truth for Base to avoid circular imports.
"""
from sqlalchemy.orm import declarative_base

# Base class for all models
Base = declarative_base()