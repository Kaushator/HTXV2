"""
SQLAlchemy Base class for all models.
Centralized to prevent metadata conflicts.
"""
from sqlalchemy.orm import declarative_base

# Base class for all models - single source of truth
Base = declarative_base()