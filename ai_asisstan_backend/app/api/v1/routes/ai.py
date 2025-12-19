"""
AI endpoint'leri
"""
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.core.database import get_db

router = APIRouter()


@router.post("/chat")
async def chat(message: str, db: Session = Depends(get_db)):
    """AI chat endpoint"""
    # TODO: Implement AI chat
    return {"response": "AI response placeholder"}


@router.post("/transcribe")
async def transcribe_audio(audio_file: bytes, db: Session = Depends(get_db)):
    """Ses dosyasını metne çevir"""
    # TODO: Implement speech-to-text
    return {"transcription": "Transcribed text"}

