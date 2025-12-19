"""
Calendar endpoint'leri
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db

router = APIRouter()


@router.get("/events")
async def get_events(db: Session = Depends(get_db)):
    """Takvim etkinliklerini getir"""
    # TODO: Implement
    return {"events": []}


@router.post("/events")
async def create_event(db: Session = Depends(get_db)):
    """Yeni takvim etkinliği oluştur"""
    # TODO: Implement
    return {"message": "Event created"}

