"""
Calendar modelleri
"""
from sqlalchemy import Column, Integer, String, ForeignKey, Text, DateTime, Boolean
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship
from app.core.database import Base


class CalendarAccount(Base):
    """Takvim hesabı modeli"""
    __tablename__ = "calendar_accounts"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    provider = Column(String, nullable=False)  # google, microsoft, yahoo
    email = Column(String, nullable=False)
    access_token = Column(Text, nullable=True)  # Şifrelenmiş olmalı
    refresh_token = Column(Text, nullable=True)  # Şifrelenmiş olmalı
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    events = relationship("CalendarEvent", back_populates="account")


class CalendarEvent(Base):
    """Takvim etkinliği modeli"""
    __tablename__ = "calendar_events"
    
    id = Column(Integer, primary_key=True, index=True)
    account_id = Column(Integer, ForeignKey("calendar_accounts.id"), nullable=False)
    event_id = Column(String, unique=True, nullable=False)  # Provider'dan gelen ID
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    start_time = Column(DateTime(timezone=True), nullable=False)
    end_time = Column(DateTime(timezone=True), nullable=False)
    location = Column(String, nullable=True)
    is_all_day = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    account = relationship("CalendarAccount", back_populates="events")

