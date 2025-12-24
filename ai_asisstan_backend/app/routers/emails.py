"""
Email endpoint'leri
"""
from fastapi import APIRouter, HTTPException, Query, Header, Depends, Body
from typing import Optional, List
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.services.outlook_email_service import OutlookEmailService
from app.services.gmail_email_service import GmailEmailService
from app.services.n8n_service import N8nService, check_email_already_processed
from app.services.token_refresh_service import TokenRefreshService
from app.models.email_schemas import (
    EmailListResponse, EmailCategory, Email,
    SendEmailRequest, SaveDraftRequest, ToggleImportantRequest
)
from app.core.redis_client import redis_client
from app.models.email_account import EmailAccount
from pydantic import BaseModel
from datetime import datetime

router = APIRouter()


# ==================== EMAIL ACCOUNT MANAGEMENT ====================

class ConnectEmailAccountRequest(BaseModel):
    """Email account bağlama request modeli"""
    provider: str  # "gmail" veya "outlook"
    email: str
    access_token: str
    refresh_token: Optional[str] = None
    user_id: Optional[int] = None


@router.post("/accounts/connect")
async def connect_email_account(
    request: ConnectEmailAccountRequest,
    db: Session = Depends(get_db)
):
    """
    Email account'u bağla ve veritabanına kaydet
    Bağlandıktan sonra background scheduler otomatik olarak email'leri çekecek
    """
    try:
        # Provider kontrolü
        if request.provider not in ["gmail", "outlook"]:
            raise HTTPException(
                status_code=400,
                detail="Provider 'gmail' veya 'outlook' olmalı"
            )
        
        # Mevcut account var mı kontrol et
        existing_account = db.query(EmailAccount).filter(
            EmailAccount.email == request.email,
            EmailAccount.provider == request.provider
        ).first()
        
        if existing_account:
            # Mevcut account'u güncelle
            existing_account.access_token = request.access_token
            existing_account.refresh_token = request.refresh_token
            existing_account.is_active = True
            existing_account.is_connected = True
            existing_account.updated_at = datetime.utcnow()
            # Token expire time'ı ayarla (genelde 1 saat)
            from datetime import timedelta
            existing_account.token_expires_at = datetime.utcnow() + timedelta(hours=1)
            db.commit()
            db.refresh(existing_account)
            
            print(f"\n✅ Email account güncellendi: {request.email} ({request.provider})")
            
            # Gmail için Push Notification kurulumu (güncelleme durumunda da yap)
            if request.provider == "gmail":
                print(f"\n🔄 Gmail Push Notification kurulumu başlatılıyor...")
                try:
                    from app.core.config import settings
                    print(f"   GOOGLE_CLOUD_PROJECT_ID: {settings.GOOGLE_CLOUD_PROJECT_ID}")
                    print(f"   PUBSUB_TOPIC_NAME: {settings.PUBSUB_TOPIC_NAME}")
                    
                    if settings.GOOGLE_CLOUD_PROJECT_ID and settings.PUBSUB_TOPIC_NAME:
                        topic_name = f"projects/{settings.GOOGLE_CLOUD_PROJECT_ID}/topics/{settings.PUBSUB_TOPIC_NAME}"
                        print(f"   Topic Full Name: {topic_name}")
                        print(f"   Access Token var: {bool(request.access_token)}")
                        
                        gmail_service = GmailEmailService(request.access_token)
                        print(f"   GmailEmailService oluşturuldu, watch request gönderiliyor...")
                        
                        watch_response = await gmail_service.setup_push_notifications(topic_name)
                        
                        print(f"\n🔔 Gmail Push Notification kuruldu:")
                        print(f"   Topic: {topic_name}")
                        print(f"   History ID: {watch_response.get('historyId')}")
                        print(f"   Expiration: {watch_response.get('expiration')}")
                    else:
                        print(f"\n⚠️  Gmail Push Notification kurulumu atlandı (Pub/Sub yapılandırılmamış)")
                        print(f"      GOOGLE_CLOUD_PROJECT_ID: '{settings.GOOGLE_CLOUD_PROJECT_ID}'")
                        print(f"      PUBSUB_TOPIC_NAME: '{settings.PUBSUB_TOPIC_NAME}'")
                except Exception as e:
                    print(f"\n❌ Gmail Push Notification kurulum HATASI: {e}")
                    print(f"   Hata tipi: {type(e).__name__}")
                    import traceback
                    print(f"   Traceback:\n{traceback.format_exc()}")
            
            return {
                "message": "Email account başarıyla güncellendi",
                "account_id": existing_account.id,
                "email": existing_account.email,
                "provider": existing_account.provider,
                "is_connected": existing_account.is_connected
            }
        else:
            # Yeni account oluştur
            from datetime import timedelta
            new_account = EmailAccount(
                user_id=request.user_id or 1,  # Default user_id, gerçek uygulamada auth'dan alınmalı
                provider=request.provider,
                email=request.email,
                access_token=request.access_token,
                refresh_token=request.refresh_token,
                is_active=True,
                is_connected=True,
                # Token expire time'ı ayarla (genelde 1 saat)
                token_expires_at=datetime.utcnow() + timedelta(hours=1)
            )
            
            db.add(new_account)
            db.commit()
            db.refresh(new_account)
            
            print(f"\n✅ Yeni email account bağlandı: {request.email} ({request.provider})")
            print(f"   Account ID: {new_account.id}")
            
            # Gmail için Push Notification kurulumu
            if request.provider == "gmail":
                try:
                    from app.core.config import settings
                    if settings.GOOGLE_CLOUD_PROJECT_ID and settings.PUBSUB_TOPIC_NAME:
                        topic_name = f"projects/{settings.GOOGLE_CLOUD_PROJECT_ID}/topics/{settings.PUBSUB_TOPIC_NAME}"
                        gmail_service = GmailEmailService(request.access_token)
                        watch_response = await gmail_service.setup_push_notifications(topic_name)
                        print(f"\n🔔 Gmail Push Notification kuruldu:")
                        print(f"   Topic: {topic_name}")
                        print(f"   History ID: {watch_response.get('historyId')}")
                        print(f"   Expiration: {watch_response.get('expiration')}")
                    else:
                        print(f"\n⚠️  Gmail Push Notification kurulumu atlandı (Pub/Sub yapılandırılmamış)")
                except Exception as e:
                    print(f"\n⚠️  Gmail Push Notification kurulum hatası (devam ediliyor): {e}")
                    import traceback
                    print(traceback.format_exc())
            
            # İlk bağlandığında email'leri çek, tek tek n8n'e gönder, dönen cevap ile Redis'e kaydet
            try:
                print(f"\n🔄 İlk bağlantı - Email'ler çekiliyor, n8n'e gönderiliyor ve Redis'e kaydediliyor...")
                
                if request.provider == "outlook":
                    service = OutlookEmailService(request.access_token)
                elif request.provider == "gmail":
                    service = GmailEmailService(request.access_token)
                else:
                    raise ValueError(f"Bilinmeyen provider: {request.provider}")
                
                # Email'leri çek (tamamını, limit 50)
                emails = await service.fetch_emails(category=None, limit=50)
                
                if emails:
                    print(f"   ✅ {len(emails)} email çekildi")
                    
                    # Tüm email'leri tek tek n8n'e gönder, dönen cevap ile Redis'e kaydet
                    n8n_service = N8nService()
                    processed_count = 0
                    skipped_count = 0
                    
                    print(f"\n   📤 Email'ler n8n'e gönderiliyor...")
                    
                    for email in emails:
                        # Email daha önce işlenmiş mi kontrol et (Redis'te email_tasks key'i var mı?)
                        already_processed = check_email_already_processed(
                            email_id=email.id,
                            provider=request.provider
                        )
                        
                        if already_processed:
                            skipped_count += 1
                            print(f"   ⏭️  [{skipped_count}] Email zaten işlenmiş: {email.subject[:50] if email.subject else 'N/A'}...")
                            continue
                        
                        # Yeni email - n8n'e gönder
                        print(f"   📧 [{processed_count + skipped_count + 1}] n8n'e gönderiliyor: {email.subject[:50] if email.subject else 'N/A'}...")
                        n8n_response = await n8n_service.send_email_for_task_extraction(
                            email=email,
                            provider=request.provider
                        )
                        
                        if n8n_response:
                            # n8n'den dönen cevap ile birlikte email Redis'e kaydedildi: email_tasks:{provider}:{email_id}
                            processed_count += 1
                            print(f"      ✅ Email işlendi ve Redis'e kaydedildi: email_tasks:{request.provider}:{email.id}")
                        else:
                            print(f"      ⚠️ n8n'den yanıt alınamadı")
                    
                    print(f"\n   📊 İşlem özeti: {processed_count} işlendi, {skipped_count} atlandı")
                    print(f"   ✅ Email'ler Redis'te saklandı: email_tasks:{request.provider}:*")
                else:
                    print(f"   ℹ️  Email bulunamadı")
                
                # Son sync tarihini güncelle
                new_account.last_sync_at = datetime.utcnow()
                db.commit()
                
            except Exception as e:
                print(f"   ⚠️  İlk email çekme hatası (background scheduler devam edecek): {e}")
                import traceback
                print(traceback.format_exc())
                # Hata olsa bile account bağlantısı başarılı
            
            print(f"   ✅ Background scheduler otomatik olarak email'leri çekecek")
            
            return {
                "message": "Email account başarıyla bağlandı",
                "account_id": new_account.id,
                "email": new_account.email,
                "provider": new_account.provider,
                "is_connected": new_account.is_connected
            }
            
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        print(f"❌ Email account bağlama hatası: {error_trace}")
        raise HTTPException(
            status_code=500,
            detail=f"Email account bağlama hatası: {str(e)}"
        )


@router.get("/accounts")
async def get_email_accounts(db: Session = Depends(get_db)):
    """Tüm email account'ları listele"""
    try:
        accounts = db.query(EmailAccount).all()
        
        return {
            "accounts": [
                {
                    "id": acc.id,
                    "email": acc.email,
                    "provider": acc.provider,
                    "is_active": acc.is_active,
                    "is_connected": acc.is_connected,
                    "last_sync_at": acc.last_sync_at.isoformat() if acc.last_sync_at else None,
                    "created_at": acc.created_at.isoformat() if acc.created_at else None,
                }
                for acc in accounts
            ]
        }
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Email account listesi hatası: {str(e)}"
        )


@router.get("/check-new-emails")
async def check_new_emails(
    provider: Optional[str] = Query(None, description="Provider filtresi: gmail veya outlook"),
    last_check: Optional[str] = Query(None, description="Son kontrol zamanı (ISO format)")
):
    """
    Yeni email var mı kontrol et (Flutter polling için)
    
    Response:
    {
        "has_new_emails": true,
        "gmail_count": 5,
        "outlook_count": 3,
        "total_count": 8,
        "last_email_timestamp": "2024-01-01T12:00:00Z"
    }
    """
    try:
        from datetime import datetime, timezone
        
        # Redis'ten email'leri al
        gmail_emails = redis_client.get_all_emails(provider="gmail") if not provider or provider == "gmail" else []
        outlook_emails = redis_client.get_all_emails(provider="outlook") if not provider or provider == "outlook" else []
        
        all_emails = gmail_emails + outlook_emails
        
        # last_check parametresi varsa, sadece o zamandan sonraki email'leri say
        new_emails_count = 0
        if last_check:
            try:
                last_check_dt = datetime.fromisoformat(last_check.replace('Z', '+00:00'))
                new_emails = [e for e in all_emails if e.received_date > last_check_dt]
                new_emails_count = len(new_emails)
            except:
                # Parse hatası varsa tüm email'leri say
                new_emails_count = len(all_emails)
        else:
            new_emails_count = len(all_emails)
        
        # Son email'in timestamp'i
        last_email_timestamp = None
        if all_emails:
            sorted_emails = sorted(all_emails, key=lambda x: x.received_date, reverse=True)
            last_email_timestamp = sorted_emails[0].received_date.isoformat()
        
        return {
            "has_new_emails": new_emails_count > 0,
            "gmail_count": len(gmail_emails),
            "outlook_count": len(outlook_emails),
            "total_count": len(all_emails),
            "new_count": new_emails_count,
            "last_email_timestamp": last_email_timestamp
        }
    except Exception as e:
        import traceback
        print(f"❌ Yeni email kontrol hatası: {e}\n{traceback.format_exc()}")
        raise HTTPException(
            status_code=500,
            detail=f"Yeni email kontrol hatası: {str(e)}"
        )


@router.delete("/accounts/{account_id}")
async def disconnect_email_account(
    account_id: int,
    db: Session = Depends(get_db)
):
    """Email account'u bağlantısını kes"""
    try:
        account = db.query(EmailAccount).filter(EmailAccount.id == account_id).first()
        
        if not account:
            raise HTTPException(
                status_code=404,
                detail="Email account bulunamadı"
            )
        
        account.is_active = False
        account.is_connected = False
        db.commit()
        
        print(f"⚠️  Email account bağlantısı kesildi: {account.email}")
        
        return {
            "message": "Email account bağlantısı başarıyla kesildi",
            "account_id": account_id
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(
            status_code=500,
            detail=f"Email account bağlantı kesme hatası: {str(e)}"
        )


def get_access_token(
    authorization: Optional[str] = Header(None),
    access_token: Optional[str] = Query(None)
) -> str:
    """
    Access token'ı header veya query parametresinden al
    Öncelik: Authorization header > Query parametresi
    """
    if authorization:
        # Authorization: Bearer TOKEN formatından token'ı çıkar
        if authorization.startswith("Bearer "):
            return authorization.replace("Bearer ", "")
        return authorization
    
    if access_token:
        return access_token
    
    raise HTTPException(
        status_code=401,
        detail="Access token gerekli. Authorization header veya access_token query parametresi ile gönderin."
    )


@router.get("/outlook", response_model=EmailListResponse)
async def get_outlook_emails(
    token: str = Depends(get_access_token),
    category: Optional[EmailCategory] = Query(None, description="Email kategorisi filtresi (None = tüm kategorilerden çek): inbox, sent, spam, drafts"),
    limit: int = Query(50, ge=1, le=100, description="Kaç email getirilecek (kategori None ise tüm klasörlerden)"),
    db: Session = Depends(get_db)
):
    """
    Outlook'tan email'leri çek (otomatik token yenileme ile)
    
    **Token Gönderme Yöntemleri:**
    1. Authorization Header (Önerilen):
       ```
       Authorization: Bearer YOUR_ACCESS_TOKEN
       ```
    
    2. Query Parametresi:
       ```
       ?access_token=YOUR_ACCESS_TOKEN
       ```
    
    **Kategoriler (Outlook):**
    - `inbox` - Gelen kutusu
    - `sent` - Giden kutusu
    - `spam` - Spam/Junk klasörü
    - `drafts` - Taslaklar
    
    **Örnek:**
    ```bash
    curl -H "Authorization: Bearer TOKEN" \\
         "http://localhost:3000/api/emails/outlook?category=inbox&limit=10"
    ```
    """
    try:
        # ÖNCE Redis'ten kontrol et (email_tasks:{provider}:* key'lerinden email'leri çıkar)
        print("\n" + "="*80)
        print(f"🔍 OUTLOOK EMAİLLER REDIS'TEN KONTROL EDİLİYOR...")
        print("="*80 + "\n")
        
        cached_emails = redis_client.get_all_emails(provider="outlook")
        
        # Redis'teki email'lerin içerik bilgisi var mı kontrol et
        # Eğer hiçbirinde plain_text veya html_content yoksa, eski format demektir
        # Bu durumda API'den yeni verileri çek
        has_content = False
        if cached_emails:
            for email in cached_emails[:5]:  # İlk 5 email'i kontrol et
                if email.plain_text or email.html_content:
                    has_content = True
                    break
        
        if cached_emails and has_content:
            print(f"✅ Redis'ten {len(cached_emails)} email bulundu (içerik bilgisi mevcut)")
            
            # Kategori filtresi varsa uygula
            if category:
                cached_emails = [e for e in cached_emails if e.category == category]
            
            # Limit uygula
            cached_emails = cached_emails[:limit]
            
            print(f"✅ {len(cached_emails)} email Redis'ten döndürülüyor")
            
            return EmailListResponse(
                emails=cached_emails,
                total=len(cached_emails),
                category=category.value if category else "all"
            )
        elif cached_emails and not has_content:
            print(f"⚠️ Redis'te {len(cached_emails)} email var ama içerik bilgisi yok (eski format)")
            print(f"🔄 Yeni verileri API'den çekiyoruz...")
        
        # Redis'te yoksa API'den çek, n8n'e gönder, Redis'e kaydet
        print(f"🔄 Redis'te email yok, API'den çekiliyor...")
        print("="*80 + "\n")
        
        # Outlook servisini oluştur ve email'leri çek
        # Eğer 401 hatası alırsak token'ı yenilemeye çalışacağız
        service = OutlookEmailService(token)
        
        try:
            emails = await service.fetch_emails(category=category, limit=limit)
        except Exception as fetch_error:
            # 401 veya Unauthorized hatası ise token'ı yenilemeyi dene
            if "401" in str(fetch_error) or "unauthorized" in str(fetch_error).lower():
                print(f"⚠️ Token geçersiz, yenileme deneniyor...")
                
                # Token ile ilişkili account'u bul
                account = db.query(EmailAccount).filter(
                    EmailAccount.access_token == token,
                    EmailAccount.provider == "outlook"
                ).first()
                
                if account and account.refresh_token:
                    try:
                        # Token'ı yenile
                        new_token = await TokenRefreshService.get_valid_access_token(account, db)
                        print(f"✅ Token yenilendi, email'ler tekrar çekiliyor...")
                        
                        # Yeni token ile tekrar dene
                        service = OutlookEmailService(new_token)
                        emails = await service.fetch_emails(category=category, limit=limit)
                    except Exception as refresh_error:
                        print(f"❌ Token yenileme hatası: {refresh_error}")
                        raise HTTPException(
                            status_code=401,
                            detail=f"Access token geçersiz ve yenilenemedi. Lütfen Outlook hesabınızı yeniden bağlayın. Hata: {str(refresh_error)}"
                        )
                else:
                    print(f"⚠️ Account bulunamadı veya refresh token yok")
                    raise HTTPException(
                        status_code=401,
                        detail="Access token geçersiz. Lütfen Outlook hesabınızı yeniden bağlayın."
                    )
            else:
                raise
        
        # Şimdilik ekrana yazdır
        print("\n" + "="*80)
        print(f"📧 OUTLOOK - {category.value.upper() if category else 'TÜM KATEGORİLER'} EMAİLLER ({len(emails)} adet)")
        print("="*80)
        for i, email in enumerate(emails, 1):
            print(f"\n{i}. {email.subject}")
            print(f"   Gönderen: {email.sender}")
            print(f"   Tarih: {email.received_date}")
            print(f"   Kategori: {email.category}")
            if email.preview:
                print(f"   Önizleme: {email.preview[:100]}...")
        print("\n" + "="*80 + "\n")
        
        # Response oluştur
        response = EmailListResponse(
            emails=emails,
            total=len(emails),
            category=category.value if category else "all"
        )
        
        # Tüm email'leri tek tek n8n'e gönder, dönen cevap ile Redis'e kaydet
        if emails:
            n8n_service = N8nService()
            processed_count = 0
            skipped_count = 0
            
            print("\n" + "="*80)
            print(f"🔄 {len(emails)} EMAIL İŞLENİYOR (n8n'e gönderiliyor)...")
            print("="*80 + "\n")
            
            for email in emails:
                # Email daha önce işlenmiş mi kontrol et (Redis'te email_tasks key'i var mı?)
                already_processed = check_email_already_processed(
                    email_id=email.id,
                    provider="outlook"
                )
                
                if already_processed:
                    skipped_count += 1
                    print(f"⏭️  [{skipped_count}] Email zaten işlenmiş, atlanıyor: {email.subject[:50] if email.subject else 'N/A'}...")
                    continue
                
                # Yeni email - n8n'e gönder
                print(f"🔄 [{processed_count + skipped_count + 1}] Yeni email n8n'e gönderiliyor: {email.subject[:50] if email.subject else 'N/A'}...")
                n8n_response = await n8n_service.send_email_for_task_extraction(
                    email=email,
                    provider="outlook"
                )
                
                if n8n_response:
                    # n8n'den dönen cevap ile birlikte email Redis'e kaydedildi: email_tasks:outlook:{email_id}
                    processed_count += 1
                    print(f"   ✅ Email işlendi ve Redis'e kaydedildi: email_tasks:outlook:{email.id}")
                else:
                    print(f"   ⚠️ n8n'den yanıt alınamadı")
            
            print("\n" + "="*80)
            print(f"📊 İŞLEM ÖZETİ:")
            print(f"   Toplam Email: {len(emails)}")
            print(f"   İşlenen (n8n'e gönderilen): {processed_count}")
            print(f"   Atlanan (zaten işlenmiş): {skipped_count}")
            print("="*80 + "\n")
        
        return response
    except HTTPException:
        # HTTPException'ları direkt fırlat
        raise
    except Exception as e:
        # Detaylı hata mesajı için traceback yazdır
        import traceback
        error_trace = traceback.format_exc()
        print(f"❌ Email çekme hatası:\n{error_trace}")
        raise HTTPException(
            status_code=500, 
            detail=f"Email çekme hatası: {str(e)}\n\nTraceback:\n{error_trace}"
        )


@router.get("/gmail", response_model=EmailListResponse)
async def get_gmail_emails(
    token: str = Depends(get_access_token),
    category: Optional[EmailCategory] = Query(None, description="Email kategorisi filtresi (None = tüm kategorilerden çek): inbox, sent, spam, drafts, promotions, social, updates, forums"),
    limit: int = Query(50, ge=1, le=100, description="Kaç email getirilecek (kategori None ise tüm kategorilerden)"),
    db: Session = Depends(get_db)
):
    """
    Gmail'den email'leri çek (otomatik token yenileme ile)
    
    **Token Gönderme Yöntemleri:**
    1. Authorization Header (Önerilen):
       ```
       Authorization: Bearer YOUR_ACCESS_TOKEN
       ```
    
    2. Query Parametresi:
       ```
       ?access_token=YOUR_ACCESS_TOKEN
       ```
    
    **Kategoriler (Gmail):**
    - `inbox` - Gelen kutusu
    - `sent` - Giden kutusu
    - `spam` - Spam klasörü
    - `drafts` - Taslaklar
    - `promotions` - Tanıtım kategorisi (promosyonlar, kampanyalar)
    - `social` - Sosyal kategorisi (sosyal medya bildirimleri)
    - `updates` - Güncellemeler (faturalar, bildirimler)
    - `forums` - Forumlar (forum tartışmaları)
    
    **Örnek:**
    ```bash
    # Gelen kutusu
    curl -H "Authorization: Bearer TOKEN" \\
         "http://localhost:3000/api/emails/gmail?category=inbox&limit=10"
    
    # Tanıtım kategorisi
    curl -H "Authorization: Bearer TOKEN" \\
         "http://localhost:3000/api/emails/gmail?category=promotions&limit=10"
    
    # Sosyal kategorisi
    curl -H "Authorization: Bearer TOKEN" \\
         "http://localhost:3000/api/emails/gmail?category=social&limit=10"
    ```
    """
    try:
        # Token geçerliliğini kontrol et ve gerekirse yenile
        # Token'ı header/query'den aldık ama database'deki account'u bulup yenilememiz lazım
        # Şimdilik direkt API'ye gidiyoruz ama 401 hatası alırsak yenileme yapacağız
        
        # ÖNCE Redis'ten kontrol et (email_tasks:{provider}:* key'lerinden email'leri çıkar)
        print("\n" + "="*80)
        print(f"🔍 GMAIL EMAİLLER REDIS'TEN KONTROL EDİLİYOR...")
        print("="*80 + "\n")
        
        cached_emails = redis_client.get_all_emails(provider="gmail")
        
        # Redis'teki email'lerin içerik bilgisi var mı kontrol et
        # Eğer hiçbirinde plain_text veya html_content yoksa, eski format demektir
        # Bu durumda API'den yeni verileri çek
        has_content = False
        if cached_emails:
            for email in cached_emails[:5]:  # İlk 5 email'i kontrol et
                if email.plain_text or email.html_content:
                    has_content = True
                    break
        
        if cached_emails and has_content:
            print(f"✅ Redis'ten {len(cached_emails)} email bulundu (içerik bilgisi mevcut)")
            
            # Kategori filtresi varsa uygula
            if category:
                cached_emails = [e for e in cached_emails if e.category == category]
            
            # Limit uygula
            cached_emails = cached_emails[:limit]
            
            print(f"✅ {len(cached_emails)} email Redis'ten döndürülüyor")
            
            return EmailListResponse(
                emails=cached_emails,
                total=len(cached_emails),
                category=category.value if category else "all"
            )
        elif cached_emails and not has_content:
            print(f"⚠️ Redis'te {len(cached_emails)} email var ama içerik bilgisi yok (eski format)")
            print(f"🔄 Yeni verileri API'den çekiyoruz...")
        
        # Redis'te yoksa API'den çek, n8n'e gönder, Redis'e kaydet
        print(f"🔄 Redis'te email yok, API'den çekiliyor...")
        print("="*80 + "\n")
        
        # Gmail servisini oluştur ve email'leri çek
        # Eğer 401 hatası alırsak token'ı yenilemeye çalışacağız
        service = GmailEmailService(token)
        
        try:
            emails = await service.fetch_emails(category=category, limit=limit)
        except Exception as fetch_error:
            # 401 veya Unauthorized hatası ise token'ı yenilemeyi dene
            if "401" in str(fetch_error) or "unauthorized" in str(fetch_error).lower():
                print(f"⚠️ Token geçersiz, yenileme deneniyor...")
                
                # Token ile ilişkili account'u bul
                account = db.query(EmailAccount).filter(
                    EmailAccount.access_token == token,
                    EmailAccount.provider == "gmail"
                ).first()
                
                if account and account.refresh_token:
                    try:
                        # Token'ı yenile
                        new_token = await TokenRefreshService.get_valid_access_token(account, db)
                        print(f"✅ Token yenilendi, email'ler tekrar çekiliyor...")
                        
                        # Yeni token ile tekrar dene
                        service = GmailEmailService(new_token)
                        emails = await service.fetch_emails(category=category, limit=limit)
                    except Exception as refresh_error:
                        print(f"❌ Token yenileme hatası: {refresh_error}")
                        raise HTTPException(
                            status_code=401,
                            detail=f"Access token geçersiz ve yenilenemedi. Lütfen Gmail hesabınızı yeniden bağlayın. Hata: {str(refresh_error)}"
                        )
                else:
                    print(f"⚠️ Account bulunamadı veya refresh token yok")
                    raise HTTPException(
                        status_code=401,
                        detail="Access token geçersiz. Lütfen Gmail hesabınızı yeniden bağlayın."
                    )
            else:
                raise
        
        # Şimdilik ekrana yazdır
        print("\n" + "="*80)
        print(f"📧 GMAIL - {category.value.upper() if category else 'TÜM KATEGORİLER'} EMAİLLER ({len(emails)} adet)")
        print("="*80)
        
        # Kategori dağılımını göster
        if not category:
            category_counts = {}
            for email in emails:
                # email.category zaten string (use_enum_values=True sayesinde)
                cat = email.category if isinstance(email.category, str) else email.category.value
                category_counts[cat] = category_counts.get(cat, 0) + 1
            print("Kategori Dağılımı:")
            for cat, count in category_counts.items():
                print(f"  - {cat}: {count} adet")
            print("="*80)
        for i, email in enumerate(emails, 1):
            print(f"\n{i}. {email.subject}")
            print(f"   Gönderen: {email.sender}")
            print(f"   Tarih: {email.received_date}")
            print(f"   Kategori: {email.category}")
            if email.preview:
                print(f"   Önizleme: {email.preview[:100]}...")
        print("\n" + "="*80 + "\n")
        
        # Response oluştur
        response = EmailListResponse(
            emails=emails,
            total=len(emails),
            category=category.value if category else "all"
        )
        
        # Tüm email'leri tek tek n8n'e gönder, dönen cevap ile Redis'e kaydet (görev çıkarımı için)
        if emails:
            n8n_service = N8nService()
            processed_count = 0
            skipped_count = 0
            
            print("\n" + "="*80)
            print(f"🔄 {len(emails)} EMAIL İŞLENİYOR (n8n'e gönderiliyor)...")
            print("="*80 + "\n")
            
            for email in emails:
                # Email daha önce işlenmiş mi kontrol et (Redis'te email_tasks key'i var mı?)
                already_processed = check_email_already_processed(
                    email_id=email.id,
                    provider="gmail"
                )
                
                if already_processed:
                    skipped_count += 1
                    print(f"⏭️  [{skipped_count}] Email zaten işlenmiş, atlanıyor: {email.subject[:50]}...")
                    continue
                
                # Yeni email - n8n'e gönder
                print(f"🔄 [{processed_count + skipped_count + 1}] Yeni email n8n'e gönderiliyor: {email.subject[:50] if email.subject else 'N/A'}...")
                n8n_response = await n8n_service.send_email_for_task_extraction(
                    email=email,
                    provider="gmail"
                )
                
                if n8n_response:
                    # n8n'den dönen cevap ile birlikte email Redis'e kaydedildi (n8n_service içinde)
                    processed_count += 1
                    print(f"   ✅ Email işlendi ve Redis'e kaydedildi: email_tasks:gmail:{email.id}")
                else:
                    print(f"   ⚠️ n8n'den yanıt alınamadı")
            
            print("\n" + "="*80)
            print(f"📊 İŞLEM ÖZETİ:")
            print(f"   Toplam Email: {len(emails)}")
            print(f"   İşlenen (n8n'e gönderilen): {processed_count}")
            print(f"   Atlanan (zaten işlenmiş): {skipped_count}")
            print("="*80 + "\n")
        
        return response
    except HTTPException:
        # HTTPException'ları direkt fırlat
        raise
    except Exception as e:
        # Detaylı hata mesajı için traceback yazdır
        import traceback
        error_trace = traceback.format_exc()
        print(f"❌ Gmail email çekme hatası:\n{error_trace}")
        raise HTTPException(
            status_code=500, 
            detail=f"Email çekme hatası: {str(e)}\n\nTraceback:\n{error_trace}"
        )


# ==================== GMAIL ENDPOINTS ====================

@router.post("/gmail/send", response_model=Email)
async def send_gmail_email(
    request: SendEmailRequest,
    token: str = Depends(get_access_token)
):
    """Gmail üzerinden email gönder"""
    try:
        service = GmailEmailService(token)
        email = await service.send_email(
            to_emails=request.to_emails,
            subject=request.subject,
            plain_text=request.plain_text,
            html_content=request.html_content,
            cc_emails=request.cc_emails,
            bcc_emails=request.bcc_emails,
        )
        return email
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Email gönderme hatası: {str(e)}\n\nTraceback:\n{error_trace}"
        )


@router.post("/gmail/{message_id}/mark-read", response_model=Email)
async def mark_gmail_as_read(
    message_id: str,
    token: str = Depends(get_access_token)
):
    """Gmail email'i okundu olarak işaretle"""
    try:
        service = GmailEmailService(token)
        email = await service.mark_as_read(message_id)
        return email
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Email okundu işaretleme hatası: {str(e)}\n\nTraceback:\n{error_trace}"
        )


@router.post("/gmail/{message_id}/mark-unread", response_model=Email)
async def mark_gmail_as_unread(
    message_id: str,
    token: str = Depends(get_access_token)
):
    """Gmail email'i okunmamış olarak işaretle"""
    try:
        service = GmailEmailService(token)
        email = await service.mark_as_unread(message_id)
        return email
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Email okunmamış işaretleme hatası: {str(e)}\n\nTraceback:\n{error_trace}"
        )


@router.post("/gmail/{message_id}/toggle-important", response_model=Email)
async def toggle_gmail_important(
    message_id: str,
    request: ToggleImportantRequest,
    token: str = Depends(get_access_token)
):
    """Gmail email'i önemli olarak işaretle/kaldır"""
    try:
        service = GmailEmailService(token)
        email = await service.toggle_important(message_id, request.is_important)
        return email
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Email önemli işaretleme hatası: {str(e)}\n\nTraceback:\n{error_trace}"
        )


@router.delete("/gmail/{message_id}")
async def delete_gmail_email(
    message_id: str,
    token: str = Depends(get_access_token)
):
    """Gmail email'i sil"""
    try:
        service = GmailEmailService(token)
        await service.delete_email(message_id)
        return {"message": "Email başarıyla silindi"}
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Email silme hatası: {str(e)}\n\nTraceback:\n{error_trace}"
        )


@router.post("/gmail/drafts", response_model=Email)
async def save_gmail_draft(
    request: SaveDraftRequest,
    token: str = Depends(get_access_token)
):
    """Gmail email taslağı kaydet/güncelle"""
    try:
        service = GmailEmailService(token)
        email = await service.save_draft(
            subject=request.subject,
            plain_text=request.plain_text,
            html_content=request.html_content,
            to_emails=request.to_emails,
            cc_emails=request.cc_emails,
            bcc_emails=request.bcc_emails,
            draft_id=request.draft_id,
        )
        return email
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Email taslağı kaydetme hatası: {str(e)}\n\nTraceback:\n{error_trace}"
        )


# ==================== OUTLOOK ENDPOINTS ====================

@router.post("/outlook/send", response_model=Email)
async def send_outlook_email(
    request: SendEmailRequest,
    token: str = Depends(get_access_token)
):
    """Outlook üzerinden email gönder"""
    try:
        service = OutlookEmailService(token)
        email = await service.send_email(
            to_emails=request.to_emails,
            subject=request.subject,
            plain_text=request.plain_text,
            html_content=request.html_content,
            cc_emails=request.cc_emails,
            bcc_emails=request.bcc_emails,
        )
        return email
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Email gönderme hatası: {str(e)}\n\nTraceback:\n{error_trace}"
        )


@router.post("/outlook/{message_id}/mark-read", response_model=Email)
async def mark_outlook_as_read(
    message_id: str,
    token: str = Depends(get_access_token)
):
    """Outlook email'i okundu olarak işaretle"""
    try:
        service = OutlookEmailService(token)
        email = await service.mark_as_read(message_id)
        return email
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Email okundu işaretleme hatası: {str(e)}\n\nTraceback:\n{error_trace}"
        )


@router.post("/outlook/{message_id}/mark-unread", response_model=Email)
async def mark_outlook_as_unread(
    message_id: str,
    token: str = Depends(get_access_token)
):
    """Outlook email'i okunmamış olarak işaretle"""
    try:
        service = OutlookEmailService(token)
        email = await service.mark_as_unread(message_id)
        return email
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Email okunmamış işaretleme hatası: {str(e)}\n\nTraceback:\n{error_trace}"
        )


@router.post("/outlook/{message_id}/toggle-important", response_model=Email)
async def toggle_outlook_important(
    message_id: str,
    request: ToggleImportantRequest,
    token: str = Depends(get_access_token)
):
    """Outlook email'i önemli olarak işaretle/kaldır"""
    try:
        service = OutlookEmailService(token)
        email = await service.toggle_important(message_id, request.is_important)
        return email
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Email önemli işaretleme hatası: {str(e)}\n\nTraceback:\n{error_trace}"
        )


@router.delete("/outlook/{message_id}")
async def delete_outlook_email(
    message_id: str,
    token: str = Depends(get_access_token)
):
    """Outlook email'i sil"""
    try:
        service = OutlookEmailService(token)
        await service.delete_email(message_id)
        return {"message": "Email başarıyla silindi"}
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Email silme hatası: {str(e)}\n\nTraceback:\n{error_trace}"
        )


@router.post("/outlook/drafts", response_model=Email)
async def save_outlook_draft(
    request: SaveDraftRequest,
    token: str = Depends(get_access_token)
):
    """Outlook email taslağı kaydet/güncelle"""
    try:
        service = OutlookEmailService(token)
        email = await service.save_draft(
            subject=request.subject,
            plain_text=request.plain_text,
            html_content=request.html_content,
            to_emails=request.to_emails,
            cc_emails=request.cc_emails,
            bcc_emails=request.bcc_emails,
            draft_id=request.draft_id,
        )
        return email
    except HTTPException:
        raise
    except Exception as e:
        import traceback
        error_trace = traceback.format_exc()
        raise HTTPException(
            status_code=500,
            detail=f"Email taslağı kaydetme hatası: {str(e)}\n\nTraceback:\n{error_trace}"
        )
