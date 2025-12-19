"""
Email endpoint'leri
"""
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.services.email_service import EmailService

router = APIRouter()


@router.get("/accounts")
async def get_email_accounts(db: Session = Depends(get_db)):
    """Kullanıcının email hesaplarını listele"""
    # TODO: Implement
    return {"accounts": []}


@router.get("/messages")
async def get_messages(account_id: str, db: Session = Depends(get_db)):
    """Email mesajlarını getir"""
    # TODO: Implement
    return {"messages": []}


@router.post("/send")
async def send_email(db: Session = Depends(get_db)):
    """Email gönder"""
    # TODO: Implement
    return {"message": "Email sent"}

