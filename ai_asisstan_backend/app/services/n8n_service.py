"""
n8n Webhook Servisi - Email'leri n8n'e gönderme ve görev çıkarımı
"""
import httpx
import json
from typing import Optional, Dict, Any, List
from app.models.email_schemas import Email
from app.core.config import settings
from app.core.redis_client import redis_client


def check_email_already_processed(email_id: str, provider: str) -> bool:
    """
    Email'in daha önce işlenip işlenmediğini kontrol et (Redis'te geçerli veri var mı?)
    
    Args:
        email_id: Email ID
        provider: Email provider ("gmail" veya "outlook")
        
    Returns:
        True ise email zaten işlenmiş VE geçerli veri var, False ise yeni email veya boş veri
    """
    if not redis_client.is_connected():
        return False  # Redis yoksa her zaman yeni email olarak işle
    
    existing_data = redis_client.get_task_extraction(email_id=email_id, provider=provider)
    
    if existing_data is None:
        return False  # Redis'te yok, yeni email
    
    # Redis'te var ama içerik boş mu kontrol et
    task_data = existing_data.get("task_data", {})
    
    # Eğer task_data boş, None veya sadece boş bir dict ise, tekrar işle
    if not task_data:
        print(f"⚠️  Redis'te email var ama task_data boş: email_tasks:{provider}:{email_id}")
        print(f"   📤 Email tekrar n8n'e gönderilecek")
        return False
    
    # task_data varsa ama "cevap" alanı boş ise de tekrar işle
    if isinstance(task_data, dict):
        cevap = task_data.get("cevap")
        # cevap boş liste, None veya boş string ise
        if cevap is None or (isinstance(cevap, list) and len(cevap) == 0) or (isinstance(cevap, str) and not cevap.strip()):
            print(f"⚠️  Redis'te email var ama 'cevap' alanı boş: email_tasks:{provider}:{email_id}")
            print(f"   📤 Email tekrar n8n'e gönderilecek")
            return False
    
    # Geçerli veri var, atlayabiliriz
    return True


class N8nService:
    """n8n webhook servisi"""
    
    def __init__(self):
        """n8n servisi başlat"""
        # Boş string kontrolü yap - eğer boş veya None ise default URL kullan
        webhook_url = settings.N8N_EMAIL_WEBHOOK_URL
        if not webhook_url or not webhook_url.strip():
            webhook_url = "https://hakanozer12.app.n8n.cloud/webhook/7d767402-8f08-47cf-91fa-279679510375"
        self.webhook_url = webhook_url
        # Debug: Webhook URL'i yazdır
        print(f"🔗 n8n Webhook URL: {self.webhook_url}")
    
    async def send_email_for_task_extraction(
        self, 
        email: Email,
        provider: str = "gmail"  # "gmail" veya "outlook"
    ) -> Optional[Dict[str, Any]]:
        """
        Email'i n8n'e gönder, görev çıkarımı yap ve Redis'e kaydet
        
        Args:
            email: Email objesi
            provider: Email provider ("gmail" veya "outlook")
            
        Returns:
            n8n'den dönen response dict veya None
        """
        if not self.webhook_url:
            print("⚠️ n8n webhook URL yapılandırılmamış")
            return None
        
        # ÖNEMLİ: Email daha önce işlenmiş mi kontrol et (Redis'te var mı?)
        # Bu kontrol router'da da yapılıyor ama burada da yaparak kesinleştiriyoruz
        already_processed = check_email_already_processed(
            email_id=email.id,
            provider=provider
        )
        
        if already_processed:
            print("\n" + "="*80)
            print("⏭️  n8n_service: Email zaten işlenmiş, n8n'e GÖNDERİLMİYOR")
            print(f"   Email ID: {email.id}")
            print(f"   Provider: {provider}")
            print(f"   Redis Key: email_tasks:{provider}:{email.id}")
            print("   ✅ Bu email bir daha n8n'e gönderilmeyecek")
            print("="*80 + "\n")
            return None
        
        try:
            # Email verisini n8n formatına çevir
            # email.category zaten string (use_enum_values=True sayesinde)
            category_value = email.category if isinstance(email.category, str) else email.category.value
            
            # is_outgoing: Email bizden gittiyse true, karşıdan geldiyse false
            # "sent" kategorisi bizden giden email'leri gösterir
            is_outgoing = category_value == "sent"
            
            payload = {
                "email_id": email.id,
                "subject": email.subject,
                "from": email.sender,
                "to": email.recipient or "",
                "body": email.preview or "",
                "plain_text": email.plain_text,
                "html_content": email.html_content,
                "received_date": email.received_date.isoformat(),
                "is_read": email.is_read,
                "category": category_value,
                "has_attachments": email.has_attachments,
                "provider": provider,
                "is_outgoing": is_outgoing,  # Bizden gittiyse true, karşıdan geldiyse false
            }
            
            print("\n" + "="*80)
            print(f"📤 n8n'e {provider.upper()} email gönderiliyor...")
            print("="*80)
            print(f"Email ID: {email.id}")
            print(f"Konu: {email.subject}")
            print(f"Gönderen: {email.sender}")
            print(f"Kategori: {category_value}")
            print(f"n8n URL: {self.webhook_url}")
            print("="*80 + "\n")
            
            # n8n'e POST isteği gönder
            async with httpx.AsyncClient(timeout=60.0) as client:
                response = await client.post(
                    self.webhook_url,
                    json=payload,
                    headers={"Content-Type": "application/json"}
                )
                
                print("\n" + "="*80)
                print(f"📥 n8n'den {provider.upper()} yanıtı alındı")
                print("="*80)
                print(f"Status Code: {response.status_code}")
                print(f"Response Headers: {dict(response.headers)}")
                print("\nResponse Body:")
                print("-" * 80)
                
                # Response'u parse et ve yazdır
                try:
                    if response.text:
                        # JSON olarak parse et
                        try:
                            response_json = response.json()
                            print(json.dumps(response_json, indent=2, ensure_ascii=False))
                        except:
                            # JSON değilse direkt yazdır
                            print(response.text)
                    else:
                        print("(Boş response)")
                    
                    print("-" * 80)
                    print("="*80 + "\n")
                    
                    # Başarılı ise response'u işle ve Redis'e kaydet
                    if response.status_code == 200:
                        response_data = response_json if response.text else {}
                        
                        # n8n'den dönen veri yeni formatta (dict içinde cevap listesi)
                        if isinstance(response_data, dict):
                            # Yeni format: {"cevap": [...], "sesli_okuma": "...", "tip": "..."}
                            task_data = response_data.copy()  # Tüm veriyi al
                            
                            # category ve is_outgoing'i task_data'dan çıkar (email'de zaten var)
                            task_data.pop("mail_category", None)
                            task_data.pop("is_outgoing", None)
                            
                        elif isinstance(response_data, list) and len(response_data) > 0:
                            # Eski format: Liste içinde tek item
                            task_data = response_data[0].copy()
                            # category ve is_outgoing'i çıkar
                            task_data.pop("mail_category", None)
                            task_data.pop("is_outgoing", None)
                        else:
                            # Boş veya farklı format
                            task_data = response_data
                        
                        # YENİ: n8n'den boş response geldiyse Redis'e kaydetme
                        # Bu sayede bir sonraki sync'te tekrar n8n'e gönderilecek
                        is_task_data_empty = False
                        if not task_data:
                            is_task_data_empty = True
                        elif isinstance(task_data, dict):
                            cevap = task_data.get("cevap")
                            if cevap is None or (isinstance(cevap, list) and len(cevap) == 0) or (isinstance(cevap, str) and not cevap.strip()):
                                is_task_data_empty = True
                        
                        if is_task_data_empty:
                            print("\n" + "="*80)
                            print("⚠️  n8n'den BOŞ response geldi - Redis'e KAYDEDİLMEYECEK")
                            print("="*80)
                            print(f"   Email ID: {email.id}")
                            print(f"   Provider: {provider}")
                            print(f"   ⏭️  Bir sonraki sync'te tekrar n8n'e gönderilecek")
                            print("="*80 + "\n")
                            return None
                        
                        # Email verisini hazırla (Redis'e kaydetmek için)
                        email_data = {
                            "email_id": email.id,
                            "subject": email.subject,
                            "from": email.sender,
                            "to": email.recipient or "",
                            "body": email.preview or "",
                            "plain_text": email.plain_text,
                            "html_content": email.html_content,
                            "received_date": email.received_date.isoformat(),
                            "is_read": email.is_read,
                            "category": category_value,  # Email'de category var
                            "has_attachments": email.has_attachments,
                            "is_outgoing": is_outgoing,  # Email'de is_outgoing var
                        }
                        
                        # Redis'e kaydet (email + n8n response)
                        print("\n" + "="*80)
                        print("💾 Redis'e kaydediliyor (Email + n8n Response)...")
                        print("="*80)
                        
                        saved = redis_client.save_task_extraction(
                            email_id=email.id,
                            provider=provider,
                            email_data=email_data,
                            task_data=task_data,
                            ttl=604800  # 1 hafta (7 gün)
                        )
                        
                        if saved:
                            print("✅ Redis'e başarıyla kaydedildi")
                            print(f"   Redis Key: email_tasks:{provider}:{email.id}")
                            print(f"   TTL: 1 hafta (604800 saniye)")
                            print("   ✅ Bu email bir daha n8n'e gönderilmeyecek (Redis'te kontrol edilecek)")
                        else:
                            print("⚠️ Redis'e kaydedilemedi (bağlantı yok veya hata)")
                            print("   ⚠️ Email Redis'e kaydedilmediği için tekrar n8n'e gönderilebilir")
                        
                        print("="*80 + "\n")
                        
                        return task_data
                    else:
                        print(f"❌ n8n hatası: {response.status_code}")
                        return None
                        
                except Exception as e:
                    print(f"❌ Response parse hatası: {e}")
                    print(f"Raw response: {response.text}")
                    print("="*80 + "\n")
                    return None
                    
        except httpx.TimeoutException:
            print(f"❌ n8n isteği zaman aşımına uğradı (60 saniye)")
            return None
        except Exception as e:
            print(f"❌ n8n'e email gönderme hatası: {str(e)}")
            import traceback
            print(traceback.format_exc())
            return None

