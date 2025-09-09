from typing import List, Optional
from sqlalchemy.orm import Session
from sqlalchemy import and_
from datetime import datetime, timedelta
from app.models.api_keys import ApiKey


class ApiKeyService:
    """Service for managing API keys and quotas"""
    
    def __init__(self, db: Session):
        self.db = db
    
    async def get_active_key(self, service_name: str) -> Optional[ApiKey]:
        """Get the primary active API key for a service"""
        return self.db.query(ApiKey).filter(
            and_(
                ApiKey.service_name == service_name,
                ApiKey.is_active == True,
                ApiKey.is_primary == True
            )
        ).first()
    
    async def get_available_key(self, service_name: str) -> Optional[ApiKey]:
        """Get an available API key (not quota exceeded) for a service"""
        keys = self.db.query(ApiKey).filter(
            and_(
                ApiKey.service_name == service_name,
                ApiKey.is_active == True
            )
        ).order_by(ApiKey.quota_used.asc()).all()
        
        for key in keys:
            if await self.check_quota_available(key):
                return key
        return None
    
    async def check_quota_available(self, api_key: ApiKey) -> bool:
        """Check if API key has available quota"""
        # Check if quota reset is needed
        if api_key.quota_reset_at and datetime.utcnow() > api_key.quota_reset_at:
            await self.reset_quota(api_key)
        
        return api_key.quota_used < api_key.quota_limit
    
    async def use_quota(self, api_key: ApiKey, requests_used: int = 1, cost: float = 0.0) -> bool:
        """Use quota for an API key"""
        if not await self.check_quota_available(api_key):
            return False
        
        api_key.quota_used += requests_used
        api_key.total_cost += cost
        api_key.last_used_at = datetime.utcnow()
        
        self.db.commit()
        return True
    
    async def reset_quota(self, api_key: ApiKey) -> None:
        """Reset quota for an API key"""
        api_key.quota_used = 0
        
        # Set next reset time based on period
        if api_key.quota_period == "hourly":
            api_key.quota_reset_at = datetime.utcnow() + timedelta(hours=1)
        elif api_key.quota_period == "daily":
            api_key.quota_reset_at = datetime.utcnow() + timedelta(days=1)
        elif api_key.quota_period == "monthly":
            api_key.quota_reset_at = datetime.utcnow() + timedelta(days=30)
        
        self.db.commit()
    
    async def create_api_key(
        self,
        service_name: str,
        api_key: str,
        quota_limit: int = 1000,
        quota_period: str = "daily",
        key_name: Optional[str] = None,
        is_primary: bool = False
    ) -> ApiKey:
        """Create a new API key"""
        new_key = ApiKey(
            service_name=service_name,
            api_key=api_key,
            quota_limit=quota_limit,
            quota_period=quota_period,
            key_name=key_name,
            is_primary=is_primary
        )
        
        self.db.add(new_key)
        self.db.commit()
        self.db.refresh(new_key)
        return new_key
    
    async def get_all_keys(self, service_name: Optional[str] = None) -> List[ApiKey]:
        """Get all API keys, optionally filtered by service"""
        query = self.db.query(ApiKey)
        if service_name:
            query = query.filter(ApiKey.service_name == service_name)
        return query.all()
    
    async def deactivate_key(self, key_id: int) -> bool:
        """Deactivate an API key"""
        key = self.db.query(ApiKey).filter(ApiKey.id == key_id).first()
        if key:
            key.is_active = False
            self.db.commit()
            return True
        return False