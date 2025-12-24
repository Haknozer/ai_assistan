"""
Google Cloud Pub/Sub Servisi - Email çekme tetikleyicisi
"""
import json
import asyncio
from typing import Optional, Dict, Any
from app.core.config import settings
from app.services.outlook_email_service import OutlookEmailService
from app.services.gmail_email_service import GmailEmailService
from app.services.n8n_service import N8nService
import traceback

# Pub/Sub import'u (optional - paket yüklü değilse None olacak)
try:
    from google.cloud import pubsub_v1
    from google.auth import default
    PUBSUB_AVAILABLE = True
except ImportError:
    PUBSUB_AVAILABLE = False
    pubsub_v1 = None  # Type hint'ler için
    print("⚠️ google-cloud-pubsub paketi yüklü değil. Pub/Sub özelliği devre dışı.")
    print("   Yüklemek için: pip install google-cloud-pubsub")


class PubSubService:
    """Google Cloud Pub/Sub subscriber servisi"""
    
    def __init__(self):
        self.project_id = settings.GOOGLE_CLOUD_PROJECT_ID
        self.subscription_name = settings.PUBSUB_SUBSCRIPTION_NAME
        self.topic_name = settings.PUBSUB_TOPIC_NAME
        
        # Pub/Sub client'ları
        self.subscriber: Optional[Any] = None
        self.publisher: Optional[Any] = None
        
        # Servisler
        self.n8n_service = N8nService()
        
        # Çalışma durumu
        self._is_running = False
        
    def _initialize_clients(self):
        """Pub/Sub client'larını başlat"""
        try:
            if not PUBSUB_AVAILABLE:
                print("⚠️ google-cloud-pubsub paketi yüklü değil, Pub/Sub devre dışı")
                return False
            
            if not self.project_id:
                print("⚠️ GOOGLE_CLOUD_PROJECT_ID yapılandırılmamış, Pub/Sub devre dışı")
                return False
            
            # Credentials kontrolü
            if settings.GOOGLE_APPLICATION_CREDENTIALS:
                import os
                os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = settings.GOOGLE_APPLICATION_CREDENTIALS
            
            # Default credentials kullan (service account veya gcloud auth)
            credentials, project = default()
            
            self.subscriber = pubsub_v1.SubscriberClient(credentials=credentials)
            self.publisher = pubsub_v1.PublisherClient(credentials=credentials)
            
            print(f"✅ Pub/Sub client'ları başlatıldı: Project={self.project_id}")
            return True
            
        except Exception as e:
            print(f"❌ Pub/Sub client başlatma hatası: {e}")
            print(f"   Traceback: {traceback.format_exc()}")
            return False
    
    def _get_subscription_path(self) -> str:
        """Subscription path'ini döndür"""
        if not self.subscriber:
            raise RuntimeError("Subscriber client başlatılmamış")
        return self.subscriber.subscription_path(self.project_id, self.subscription_name)
    
    def _get_topic_path(self) -> str:
        """Topic path'ini döndür"""
        if not self.publisher:
            raise RuntimeError("Publisher client başlatılmamış")
        return self.publisher.topic_path(self.project_id, self.topic_name)
    
    async def _process_message(self, message: Any):
        """
        Pub/Sub mesajını işle ve email'leri çek
        
        Beklenen mesaj formatları:
        
        1. Manuel trigger (eski format):
        {
            "provider": "gmail" | "outlook",
            "access_token": "...",
            "user_id": "...",  # opsiyonel
            "email": "...",    # opsiyonel
            "limit": 50        # opsiyonel, default 50
        }
        
        2. Gmail Push Notification (yeni format):
        {
            "emailAddress": "user@gmail.com",
            "historyId": "1234567"
        }
        """
        try:
            # Mesajı parse et
            message_data = json.loads(message.data.decode('utf-8'))
            
            # Gmail Push Notification formatı mı kontrol et
            if 'emailAddress' in message_data and 'historyId' in message_data:
                print("\n" + "="*80)
                print(f"🔔 Gmail Push Notification alındı!")
                print("="*80)
                print(f"Email: {message_data.get('emailAddress')}")
                print(f"History ID: {message_data.get('historyId')}")
                print("="*80 + "\n")
                
                # Gmail hesabını database'den bul
                email_address = message_data.get('emailAddress')
                
                # Database'den email account bilgilerini çek
                from app.core.database import SessionLocal
                from app.models.email_account import EmailAccount
                
                db = SessionLocal()
                try:
                    account = db.query(EmailAccount).filter(
                        EmailAccount.email == email_address,
                        EmailAccount.provider == "gmail",
                        EmailAccount.is_active == True
                    ).first()
                    
                    if not account:
                        print(f"⚠️  Gmail account bulunamadı: {email_address}")
                        message.ack()
                        return
                    
                    # Account bilgilerini kullanarak email'leri çek
                    provider = "gmail"
                    access_token = account.access_token
                    user_id = account.user_id
                    limit = 50
                    
                    print(f"✅ Gmail account bulundu: {email_address}")
                    print(f"   Account ID: {account.id}")
                    print(f"   User ID: {user_id}")
                    
                finally:
                    db.close()
            else:
                # Manuel trigger formatı (eski format)
                provider = message_data.get('provider', '').lower()
                access_token = message_data.get('access_token', '')
                user_id = message_data.get('user_id')
                email_address = message_data.get('email')
                limit = message_data.get('limit', 50)

                
                print("\n" + "="*80)
                print(f"📨 Pub/Sub mesajı alındı (manuel): {provider.upper()}")
                print("="*80)
                print(f"Provider: {provider}")
                print(f"User ID: {user_id}")
                print(f"Email: {email_address}")
                print(f"Limit: {limit}")
                print("="*80 + "\n")
            
            if not access_token:
                print("❌ Access token bulunamadı, mesaj atlanıyor")
                message.ack()
                return
            
            if provider not in ['gmail', 'outlook']:
                print(f"❌ Geçersiz provider: {provider}")
                message.ack()
                return
            
            # Email'leri çek
            if provider == 'gmail':
                service = GmailEmailService(access_token)
            else:
                service = OutlookEmailService(access_token)
            
            # Tüm kategorilerden email'leri çek
            emails = await service.fetch_emails(category=None, limit=limit)
            
            print(f"\n✅ {len(emails)} email çekildi ({provider})")
            
            # Her email için n8n'e gönder ve Redis'e kaydet
            processed_count = 0
            for email in emails:
                try:
                    n8n_response = await self.n8n_service.send_email_for_task_extraction(
                        email=email,
                        provider=provider
                    )
                    if n8n_response:
                        processed_count += 1
                except Exception as e:
                    print(f"⚠️ Email işleme hatası ({email.id}): {e}")
                    continue
            
            print(f"\n✅ {processed_count}/{len(emails)} email başarıyla işlendi ve Redis'e kaydedildi")
            
            # Mesajı acknowledge et
            message.ack()
            
            print("\n" + "="*80)
            print("✅ Pub/Sub mesajı başarıyla işlendi")
            print("="*80 + "\n")
            
        except json.JSONDecodeError as e:
            print(f"❌ Mesaj parse hatası: {e}")
            message.ack()  # Geçersiz mesajı da ack et (sonsuz döngüye girmesin)
        except Exception as e:
            print(f"❌ Mesaj işleme hatası: {e}")
            print(f"   Traceback: {traceback.format_exc()}")
            message.nack()  # Hata durumunda mesajı geri gönder (retry için)
    
    def _callback(self, message):
        """Pub/Sub callback fonksiyonu (async wrapper)"""
        try:
            # Async fonksiyonu sync callback'te çalıştır
            loop = asyncio.new_event_loop()
            asyncio.set_event_loop(loop)
            loop.run_until_complete(self._process_message(message))
            loop.close()
        except Exception as e:
            print(f"❌ Callback hatası: {e}")
            try:
                message.nack()
            except:
                pass
    
    def start_listening(self):
        """Pub/Sub subscription'ı dinlemeye başla"""
        if not PUBSUB_AVAILABLE:
            print("⚠️ google-cloud-pubsub paketi yüklü değil, Pub/Sub dinleme başlatılamıyor")
            return
        
        if self._is_running:
            print("⚠️ Pub/Sub zaten dinleniyor")
            return
        
        if not self._initialize_clients():
            print("⚠️ Pub/Sub client'ları başlatılamadı, dinleme başlatılamıyor")
            return
        
        if not self.subscriber:
            print("❌ Subscriber client yok")
            return
        
        try:
            subscription_path = self._get_subscription_path()
            
            print("\n" + "="*80)
            print("🚀 Pub/Sub dinleme başlatılıyor...")
            print("="*80)
            print(f"Project ID: {self.project_id}")
            print(f"Subscription: {self.subscription_name}")
            print(f"Subscription Path: {subscription_path}")
            print("="*80 + "\n")
            
            # Subscription'ı dinle
            streaming_pull_future = self.subscriber.subscribe(
                subscription_path,
                callback=self._callback
            )
            
            self._is_running = True
            
            print("✅ Pub/Sub dinleme başlatıldı, mesajlar bekleniyor...")
            
            # Streaming pull future'ı tut (sonsuz döngü)
            try:
                streaming_pull_future.result()
            except KeyboardInterrupt:
                streaming_pull_future.cancel()
                self._is_running = False
                print("\n⚠️ Pub/Sub dinleme durduruldu")
            
        except Exception as e:
            error_msg = str(e)
            print(f"\n❌ Pub/Sub dinleme başlatma hatası: {error_msg}")
            
            # Yetkilendirme hatası için özel mesaj
            if "403" in error_msg or "PermissionDenied" in error_msg or "not authorized" in error_msg.lower():
                print("\n" + "="*80)
                print("🔴 YETKİLENDİRME HATASI")
                print("="*80)
                print("Service Account'unuzun Pub/Sub erişim izni yok!")
                print("\nÇözüm:")
                print("1. Google Cloud Console → IAM & Admin → Service Accounts")
                print("2. JSON key dosyanızın ait olduğu Service Account'u bulun")
                print("3. Service Account'a şu rolleri verin:")
                print("   - Pub/Sub Subscriber (roles/pubsub.subscriber)")
                print("   - Pub/Sub Publisher (roles/pubsub.publisher) - opsiyonel")
                print("\nDetaylı rehber için: PUBSUB_YETKI_SORUNU.md dosyasına bakın")
                print("="*80 + "\n")
            else:
                print(f"   Traceback: {traceback.format_exc()}")
            
            self._is_running = False
    
    def stop_listening(self):
        """Pub/Sub dinlemeyi durdur"""
        self._is_running = False
        print("⚠️ Pub/Sub dinleme durduruldu")
    
    def publish_message(self, data: Dict[str, Any]) -> Optional[str]:
        """
        Pub/Sub topic'ine mesaj gönder (test için)
        
        Args:
            data: Gönderilecek mesaj verisi
            
        Returns:
            Message ID veya None
        """
        if not self.publisher:
            if not self._initialize_clients():
                return None
        
        try:
            topic_path = self._get_topic_path()
            message_data = json.dumps(data).encode('utf-8')
            
            future = self.publisher.publish(topic_path, message_data)
            message_id = future.result()
            
            print(f"✅ Mesaj gönderildi: Message ID={message_id}")
            return message_id
            
        except Exception as e:
            print(f"❌ Mesaj gönderme hatası: {e}")
            return None

