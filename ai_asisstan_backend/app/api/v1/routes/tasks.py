"""
Tasks endpoint'leri
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db

router = APIRouter()


@router.get("/")
async def get_tasks(db: Session = Depends(get_db)):
    """Görevleri getir"""
    # TODO: Implement
    return {"tasks": []}


@router.post("/")
async def create_task(db: Session = Depends(get_db)):
    """Yeni görev oluştur"""
    # TODO: Implement
    return {"message": "Task created"}

