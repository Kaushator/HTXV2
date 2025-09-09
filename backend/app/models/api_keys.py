from sqlalchemy import Column, Integer, String, Boolean, DateTime, Numeric
from sqlalchemy.sql import func
from app.db.session import Base


class ApiKey(Base):
    """API Key model for managing external service quotas"""
    __tablename__ = "api_keys"
    
    id = Column(Integer, primary_key=True, index=True)
    service_name = Column(String(50), nullable=False, index=True)  # coingecko, openai, etc.
    api_key = Column(String(255), nullable=False)
    
    # Quota management
    quota_limit = Column(Integer, nullable=False, default=1000)  # requests per period
    quota_used = Column(Integer, nullable=False, default=0)
    quota_period = Column(String(20), nullable=False, default="daily")  # daily, hourly, monthly
    quota_reset_at = Column(DateTime(timezone=True), nullable=True)
    
    # Key metadata
    key_name = Column(String(100), nullable=True)  # friendly name
    description = Column(String(255), nullable=True)
    
    # Cost tracking
    cost_per_request = Column(Numeric(10, 6), nullable=True, default=0.0)
    total_cost = Column(Numeric(10, 2), nullable=False, default=0.0)
    
    # Status
    is_active = Column(Boolean, default=True)
    is_primary = Column(Boolean, default=False)  # primary key for the service
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    last_used_at = Column(DateTime(timezone=True), nullable=True)
    
    def __repr__(self):
        return f"<ApiKey(service='{self.service_name}', quota={self.quota_used}/{self.quota_limit}, active={self.is_active})>"