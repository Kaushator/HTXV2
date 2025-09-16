from typing import Optional

from pydantic import BaseModel

from app.schemas.user import UserCreate, UserLogin


class Token(BaseModel):
    """Token response schema"""

    access_token: str
    refresh_token: str
    token_type: str


class TokenData(BaseModel):
    """Token data schema"""

    user_id: Optional[str] = None


class TokenRefreshRequest(BaseModel):
    """Refresh token request payload"""

    refresh_token: str
