"""
FastAPI Ana Uygulama Dosyası
"""
import asyncio
import threading
import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.routers import emails
from app.routers import redis_test
from app.services.pubsub_service import PubSubService
from app.services.email_sync_scheduler import email_sync_scheduler

app = FastAPI(
    title="AI Asistan API",
    description="AI Asistan Backend API",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
)

# CORS ayarları - virgülle ayrılmış string'i liste'ye çevir
# CORS_ORIGINS'i Settings'ten kaldırdık, doğrudan os.getenv() kullanıyoruz
cors_origins_str = os.getenv("CORS_ORIGINS", "http://localhost:3000")
cors_origins_list = [origin.strip() for origin in cors_origins_str.split(",") if origin.strip()]

app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# API route'ları
app.include_router(emails.router, prefix="/api/emails", tags=["Emails"])
app.include_router(redis_test.router, prefix="/api/redis", tags=["Redis"])

# Pub/Sub servisi (background task için)
pubsub_service = PubSubService()


def start_pubsub_listener():
    """Pub/Sub listener'ı background thread'de başlat"""
    try:
        if settings.GOOGLE_CLOUD_PROJECT_ID:
            print("\n" + "="*80)
            print("🔄 Pub/Sub background listener başlatılıyor...")
            print("="*80 + "\n")
            pubsub_service.start_listening()
        else:
            print("⚠️ GOOGLE_CLOUD_PROJECT_ID yapılandırılmamış, Pub/Sub devre dışı")
    except Exception as e:
        print(f"❌ Pub/Sub listener başlatma hatası: {e}")


@app.on_event("startup")
async def startup_event():
    """Uygulama başlangıcında çalışacak event"""
    # Pub/Sub listener'ı background thread'de başlat (sadece yapılandırılmışsa)
    if settings.GOOGLE_CLOUD_PROJECT_ID:
        try:
            pubsub_thread = threading.Thread(target=start_pubsub_listener, daemon=True)
            pubsub_thread.start()
            print("✅ Pub/Sub background thread başlatıldı")
        except Exception as e:
            print(f"⚠️ Pub/Sub thread başlatılamadı: {e}")
    else:
        print("ℹ️ Pub/Sub yapılandırılmamış, background listener başlatılmıyor")
    
    # Email Sync Scheduler'ı başlat (UI açık değilken bile email'leri çekecek)
    try:
        email_sync_scheduler.start()
        print("✅ Email Sync Scheduler başlatıldı")
    except Exception as e:
        print(f"⚠️ Email Sync Scheduler başlatılamadı: {e}")


@app.on_event("shutdown")
async def shutdown_event():
    """Uygulama kapanışında çalışacak event"""
    pubsub_service.stop_listening()
    print("⚠️ Pub/Sub listener durduruldu")
    
    # Email Sync Scheduler'ı durdur
    try:
        email_sync_scheduler.stop()
    except Exception as e:
        print(f"⚠️ Email Sync Scheduler durdurma hatası: {e}")


@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "message": "AI Asistan API",
        "version": "1.0.0",
        "status": "running",
        "pubsub_enabled": bool(settings.GOOGLE_CLOUD_PROJECT_ID)
    }


@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "pubsub_enabled": bool(settings.GOOGLE_CLOUD_PROJECT_ID)
    }


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host="0.0.0.0",
        port=3000,
        reload=True
    )

