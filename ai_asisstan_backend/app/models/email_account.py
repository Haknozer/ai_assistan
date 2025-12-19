"""
Email Account modelleri
"""
from sqlalchemy import Column, Integer, String, ForeignKey, Text, DateTime, Boolean
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.database import Base


class EmailAccount(Base):
    """Email hesabı modeli"""
    __tablename__ = "email_accounts"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    provider = Column(String, nullable=False)  # "gmail" veya "outlook"
    email = Column(String, nullable=False)
    access_token = Column(Text, nullable=True)  # OAuth access token
    refresh_token = Column(Text, nullable=True)  # OAuth refresh token
    token_expires_at = Column(DateTime(timezone=True), nullable=True)  # Token son kullanma tarihi
    is_active = Column(Boolean, default=True)  # Hesap aktif mi?
    is_connected = Column(Boolean, default=False)  # Entegre edilmiş mi?
    last_sync_at = Column(DateTime(timezone=True), nullable=True)  # Son senkronizasyon tarihi
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

