"""
Uygulama yapılandırması ve ortam değişkenleri
"""
from pydantic_settings import BaseSettings
from pydantic import ConfigDict
from typing import List
import os
from dotenv import load_dotenv

load_dotenv()


class Settings(BaseSettings):
    """Uygulama ayarları"""
    
    # Database
    DATABASE_URL: str = os.getenv("DATABASE_URL", "sqlite:///./ai_asisstan.db")
    
    # JWT Security
    SECRET_KEY: str = os.getenv("SECRET_KEY", "change-this-secret-key-in-production")
    ALGORITHM: str = os.getenv("ALGORITHM", "HS256")
    ACCESS_TOKEN_EXPIRE_MINUTES: int = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "30"))
    
    # Google OAuth
    GOOGLE_CLIENT_ID: str = os.getenv("GOOGLE_CLIENT_ID", "")
    GOOGLE_CLIENT_SECRET: str = os.getenv("GOOGLE_CLIENT_SECRET", "")
    GOOGLE_REDIRECT_URI: str = os.getenv("GOOGLE_REDIRECT_URI", "")
    
    # Microsoft OAuth
    MICROSOFT_CLIENT_ID: str = os.getenv("MICROSOFT_CLIENT_ID") or os.getenv("MS_CLIENT_ID", "")
    MICROSOFT_CLIENT_SECRET: str = os.getenv("MICROSOFT_CLIENT_SECRET") or os.getenv("MS_CLIENT_SECRET", "")
    MS_CLIENT_ID: str = os.getenv("MS_CLIENT_ID", "")
    MS_CLIENT_SECRET: str = os.getenv("MS_CLIENT_SECRET", "")
    MS_REDIRECT_URI: str = os.getenv("MS_REDIRECT_URI", "")
    MS_TENANT_ID: str = os.getenv("MS_TENANT_ID", "common")
    
    # Outlook OAuth (alias for MS)
    OUTLOOK_CLIENT_ID: str = os.getenv("OUTLOOK_CLIENT_ID") or os.getenv("MS_CLIENT_ID", "")
    OUTLOOK_CLIENT_SECRET: str = os.getenv("OUTLOOK_CLIENT_SECRET") or os.getenv("MS_CLIENT_SECRET", "")
    
    # Yahoo OAuth
    YAHOO_CLIENT_ID: str = os.getenv("YAHOO_CLIENT_ID", "")
    YAHOO_CLIENT_SECRET: str = os.getenv("YAHOO_CLIENT_SECRET", "")
    
    # AI Services
    GROQ_API_KEY: str = os.getenv("GROQ_API_KEY", "")
    OPENAI_API_KEY: str = os.getenv("OPENAI_API_KEY", "")
    
    # Telegram
    TELEGRAM_BOT_TOKEN: str = os.getenv("TELEGRAM_BOT_TOKEN", "")
    
    # n8n Webhooks
    N8N_TELEGRAM_WEBHOOK_URL: str = (os.getenv("N8N_TELEGRAM_WEBHOOK_URL") or "").strip() or "https://hakanozer12.app.n8n.cloud/webhook/7d767402-8f08-47cf-91fa-279679510375"
    N8N_EMAIL_WEBHOOK_URL: str = (os.getenv("N8N_EMAIL_WEBHOOK_URL") or "").strip() or "https://hakanozer12.app.n8n.cloud/webhook/7d767402-8f08-47cf-91fa-279679510375"
    N8N_BASE_URL: str = os.getenv("N8N_BASE_URL", "")
    N8N_MEETING_ANALYSIS_PATH: str = os.getenv("N8N_MEETING_ANALYSIS_PATH", "")
    
    # Weather API
    WEATHER_API_KEY: str = os.getenv("WEATHER_API_KEY", "")
    
    # Redis (opsiyonel)
    REDIS_URL: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")
    
    # Google Cloud Pub/Sub
    GOOGLE_CLOUD_PROJECT_ID: str = os.getenv("GOOGLE_CLOUD_PROJECT_ID", "")
    PUBSUB_SUBSCRIPTION_NAME: str = os.getenv("PUBSUB_SUBSCRIPTION_NAME", "email-fetch-subscription")
    PUBSUB_TOPIC_NAME: str = os.getenv("PUBSUB_TOPIC_NAME", "email-fetch-trigger")
    GOOGLE_APPLICATION_CREDENTIALS: str = os.getenv("GOOGLE_APPLICATION_CREDENTIALS", "")  # JSON key file path
    
    # Environment
    ENVIRONMENT: str = os.getenv("ENVIRONMENT", "development")
    APP_ENV: str = os.getenv("APP_ENV", "development")
    DEBUG: bool = os.getenv("DEBUG", "True").lower() == "true"
    
    # CORS_ORIGINS - Pydantic Settings'in parse edebilmesi için ekliyoruz
    # Ancak main.py'de os.getenv() kullanıldığı için bu field kullanılmıyor
    # Sadece Pydantic Settings'in hata vermemesi için burada tanımlı
    CORS_ORIGINS: str = os.getenv("CORS_ORIGINS", "http://localhost:3000")
    
    model_config = ConfigDict(
        env_file=".env",
        case_sensitive=True,
        extra="ignore"  # Extra alanları ignore et (hata vermesin)
    )


settings = Settings()

