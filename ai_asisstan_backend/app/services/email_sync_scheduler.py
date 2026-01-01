"""
Email Sync Scheduler - Background email sync servisi
UI açık değilken bile email'leri çeker
"""
import asyncio
from datetime import datetime, timezone
from typing import List
from apscheduler.schedulers.asyncio import AsyncIOScheduler
from apscheduler.triggers.interval import IntervalTrigger
from sqlalchemy.orm import Session
from app.core.database import SessionLocal
from app.models.email_account import EmailAccount
from app.services.gmail_email_service import GmailEmailService
from app.services.outlook_email_service import OutlookEmailService
from app.services.n8n_service import N8nService, check_email_already_processed
from app.services.token_refresh_service import TokenRefreshService
from app.core.redis_client import redis_client


class EmailSyncScheduler:
    """Email senkronizasyon scheduler'ı"""
    
    def __init__(self):
        self.scheduler = AsyncIOScheduler()
        self.sync_interval_minutes = 5  # Her 5 dakikada bir sync
    
    def start(self):
        """Scheduler'ı başlat"""
        # Her 5 dakikada bir sync job'u ekle
        self.scheduler.add_job(
            self.sync_all_accounts,
            trigger=IntervalTrigger(minutes=self.sync_interval_minutes),
            id='email_sync_job',
            name='Email Sync Job',
            replace_existing=True
        )
        
        self.scheduler.start()
        print("\n" + "="*80)
        print("✅ Email Sync Scheduler başlatıldı")
        print(f"   Sync interval: {self.sync_interval_minutes} dakika")
        print("="*80 + "\n")
    
    def stop(self):
        """Scheduler'ı durdur"""
        self.scheduler.shutdown()
        print("⚠️ Email Sync Scheduler durduruldu")
    
    async def sync_all_accounts(self):
        """
        Tüm aktif ve entegre olan email account'ları için email'leri çek
        """
        print("\n" + "="*80)
        print(f"🔄 BACKGROUND EMAIL SYNC BAŞLADI - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print("="*80 + "\n")
        
        db = SessionLocal()
        try:
            # Aktif ve entegre olan tüm email account'ları çek
            accounts = db.query(EmailAccount).filter(
                EmailAccount.is_active == True,
                EmailAccount.is_connected == True
            ).all()
            
            if not accounts:
                print("ℹ️  Aktif ve entegre email account bulunamadı")
                return
            
            print(f"📧 {len(accounts)} aktif email account bulundu")
            
            for account in accounts:
                try:
                    await self.sync_account(account, db)
                except Exception as e:
                    print(f"❌ Account {account.email} sync hatası: {e}")
                    continue
            
            print("\n" + "="*80)
            print("✅ BACKGROUND EMAIL SYNC TAMAMLANDI")
            print("="*80 + "\n")
            
        except Exception as e:
            print(f"❌ Background sync genel hatası: {e}")
        finally:
            db.close()
    
    async def sync_account(self, account: EmailAccount, db: Session):
        """
        Tek bir email account için email'leri çek ve işle
        
        Args:
            account: EmailAccount modeli
            db: Database session
        """
        if not account.access_token:
            print(f"⚠️  Account {account.email} için access token yok, atlanıyor")
            return
        
        print(f"\n📧 Account sync başlıyor: {account.email} ({account.provider})")
        
        try:
            # ÖNCE token'ı kontrol et ve gerekirse yenile
            try:
                access_token = await TokenRefreshService.get_valid_access_token(account, db)
                print(f"   ✅ Token geçerli veya yenilendi")
            except Exception as token_error:
                print(f"   ❌ Token yenileme hatası: {token_error}")
                print(f"   ⚠️  Account {account.email} atlanıyor (token geçersiz)")
                return
            
            # Provider'a göre servis seç (yenilenmiş token ile)
            if account.provider == "gmail":
                service = GmailEmailService(access_token)
            elif account.provider == "outlook":
                service = OutlookEmailService(access_token)
            else:
                print(f"⚠️  Bilinmeyen provider: {account.provider}")
                return
            
            # Email'leri çek (inbox'dan, limit 50)
            emails = await service.fetch_emails(category=None, limit=50)
            
            if not emails:
                print(f"   ℹ️  Email bulunamadı")
                return
            
            print(f"   ✅ {len(emails)} email çekildi")
            
            # Tüm email'leri tek tek n8n'e gönder, dönen cevap ile Redis'e kaydet
            n8n_service = N8nService()
            processed_count = 0
            skipped_count = 0
            
            print(f"   📤 Email'ler n8n'e gönderiliyor...")
            
            for email in emails:
                # Email daha önce işlenmiş mi kontrol et (Redis'te email_tasks key'i var mı?)
                already_processed = check_email_already_processed(
                    email_id=email.id,
                    provider=account.provider
                )
                
                if already_processed:
                    skipped_count += 1
                    continue
                
                # Yeni email - n8n'e gönder
                n8n_response = await n8n_service.send_email_for_task_extraction(
                    email=email,
                    provider=account.provider
                )
                
                if n8n_response:
                    # n8n'den dönen cevap ile birlikte email Redis'e kaydedildi: email_tasks:{provider}:{email_id}
                    processed_count += 1
            
            # Son sync tarihini güncelle
            account.last_sync_at = datetime.now(timezone.utc)
            db.commit()
            
            print(f"   📊 İşlem özeti: {processed_count} işlendi, {skipped_count} atlandı")
            
        except Exception as e:
            print(f"   ❌ Sync hatası: {e}")
            # Token expire olmuş olabilir, yenilemeyi dene
            if "401" in str(e) or "unauthorized" in str(e).lower() or "token" in str(e).lower():
                print(f"   🔄 Token hatası tespit edildi, yenileme deneniyor...")
                try:
                    access_token = await TokenRefreshService.get_valid_access_token(account, db)
                    print(f"   ✅ Token yenilendi, sync tekrar deneniyor...")
                    
                    # Yeni token ile servisi yeniden oluştur
                    if account.provider == "gmail":
                        service = GmailEmailService(access_token)
                    elif account.provider == "outlook":
                        service = OutlookEmailService(access_token)
                    else:
                        return
                    
                    # Email'leri tekrar çek
                    emails = await service.fetch_emails(category=None, limit=50)
                    
                    if not emails:
                        print(f"   ℹ️  Email bulunamadı")
                        return
                    
                    print(f"   ✅ {len(emails)} email çekildi (token yenilendikten sonra)")
                    
                    # Email'leri işle
                    n8n_service = N8nService()
                    processed_count = 0
                    skipped_count = 0
                    
                    for email in emails:
                        already_processed = check_email_already_processed(
                            email_id=email.id,
                            provider=account.provider
                        )
                        
                        if already_processed:
                            skipped_count += 1
                            continue
                        
                        n8n_response = await n8n_service.send_email_for_task_extraction(
                            email=email,
                            provider=account.provider
                        )
                        
                        if n8n_response:
                            processed_count += 1
                    
                    # Son sync tarihini güncelle
                    account.last_sync_at = datetime.now(timezone.utc)
                    db.commit()
                    
                    print(f"   📊 İşlem özeti (token yenileme sonrası): {processed_count} işlendi, {skipped_count} atlandı")
                    
                except Exception as refresh_error:
                    print(f"   ❌ Token yenileme başarısız: {refresh_error}")
                    # Token yenilenemedi, account'u pasif yap
                    account.is_active = False
                    db.commit()
                    print(f"   ⚠️  Account pasif yapıldı (token yenilenemedi)")


# Global scheduler instance
email_sync_scheduler = EmailSyncScheduler()

