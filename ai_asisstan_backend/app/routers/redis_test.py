"""
Redis test endpoint'leri - Redis'teki verileri kontrol etmek için
"""
from fastapi import APIRouter, Query
from typing import Optional, List
from app.core.redis_client import redis_client
import json

router = APIRouter()


@router.get("/tasks")
async def get_all_tasks(
    provider: Optional[str] = Query(None, description="Provider filtresi: 'gmail' veya 'outlook'")
):
    """
    Redis'teki tüm görev çıkarımlarını listele
    
    **Örnek:**
    ```bash
    # Tüm görevler
    curl "http://localhost:3000/api/redis/tasks"
    
    # Sadece Gmail görevleri
    curl "http://localhost:3000/api/redis/tasks?provider=gmail"
    
    # Sadece Outlook görevleri
    curl "http://localhost:3000/api/redis/tasks?provider=outlook"
    ```
    """
    if not redis_client.is_connected():
        return {
            "error": "Redis bağlantısı yok",
            "connected": False,
            "tasks": []
        }
    
    tasks = redis_client.get_all_tasks(provider=provider)
    
    return {
        "connected": True,
        "provider_filter": provider or "all",
        "total": len(tasks),
        "tasks": tasks
    }


@router.get("/emails")
async def get_emails_by_date_range(
    start_date: str = Query(..., description="Başlangıç tarihi (ISO 8601 format: 2025-12-25T00:00:00.000Z)"),
    end_date: str = Query(..., description="Bitiş tarihi (ISO 8601 format: 2025-12-25T23:59:59.999Z)"),
    provider: Optional[str] = Query(None, description="Provider filtresi: 'gmail' veya 'outlook'")
):
    """
    Redis'ten tarih aralığına göre email ve task verilerini getir
    
    Bu endpoint, sesli asistan "5 gün önceki maillerimi özetle" gibi komutlar için kullanılır.
    
    **Örnek:**
    ```bash
    # Belirli tarih aralığındaki tüm emailleri getir
    curl "http://localhost:3000/api/redis/emails?start_date=2025-12-25T00:00:00.000Z&end_date=2025-12-25T23:59:59.999Z"
    
    # Sadece Gmail emailleri
    curl "http://localhost:3000/api/redis/emails?start_date=2025-12-25T00:00:00.000Z&end_date=2025-12-25T23:59:59.999Z&provider=gmail"
    ```
    """
    if not redis_client.is_connected():
        return {
            "error": "Redis bağlantısı yok",
            "connected": False,
            "emails": []
        }
    
    emails = redis_client.get_emails_by_date_range(
        start_date=start_date,
        end_date=end_date,
        provider=provider
    )
    
    return {
        "connected": True,
        "start_date": start_date,
        "end_date": end_date,
        "provider_filter": provider or "all",
        "total": len(emails),
        "emails": emails
    }


@router.get("/tasks/{provider}/{email_id}")
async def get_task_by_email(
    provider: str,
    email_id: str
):
    """
    Belirli bir email için Redis'teki görev çıkarımını getir
    
    **Örnek:**
    ```bash
    curl "http://localhost:3000/api/redis/tasks/gmail/19b2c7e64bb0a7c5"
    ```
    """
    if not redis_client.is_connected():
        return {
            "error": "Redis bağlantısı yok",
            "connected": False,
            "data": None
        }
    
    data = redis_client.get_task_extraction(email_id=email_id, provider=provider)
    
    if data:
        return {
            "connected": True,
            "found": True,
            "data": data
        }
    else:
        return {
            "connected": True,
            "found": False,
            "data": None,
            "message": f"Email ID '{email_id}' için {provider} provider'ında veri bulunamadı"
        }


@router.delete("/tasks")
async def clear_all_email_tasks(
    provider: Optional[str] = Query(None, description="Provider filtresi: 'gmail' veya 'outlook'. None ise tümü silinir")
):
    """
    Redis'teki tüm email task verilerini sil
    
    **Örnek:**
    ```bash
    # Tüm email task'ları sil
    curl -X DELETE "http://localhost:3000/api/redis/tasks"
    
    # Sadece Gmail task'ları sil
    curl -X DELETE "http://localhost:3000/api/redis/tasks?provider=gmail"
    
    # Sadece Outlook task'ları sil
    curl -X DELETE "http://localhost:3000/api/redis/tasks?provider=outlook"
    ```
    """
    if not redis_client.is_connected():
        return {
            "error": "Redis bağlantısı yok",
            "connected": False,
            "deleted": 0
        }
    
    try:
        pattern = f"email_tasks:{provider}:*" if provider else "email_tasks:*:*"
        keys = redis_client.client.keys(pattern)
        
        deleted_count = 0
        for key in keys:
            redis_client.client.delete(key)
            deleted_count += 1
        
        return {
            "connected": True,
            "provider_filter": provider or "all",
            "deleted": deleted_count,
            "message": f"{deleted_count} adet email task verisi silindi"
        }
    except Exception as e:
        return {
            "error": f"Silme hatası: {str(e)}",
            "connected": True,
            "deleted": 0
        }


@router.get("/status")
async def get_redis_status():
    """
    Redis bağlantı durumunu kontrol et
    
    **Örnek:**
    ```bash
    curl "http://localhost:3000/api/redis/status"
    ```
    """
    is_connected = redis_client.is_connected()
    
    if is_connected:
        # Redis'teki key sayısını al
        try:
            all_keys = redis_client.client.keys("email_tasks:*:*")
            gmail_keys = redis_client.client.keys("email_tasks:gmail:*")
            outlook_keys = redis_client.client.keys("email_tasks:outlook:*")
            
            return {
                "connected": True,
                "redis_url": redis_client.client.connection_pool.connection_kwargs.get("host", "unknown"),
                "stats": {
                    "total_tasks": len(all_keys),
                    "gmail_tasks": len(gmail_keys),
                    "outlook_tasks": len(outlook_keys)
                }
            }
        except Exception as e:
            return {
                "connected": True,
                "error": f"İstatistik alınamadı: {str(e)}"
            }
    else:
        return {
            "connected": False,
            "message": "Redis bağlantısı yok. Redis'in çalıştığından emin olun."
        }

