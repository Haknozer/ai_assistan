"""
Yardımcı fonksiyonlar
"""
from datetime import datetime
from typing import Any, Dict


def format_datetime(dt: datetime) -> str:
    """Datetime'ı string'e çevir"""
    return dt.isoformat() if dt else None


def create_response(data: Any, message: str = "Success") -> Dict:
    """Standart API response oluştur"""
    return {
        "message": message,
        "data": data,
        "timestamp": datetime.utcnow().isoformat()
    }

