from typing import Optional

from pydantic import BaseModel, EmailStr


class UserBase(BaseModel):
    """Base user schema"""

    email: EmailStr
    username: str
    full_name: Optional[str] = None


class UserCreate(UserBase):
    """User creation schema"""

    password: str


class UserUpdate(BaseModel):
    """User update schema"""

    email: Optional[EmailStr] = None
    username: Optional[str] = None
    full_name: Optional[str] = None
    bio: Optional[str] = None
    avatar_url: Optional[str] = None


class UserLogin(BaseModel):
    """User login schema"""

    username: str
    password: str


class UserResponse(UserBase):
    """User response schema"""

    id: int
    is_active: bool
    is_superuser: bool
    avatar_url: Optional[str] = None
    bio: Optional[str] = None

    class Config:
        from_attributes = True
