"""
Redis client - Task extraction ve email cache yönetimi
"""
import redis
import json
from typing import Optional, Dict, Any, List
from app.core.config import settings
from app.models.email_schemas import Email


class RedisClient:
    """Redis client wrapper"""
    
    def __init__(self):
        """Redis client'ı başlat"""
        self.client = None
        self._connect()
    
    def _connect(self):
        """Redis'e bağlan"""
        try:
            if settings.REDIS_URL:
                self.client = redis.from_url(settings.REDIS_URL, decode_responses=False)
                # Bağlantıyı test et
                self.client.ping()
                print("✅ Redis bağlantısı başarılı")
            else:
                print("⚠️ REDIS_URL yapılandırılmamış, Redis devre dışı")
        except Exception as e:
            print(f"⚠️ Redis bağlantı hatası: {e}")
            self.client = None
    
    def is_connected(self) -> bool:
        """Redis bağlantısı var mı?"""
        if not self.client:
            return False
        try:
            self.client.ping()
            return True
        except:
            return False
    
    def save_task_extraction(
        self,
        email_id: str,
        provider: str,
        email_data: Dict[str, Any],
        task_data: Dict[str, Any],
        ttl: int = 604800  # 1 hafta (7 gün)
    ) -> bool:
        """
        Email ve görev çıkarımı verisini Redis'e kaydet
        Key: email_tasks:{provider}:{email_id}
        
        Args:
            email_id: Email ID
            provider: Email provider ("gmail" veya "outlook")
            email_data: Email verisi (dict)
            task_data: n8n'den dönen görev çıkarımı verisi (dict)
            ttl: Time to live (saniye)
            
        Returns:
            True ise başarılı, False ise hata
        """
        if not self.is_connected():
            return False
        
        try:
            # Email ve görev verisini birleştir
            combined_data = {
                "email": email_data,  # Email verisi
                "task_data": task_data,  # n8n'den dönen görev çıkarımı
                "provider": provider,  # Provider bilgisi
                "email_id": email_id  # Email ID
            }
            
            # Redis key oluştur: email_tasks:{provider}:{email_id}
            key = f"email_tasks:{provider}:{email_id}"
            
            # JSON olarak kaydet
            value = json.dumps(combined_data, ensure_ascii=False, default=str)
            
            # Redis'e kaydet (TTL ile)
            self.client.setex(key, ttl, value)
            
            print(f"✅ Redis'e kaydedildi: {key}")
            print(f"   Email: {email_data.get('subject', 'N/A')[:50]}...")
            
            # Görev bilgisini yazdır
            if isinstance(task_data, dict):
                if "cevap" in task_data and isinstance(task_data["cevap"], list) and len(task_data["cevap"]) > 0:
                    first_task = task_data["cevap"][0]
                    task_title = first_task.get("baslik", first_task.get("kullanici_mesaji", "N/A"))
                    print(f"   Görev: {task_title[:50]}...")
                elif "summary" in task_data:
                    print(f"   Görev: {task_data.get('summary', 'N/A')[:50]}...")
                else:
                    print(f"   Görev: {str(task_data)[:50]}...")
            else:
                print(f"   Görev: {str(task_data)[:50]}...")
            
            print(f"   TTL: {ttl} saniye ({ttl/3600:.1f} saat)")
            
            return True
            
        except Exception as e:
            print(f"❌ Redis'e kaydetme hatası: {e}")
            import traceback
            print(traceback.format_exc())
            return False
    
    def get_task_extraction(
        self,
        email_id: str,
        provider: str
    ) -> Optional[Dict[str, Any]]:
        """
        Redis'ten email ve görev çıkarımı verisini al
        Key: email_tasks:{provider}:{email_id}
        
        Args:
            email_id: Email ID
            provider: Email provider ("gmail" veya "outlook")
            
        Returns:
            Dict içinde email ve task_data veya None
        """
        if not self.is_connected():
            return None
        
        try:
            key = f"email_tasks:{provider}:{email_id}"
            value = self.client.get(key)
            
            if value:
                return json.loads(value)
            return None
            
        except Exception as e:
            print(f"❌ Redis'ten okuma hatası: {e}")
            return None
    
    def get_all_tasks(
        self,
        provider: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Redis'ten tüm görev çıkarımlarını al
        
        Args:
            provider: Provider filtresi (None ise tüm provider'lar)
            
        Returns:
            Görev listesi
        """
        if not self.is_connected():
            return []
        
        try:
            pattern = f"email_tasks:{provider}:*" if provider else "email_tasks:*:*"
            keys = self.client.keys(pattern)
            
            tasks = []
            for key in keys:
                value = self.client.get(key)
                if value:
                    tasks.append(json.loads(value))
            
            return tasks
            
        except Exception as e:
            print(f"❌ Redis'ten tüm görevleri alma hatası: {e}")
            return []
    
    def get_emails_by_date_range(
        self,
        start_date: str,
        end_date: str,
        provider: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Redis'ten tarih aralığına göre email ve task verilerini al
        
        Args:
            start_date: Başlangıç tarihi (ISO 8601 format: 2025-12-25T00:00:00.000Z)
            end_date: Bitiş tarihi (ISO 8601 format: 2025-12-25T23:59:59.999Z)
            provider: Provider filtresi (None ise tüm provider'lar)
            
        Returns:
            Tarih aralığına uyan email ve task verileri listesi
        """
        if not self.is_connected():
            return []
        
        try:
            from datetime import datetime
            
            # Tarih parse et
            start_dt = datetime.fromisoformat(start_date.replace("Z", "+00:00"))
            end_dt = datetime.fromisoformat(end_date.replace("Z", "+00:00"))
            
            pattern = f"email_tasks:{provider}:*" if provider else "email_tasks:*:*"
            keys = self.client.keys(pattern)
            
            results = []
            for key in keys:
                value = self.client.get(key)
                if value:
                    try:
                        data = json.loads(value)
                        email_data = data.get("email", {})
                        
                        # Email tarihini al
                        received_date_str = email_data.get("received_date", "")
                        if not received_date_str:
                            continue
                        
                        # Tarih parse et
                        try:
                            if isinstance(received_date_str, str):
                                email_dt = datetime.fromisoformat(received_date_str.replace("Z", "+00:00"))
                            else:
                                continue
                        except (ValueError, TypeError):
                            continue
                        
                        # Tarih filtresi uygula
                        if start_dt <= email_dt <= end_dt:
                            results.append({
                                "email_id": data.get("email_id", ""),
                                "provider": data.get("provider", ""),
                                "email": email_data,
                                "task_data": data.get("task_data", {}),
                                "received_date": received_date_str
                            })
                    except json.JSONDecodeError:
                        continue
            
            # Tarihe göre sırala (yeniden eskiye)
            results.sort(key=lambda x: x.get("received_date", ""), reverse=True)
            
            print(f"📧 Tarih aralığı sorgusu: {start_date} - {end_date}")
            print(f"   Provider: {provider or 'all'}")
            print(f"   Bulunan email sayısı: {len(results)}")
            
            return results
            
        except Exception as e:
            print(f"❌ Redis tarih bazlı email alma hatası: {e}")
            import traceback
            print(traceback.format_exc())
            return []
    
    def get_all_emails(
        self,
        provider: str
    ) -> List[Email]:
        """
        Redis'ten tüm email'leri al (email_tasks key'lerinden)
        Flutter için email listesi döndürür
        
        Args:
            provider: Email provider ("gmail" veya "outlook")
            
        Returns:
            Email listesi
        """
        if not self.is_connected():
            return []
        
        try:
            pattern = f"email_tasks:{provider}:*"
            keys = self.client.keys(pattern)
            
            emails = []
            for key in keys:
                value = self.client.get(key)
                if value:
                    data = json.loads(value)
                    email_data = data.get("email", {})
                    
                    # Email objesine çevir
                    try:
                        # Email modeline uygun formata çevir
                        email_dict = {
                            "id": email_data.get("email_id", ""),
                            "subject": email_data.get("subject", "(Konu yok)"),
                            "sender": email_data.get("from", ""),
                            "recipient": email_data.get("to", ""),
                            "preview": email_data.get("body", ""),
                            "plain_text": email_data.get("plain_text"),
                            "html_content": email_data.get("html_content"),
                            "received_date": email_data.get("received_date", ""),
                            "is_read": email_data.get("is_read", False),
                            "category": email_data.get("category", "inbox"),
                            "has_attachments": email_data.get("has_attachments", False)
                        }
                        
                        # received_date string ise parse et
                        if isinstance(email_dict["received_date"], str):
                            from datetime import datetime
                            email_dict["received_date"] = datetime.fromisoformat(
                                email_dict["received_date"].replace("Z", "+00:00")
                            )
                        
                        email = Email(**email_dict)
                        emails.append(email)
                    except Exception as e:
                        print(f"⚠️ Email parse hatası ({key}): {e}")
                        continue
            
            return emails
            
        except Exception as e:
            print(f"❌ Redis'ten email listesi alma hatası: {e}")
            import traceback
            print(traceback.format_exc())
            return []


redis_client = RedisClient()
