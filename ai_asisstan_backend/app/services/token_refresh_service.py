"""
Token Refresh Service - Otomatik token yenileme servisi
Gmail ve Outlook için expired token'ları otomatik olarak yeniler
"""
import httpx
from typing import Optional, Dict
from datetime import datetime, timedelta
from sqlalchemy.orm import Session
from app.models.email_account import EmailAccount
from app.core.config import settings


class TokenRefreshService:
    """Token yenileme servisi"""
    
    @staticmethod
    async def refresh_gmail_token(refresh_token: str) -> Dict[str, any]:
        """
        Gmail refresh token ile yeni access token al
        
        Args:
            refresh_token: Gmail refresh token
            
        Returns:
            {
                'access_token': str,
                'expires_in': int,
                'token_type': str
            }
            
        Raises:
            Exception: Token yenilenemezse
        """
        if not settings.GOOGLE_CLIENT_ID or not settings.GOOGLE_CLIENT_SECRET:
            raise Exception("Gmail OAuth yapılandırması eksik (CLIENT_ID veya CLIENT_SECRET)")
        
        token_url = "https://oauth2.googleapis.com/token"
        
        data = {
            'client_id': settings.GOOGLE_CLIENT_ID,
            'client_secret': settings.GOOGLE_CLIENT_SECRET,
            'refresh_token': refresh_token,
            'grant_type': 'refresh_token'
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                token_url,
                data=data,
                headers={'Content-Type': 'application/x-www-form-urlencoded'}
            )
            
            if response.status_code != 200:
                error_body = response.text
                if 'invalid_grant' in error_body:
                    raise Exception("Refresh token geçersiz veya süresi dolmuş. Lütfen Gmail hesabını yeniden bağlayın.")
                elif 'invalid_client' in error_body:
                    raise Exception("Gmail OAuth yapılandırması hatalı (Client ID veya Secret yanlış)")
                else:
                    raise Exception(f"Token yenileme hatası: {error_body}")
            
            return response.json()
    
    @staticmethod
    async def refresh_outlook_token(refresh_token: str) -> Dict[str, any]:
        """
        Outlook refresh token ile yeni access token al
        
        Args:
            refresh_token: Outlook refresh token
            
        Returns:
            {
                'access_token': str,
                'expires_in': int,
                'token_type': str,
                'refresh_token': str  # Outlook bazen yeni refresh token döner
            }
            
        Raises:
            Exception: Token yenilenemezse
        """
        if not settings.OUTLOOK_CLIENT_ID or not settings.OUTLOOK_CLIENT_SECRET:
            raise Exception("Outlook OAuth yapılandırması eksik (CLIENT_ID veya CLIENT_SECRET)")
        
        token_url = "https://login.microsoftonline.com/common/oauth2/v2.0/token"
        
        data = {
            'client_id': settings.OUTLOOK_CLIENT_ID,
            'client_secret': settings.OUTLOOK_CLIENT_SECRET,
            'refresh_token': refresh_token,
            'grant_type': 'refresh_token',
            'scope': 'https://graph.microsoft.com/Mail.Read https://graph.microsoft.com/Mail.ReadWrite https://graph.microsoft.com/Mail.Send https://graph.microsoft.com/User.Read offline_access'
        }
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                token_url,
                data=data,
                headers={'Content-Type': 'application/x-www-form-urlencoded'}
            )
            
            if response.status_code != 200:
                error_body = response.text
                if 'invalid_grant' in error_body:
                    raise Exception("Refresh token geçersiz veya süresi dolmuş. Lütfen Outlook hesabını yeniden bağlayın.")
                elif 'invalid_client' in error_body:
                    raise Exception("Outlook OAuth yapılandırması hatalı (Client ID veya Secret yanlış)")
                else:
                    raise Exception(f"Token yenileme hatası: {error_body}")
            
            return response.json()
    
    @staticmethod
    async def refresh_account_token_if_needed(account: EmailAccount, db: Session) -> bool:
        """
        Email account'un token'ını gerekirse yenile
        
        Args:
            account: EmailAccount instance
            db: Database session
            
        Returns:
            bool: Token yenilendi mi?
            
        Raises:
            Exception: Token yenilenemezse
        """
        # Token expires_at kontrolü
        # Eğer token 5 dakikadan az süre içinde expire olacaksa yenile
        if account.token_expires_at:
            time_until_expiry = account.token_expires_at - datetime.utcnow()
            
            # Token henüz expire olmamış ve 5 dakikadan fazla süresi var
            if time_until_expiry.total_seconds() > 300:
                return False
        
        # Token yenilenmesi gerekiyor
        if not account.refresh_token:
            raise Exception(f"Refresh token yok: {account.email}. Hesabı yeniden bağlamanız gerekiyor.")
        
        print(f"🔄 Token yenileniyor: {account.email} ({account.provider})")
        
        try:
            if account.provider == "gmail":
                token_response = await TokenRefreshService.refresh_gmail_token(account.refresh_token)
            elif account.provider == "outlook":
                token_response = await TokenRefreshService.refresh_outlook_token(account.refresh_token)
            else:
                raise Exception(f"Bilinmeyen provider: {account.provider}")
            
            # Yeni token'ı database'e kaydet
            account.access_token = token_response['access_token']
            account.token_expires_at = datetime.utcnow() + timedelta(seconds=token_response.get('expires_in', 3600))
            
            # Outlook bazen yeni refresh token döner
            if 'refresh_token' in token_response:
                account.refresh_token = token_response['refresh_token']
            
            account.updated_at = datetime.utcnow()
            account.is_active = True  # Token yenilendiği için account'u aktif yap
            
            db.commit()
            
            print(f"   ✅ Token yenilendi: {account.email}")
            print(f"   ⏰ Yeni token expire: {account.token_expires_at}")
            
            return True
            
        except Exception as e:
            print(f"   ❌ Token yenileme hatası: {e}")
            
            # invalid_grant hatası ise account'u pasif yap
            if 'invalid_grant' in str(e).lower() or 'geçersiz' in str(e).lower():
                account.is_active = False
                db.commit()
                print(f"   ⚠️  Account pasif yapıldı: {account.email}")
            
            raise
    
    @staticmethod
    async def get_valid_access_token(account: EmailAccount, db: Session) -> str:
        """
        Email account için geçerli bir access token döndür
        Token expire olduysa otomatik olarak yenile
        
        Args:
            account: EmailAccount instance
            db: Database session
            
        Returns:
            str: Geçerli access token
            
        Raises:
            Exception: Token yenilenemezse veya refresh token yoksa
        """
        # Token yenilenmesi gerekirse yenile
        await TokenRefreshService.refresh_account_token_if_needed(account, db)
        
        # Yenilenmiş veya mevcut geçerli token'ı döndür
        if not account.access_token:
            raise Exception(f"Access token bulunamadı: {account.email}")
        
        return account.access_token

