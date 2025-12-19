"""
User şemaları
"""
from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional


class UserBase(BaseModel):
    """Temel kullanıcı şeması"""
    email: EmailStr
    full_name: Optional[str] = None


class UserCreate(UserBase):
    """Kullanıcı oluşturma şeması"""
    password: str


class UserResponse(UserBase):
    """Kullanıcı response şeması"""
    id: int
    is_active: bool
    created_at: datetime
    
    class Config:
        from_attributes = True


class Token(BaseModel):
    """Token response şeması"""
    access_token: str
    token_type: str

