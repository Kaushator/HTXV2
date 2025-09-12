from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.sql import func

from app.models.user import User
from app.schemas.user import UserCreate, UserUpdate
from app.core.password import get_password_hash, verify_password


class UserService:
    """User service for database operations"""
    
    def __init__(self, db: AsyncSession):
        self.db = db
    
    async def get_user(self, user_id: int) -> Optional[User]:
        """Get user by ID"""
        result = await self.db.execute(
            select(User).where(User.id == user_id)
        )
        return result.scalar_one_or_none()
    
    async def get_user_by_email(self, email: str) -> Optional[User]:
        """Get user by email"""
        result = await self.db.execute(
            select(User).where(User.email == email)
        )
        return result.scalar_one_or_none()
    
    async def get_user_by_username(self, username: str) -> Optional[User]:
        """Get user by username"""
        result = await self.db.execute(
            select(User).where(User.username == username)
        )
        return result.scalar_one_or_none()
    
    async def create_user(self, user_create: UserCreate) -> User:
        """Create a new user"""
        hashed_password = get_password_hash(user_create.password)
        
        user = User(
            email=user_create.email,
            username=user_create.username,
            hashed_password=hashed_password,
            full_name=user_create.full_name,
        )
        
        self.db.add(user)
        await self.db.commit()
        await self.db.refresh(user)
        
        return user
    
    async def update_user(self, user_id: int, user_update: UserUpdate) -> Optional[User]:
        """Update user information"""
        user = await self.get_user(user_id)
        if not user:
            return None
        
        update_data = user_update.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(user, field, value)
        
        user.updated_at = func.now()
        await self.db.commit()
        await self.db.refresh(user)
        
        return user
    
    async def authenticate_user(self, username: str, password: str) -> Optional[User]:
        """Authenticate user with username/email and password"""
        # Try to find user by username first, then by email
        user = await self.get_user_by_username(username)
        if not user:
            user = await self.get_user_by_email(username)
        
        if not user:
            return None
        
        if not verify_password(password, user.hashed_password):
            return None
        
        return user
    
    async def update_last_login(self, user_id: int) -> None:
        """Update user's last login timestamp"""
        user = await self.get_user(user_id)
        if user:
            user.last_login = func.now()
            await self.db.commit()
    
    async def deactivate_user(self, user_id: int) -> bool:
        """Deactivate a user account"""
        user = await self.get_user(user_id)
        if not user:
            return False
        
        user.is_active = False
        await self.db.commit()
        return True
    
    async def activate_user(self, user_id: int) -> bool:
        """Activate a user account"""
        user = await self.get_user(user_id)
        if not user:
            return False
        
        user.is_active = True
        await self.db.commit()
        return True