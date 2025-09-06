from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import timedelta

from app.core.config import settings
from app.core.security import (
    create_access_token, 
    create_refresh_token,
    verify_password,
    get_password_hash,
    get_current_active_user
)
from app.db.session import get_db
from app.services.user_service import UserService
from app.schemas.auth import Token, UserCreate, UserLogin
from app.schemas.user import UserResponse

router = APIRouter()


@router.post("/register", response_model=UserResponse)
async def register(
    user_create: UserCreate,
    db: AsyncSession = Depends(get_db)
):
    """Register a new user"""
    user_service = UserService(db)
    
    # Check if user already exists
    existing_user = await user_service.get_user_by_email(user_create.email)
    if existing_user:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Email already registered"
        )
    
    existing_username = await user_service.get_user_by_username(user_create.username)
    if existing_username:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Username already taken"
        )
    
    # Create new user
    user = await user_service.create_user(user_create)
    return user


@router.post("/login", response_model=Token)
async def login(
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: AsyncSession = Depends(get_db)
):
    """User login"""
    user_service = UserService(db)
    
    # Authenticate user
    user = await user_service.authenticate_user(form_data.username, form_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    # Create access token
    access_token_expires = timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": str(user.id)}, 
        expires_delta=access_token_expires
    )
    
    # Create refresh token
    refresh_token = create_refresh_token(data={"sub": str(user.id)})
    
    # Update last login
    await user_service.update_last_login(user.id)
    
    return {
        "access_token": access_token,
        "refresh_token": refresh_token,
        "token_type": "bearer"
    }


@router.post("/refresh", response_model=Token)
async def refresh_token(
    refresh_token: str,
    db: AsyncSession = Depends(get_db)
):
    """Refresh access token"""
    # In a real implementation, you would:
    # 1. Validate the refresh token
    # 2. Extract user information from the token
    # 3. Generate new access and refresh tokens
    # 4. Optionally rotate the refresh token
    
    # For now, returning new tokens (would validate refresh_token in production)
    new_access_token = create_access_token(data={"sub": "user@example.com"})
    new_refresh_token = create_refresh_token(data={"sub": "user@example.com"})
    
    return {
        "access_token": new_access_token,
        "refresh_token": new_refresh_token,
        "token_type": "bearer"
    }


@router.post("/logout")
async def logout(
    current_user = Depends(get_current_active_user),
    db: AsyncSession = Depends(get_db)
):
    """Logout user and invalidate tokens"""
    from datetime import datetime
    
    # In a real implementation, you would:
    # 1. Add the token to a blacklist/revocation list
    # 2. Clear any session data
    # 3. Log the logout event
    
    return {
        "message": "Successfully logged out",
        "user_id": current_user.id,
        "timestamp": datetime.utcnow().isoformat()
    }