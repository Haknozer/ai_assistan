"""
Gmail Email Servisi - Google Gmail API entegrasyonu
"""
import httpx
from typing import List, Optional
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
from app.models.email_schemas import Email, EmailCategory
from app.core.config import settings
from app.core.exceptions import UnauthorizedError


class GmailEmailService:
    """Gmail email işlemleri servisi"""
    
    GMAIL_API_BASE = "https://gmail.googleapis.com/gmail/v1"
    
    def __init__(self, access_token: str):
        """
        Gmail email servisi başlat
        
        Args:
            access_token: Google OAuth access token
        """
        self.access_token = access_token
        self.headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }
    
    async def _make_request(self, endpoint: str, method: str = "GET", params: Optional[dict] = None, json_data: Optional[dict] = None) -> dict:
        """
        Google Gmail API'ye istek at
        
        Args:
            endpoint: API endpoint (örn: /users/me/messages)
            method: HTTP method (GET, POST, PUT, DELETE)
            params: Query parametreleri
            json_data: Request body (POST/PUT için)
            
        Returns:
            API response dict
        """
        url = f"{self.GMAIL_API_BASE}{endpoint}"
        
        async with httpx.AsyncClient() as client:
            if method == "GET":
                response = await client.get(url, headers=self.headers, params=params)
            elif method == "POST":
                response = await client.post(url, headers=self.headers, params=params, json=json_data)
            elif method == "PUT":
                response = await client.put(url, headers=self.headers, params=params, json=json_data)
            elif method == "DELETE":
                response = await client.delete(url, headers=self.headers, params=params)
            else:
                raise ValueError(f"Unsupported HTTP method: {method}")
            
            # 401 hatası için özel kontrol - token yenileme için
            if response.status_code == 401:
                raise UnauthorizedError("Geçersiz access token. Token'ı yenileyin.")
            
            response.raise_for_status()
            return response.json() if response.content else {}
    
    def _determine_category(self, message: dict, label_ids: List[str]) -> EmailCategory:
        """
        Email kategorisini belirle
        
        Args:
            message: Gmail message objesi
            label_ids: Message label ID'leri
            
        Returns:
            EmailCategory enum değeri
        """
        # Gmail label'ları - öncelik sırasına göre kontrol et
        if "SENT" in label_ids:
            return EmailCategory.SENT
        elif "DRAFT" in label_ids:
            return EmailCategory.DRAFTS
        elif "SPAM" in label_ids:
            return EmailCategory.SPAM
        elif "CATEGORY_PROMOTIONS" in label_ids:
            return EmailCategory.PROMOTIONS  # Tanıtım kategorisi
        elif "CATEGORY_SOCIAL" in label_ids:
            return EmailCategory.SOCIAL  # Sosyal kategorisi
        elif "CATEGORY_UPDATES" in label_ids:
            return EmailCategory.UPDATES  # Güncellemeler kategorisi
        elif "CATEGORY_FORUMS" in label_ids:
            return EmailCategory.FORUMS  # Forumlar kategorisi
        elif "INBOX" in label_ids:
            return EmailCategory.INBOX
        
        # Varsayılan olarak inbox
        return EmailCategory.INBOX
    
    def _parse_email(self, message: dict, category: Optional[EmailCategory] = None) -> Email:
        """
        Gmail message objesini Email modeline çevir
        
        Args:
            message: Gmail message objesi (full message veya message list item)
            category: Email kategorisi (None ise otomatik belirlenir)
            
        Returns:
            Email modeli
        """
        # Message ID
        message_id = message.get("id", "")
        
        # Label'lar
        label_ids = message.get("labelIds", [])
        
        # Kategori belirleme
        if category is None:
            category = self._determine_category(message, label_ids)
        
        # Message payload (eğer full message ise)
        payload = message.get("payload", {})
        headers = payload.get("headers", [])
        
        # Header'lardan bilgileri çıkar
        def get_header(name: str) -> str:
            for header in headers:
                if header.get("name", "").lower() == name.lower():
                    return header.get("value", "")
            return ""
        
        subject = get_header("Subject") or "(Konu yok)"
        sender = get_header("From") or "unknown"
        recipient = get_header("To") or ""
        
        # Tarih parse
        date_str = get_header("Date")
        received_date = datetime.now(timezone.utc)
        if date_str:
            try:
                # Gmail date formatını parse et
                received_date = parsedate_to_datetime(date_str)
            except:
                pass
        
        # Body preview (snippet)
        snippet = message.get("snippet", "")
        
        # Is read
        is_read = "UNREAD" not in label_ids
        
        # Has attachments
        has_attachments = any(
            part.get("filename") 
            for part in payload.get("parts", [])
            if part.get("filename")
        )
        
        # Body içeriğini çıkar (plainText ve htmlContent)
        plain_text = None
        html_content = None
        
        def extract_body_from_parts(parts):
            """Recursive olarak parts'tan body çıkar"""
            plain = None
            html = None
            
            for part in parts:
                mime_type = part.get("mimeType", "")
                body_data = part.get("body", {})
                body_data_value = body_data.get("data", "")
                
                if body_data_value:
                    import base64
                    try:
                        decoded = base64.urlsafe_b64decode(body_data_value).decode('utf-8')
                        if mime_type == "text/plain" and not plain:
                            plain = decoded
                        elif mime_type == "text/html" and not html:
                            html = decoded
                    except Exception as e:
                        print(f"⚠️ Body decode hatası: {e}")
                
                # Nested parts varsa recursive çağır
                nested_parts = part.get("parts", [])
                if nested_parts:
                    nested_plain, nested_html = extract_body_from_parts(nested_parts)
                    if nested_plain and not plain:
                        plain = nested_plain
                    if nested_html and not html:
                        html = nested_html
            
            return plain, html
        
        # Payload'dan body çıkar
        if payload:
            # Eğer direkt body varsa (tek part email)
            body_data = payload.get("body", {})
            body_data_value = body_data.get("data", "")
            mime_type = payload.get("mimeType", "")
            
            if body_data_value:
                import base64
                try:
                    decoded = base64.urlsafe_b64decode(body_data_value).decode('utf-8')
                    if mime_type == "text/plain":
                        plain_text = decoded
                    elif mime_type == "text/html":
                        html_content = decoded
                except Exception as e:
                    print(f"⚠️ Body decode hatası: {e}")
            
            # Parts varsa recursive çıkar
            parts = payload.get("parts", [])
            if parts:
                extracted_plain, extracted_html = extract_body_from_parts(parts)
                if extracted_plain:
                    plain_text = extracted_plain
                if extracted_html:
                    html_content = extracted_html
        
        return Email(
            id=message_id,
            subject=subject,
            sender=sender,
            recipient=recipient,
            preview=snippet,
            plain_text=plain_text,
            html_content=html_content,
            received_date=received_date,
            is_read=is_read,
            category=category,
            has_attachments=has_attachments
        )
    
    async def fetch_emails(
        self, 
        category: Optional[EmailCategory] = None,
        limit: int = 10
    ) -> List[Email]:
        """
        Gmail'den email'leri çek
        
        Args:
            category: Email kategorisi filtresi (None = tüm kategorilerden çek)
            limit: Kaç email getirilecek (her kategori için limit/4 kadar çekilir)
            
        Returns:
            Email listesi
        """
        # Eğer kategori belirtilmişse sadece o kategoriden çek
        if category is not None:
            query = ""
            if category == EmailCategory.SENT:
                query = "in:sent"
            elif category == EmailCategory.DRAFTS:
                query = "in:drafts"
            elif category == EmailCategory.SPAM:
                query = "in:spam"
            elif category == EmailCategory.PROMOTIONS:
                query = "category:promotions"
            elif category == EmailCategory.SOCIAL:
                query = "category:social"
            elif category == EmailCategory.UPDATES:
                query = "category:updates"
            elif category == EmailCategory.FORUMS:
                query = "category:forums"
            else:
                query = "in:inbox"
            
            return await self._fetch_emails_by_query(query, limit, category)
        
        # Kategori belirtilmemişse TÜM kategorilerden çek
        all_emails = []
        
        # Her kategoriden email çek (limit/4 kadar her birinden)
        per_category_limit = max(limit // 4, 5)  # En az 5 email
        
        categories_to_fetch = [
            ("in:inbox", None),  # Inbox - kategori otomatik belirlenecek
            ("category:promotions", EmailCategory.PROMOTIONS),
            ("category:social", EmailCategory.SOCIAL),
            ("category:updates", EmailCategory.UPDATES),
            ("category:forums", EmailCategory.FORUMS),
            ("in:sent", EmailCategory.SENT),
            ("in:spam", EmailCategory.SPAM),
        ]
        
        for query, cat in categories_to_fetch:
            try:
                category_emails = await self._fetch_emails_by_query(query, per_category_limit, cat)
                all_emails.extend(category_emails)
            except Exception as e:
                print(f"⚠️ Kategori {cat} çekilemedi: {e}")
                continue
        
        # Tarihe göre sırala ve limit'e göre kes
        all_emails.sort(key=lambda x: x.received_date, reverse=True)
        return all_emails[:limit]
    
    async def _fetch_emails_by_query(
        self, 
        query: str, 
        limit: int, 
        category: Optional[EmailCategory] = None
    ) -> List[Email]:
        """Belirli bir query ile email'leri çek"""
        params = {
            "q": query,
            "maxResults": limit,
        }
        
        try:
            # Message listesini al
            response = await self._make_request("/users/me/messages", params=params)
            messages_list = response.get("messages", [])
            
            if not messages_list:
                return []
            
            # Her message için detaylı bilgiyi çek
            emails = []
            for msg_item in messages_list[:limit]:
                message_id = msg_item.get("id")
                if not message_id:
                    continue
                
                try:
                    message_response = await self._make_request(f"/users/me/messages/{message_id}")
                    email = self._parse_email(message_response, category)
                    emails.append(email)
                except Exception as e:
                    print(f"⚠️ Message {message_id} çekilemedi: {e}")
                    continue
            
            return emails
            
        except httpx.HTTPStatusError as e:
            if e.response.status_code == 401:
                raise UnauthorizedError("Geçersiz access token. Token'ı yenileyin.")
            elif e.response.status_code == 403:
                raise Exception("Gmail okuma yetkisi yok. Lütfen izinleri kontrol edin.")
            else:
                raise Exception(f"Gmail API hatası: {e.response.status_code}")
        except Exception as e:
            raise Exception(f"Email çekme hatası: {str(e)}")
    
    async def send_email(
        self,
        to_emails: List[str],
        subject: str,
        plain_text: Optional[str] = None,
        html_content: Optional[str] = None,
        cc_emails: Optional[List[str]] = None,
        bcc_emails: Optional[List[str]] = None,
    ) -> Email:
        """
        Email gönder (Gmail API)
        
        Args:
            to_emails: Alıcı email adresleri
            subject: Email konusu
            plain_text: Düz metin içerik
            html_content: HTML içerik
            cc_emails: CC alıcıları
            bcc_emails: BCC alıcıları
            
        Returns:
            Gönderilen Email modeli
        """
        import base64
        from email.mime.text import MIMEText
        from email.mime.multipart import MIMEMultipart
        
        # Email mesajı oluştur
        if html_content:
            msg = MIMEMultipart('alternative')
            if plain_text:
                msg.attach(MIMEText(plain_text, 'plain'))
            msg.attach(MIMEText(html_content, 'html'))
        else:
            msg = MIMEText(plain_text or '', 'plain')
        
        msg['To'] = ', '.join(to_emails)
        msg['Subject'] = subject
        if cc_emails:
            msg['Cc'] = ', '.join(cc_emails)
        
        # BCC header'a eklenmez, body'de olur
        
        # Base64 encode
        raw_message = base64.urlsafe_b64encode(msg.as_bytes()).decode('utf-8')
        
        # Gmail API'ye gönder
        body = {'raw': raw_message}
        response = await self._make_request(
            "/users/me/messages/send",
            method="POST",
            json_data=body
        )
        
        # Gönderilen email'i çek
        message_id = response.get('id')
        if not message_id:
            raise Exception("Email gönderildi ancak message ID alınamadı")
        
        # Gönderilen email'i getir
        message_response = await self._make_request(f"/users/me/messages/{message_id}")
        return self._parse_email(message_response, EmailCategory.SENT)
    
    async def mark_as_read(self, message_id: str) -> Email:
        """
        Email'i okundu olarak işaretle
        
        Args:
            message_id: Email message ID
            
        Returns:
            Güncellenmiş Email modeli
        """
        body = {
            'removeLabelIds': ['UNREAD']
        }
        await self._make_request(
            f"/users/me/messages/{message_id}/modify",
            method="POST",
            json_data=body
        )
        
        # Güncellenmiş email'i getir
        message_response = await self._make_request(f"/users/me/messages/{message_id}")
        return self._parse_email(message_response)
    
    async def mark_as_unread(self, message_id: str) -> Email:
        """
        Email'i okunmamış olarak işaretle
        
        Args:
            message_id: Email message ID
            
        Returns:
            Güncellenmiş Email modeli
        """
        body = {
            'addLabelIds': ['UNREAD']
        }
        await self._make_request(
            f"/users/me/messages/{message_id}/modify",
            method="POST",
            json_data=body
        )
        
        # Güncellenmiş email'i getir
        message_response = await self._make_request(f"/users/me/messages/{message_id}")
        return self._parse_email(message_response)
    
    async def toggle_important(self, message_id: str, is_important: bool) -> Email:
        """
        Email'i önemli olarak işaretle/kaldır
        
        Args:
            message_id: Email message ID
            is_important: True ise önemli işaretle, False ise kaldır
            
        Returns:
            Güncellenmiş Email modeli
        """
        if is_important:
            body = {'addLabelIds': ['IMPORTANT']}
        else:
            body = {'removeLabelIds': ['IMPORTANT']}
        
        await self._make_request(
            f"/users/me/messages/{message_id}/modify",
            method="POST",
            json_data=body
        )
        
        # Güncellenmiş email'i getir
        message_response = await self._make_request(f"/users/me/messages/{message_id}")
        return self._parse_email(message_response)
    
    async def delete_email(self, message_id: str) -> None:
        """
        Email'i sil (trash'e taşı)
        
        Args:
            message_id: Email message ID
        """
        await self._make_request(
            f"/users/me/messages/{message_id}/trash",
            method="POST"
        )
    
    async def save_draft(
        self,
        subject: str,
        plain_text: Optional[str] = None,
        html_content: Optional[str] = None,
        to_emails: Optional[List[str]] = None,
        cc_emails: Optional[List[str]] = None,
        bcc_emails: Optional[List[str]] = None,
        draft_id: Optional[str] = None,
    ) -> Email:
        """
        Email taslağı kaydet/güncelle
        
        Args:
            subject: Email konusu
            plain_text: Düz metin içerik
            html_content: HTML içerik
            to_emails: Alıcı email adresleri
            cc_emails: CC alıcıları
            bcc_emails: BCC alıcıları
            draft_id: Draft ID (güncelleme için)
            
        Returns:
            Kaydedilen Email modeli
        """
        import base64
        from email.mime.text import MIMEText
        from email.mime.multipart import MIMEMultipart
        
        # Email mesajı oluştur
        if html_content:
            msg = MIMEMultipart('alternative')
            if plain_text:
                msg.attach(MIMEText(plain_text, 'plain'))
            msg.attach(MIMEText(html_content, 'html'))
        else:
            msg = MIMEText(plain_text or '', 'plain')
        
        if to_emails:
            msg['To'] = ', '.join(to_emails)
        msg['Subject'] = subject
        if cc_emails:
            msg['Cc'] = ', '.join(cc_emails)
        
        # Base64 encode
        raw_message = base64.urlsafe_b64encode(msg.as_bytes()).decode('utf-8')
        
        # Gmail API'ye kaydet
        body = {'message': {'raw': raw_message}}
        
        if draft_id:
            # Güncelle
            response = await self._make_request(
                f"/users/me/drafts/{draft_id}",
                method="PUT",
                json_data=body
            )
        else:
            # Yeni oluştur
            response = await self._make_request(
                "/users/me/drafts",
                method="POST",
                json_data=body
            )
        
        # Draft message ID'yi al
        message_data = response.get('message', {})
        message_id = message_data.get('id')
        if not message_id:
            raise Exception("Draft kaydedildi ancak message ID alınamadı")
        
        # Kaydedilen draft'ı getir
        message_response = await self._make_request(f"/users/me/messages/{message_id}")
        return self._parse_email(message_response, EmailCategory.DRAFTS)
    
    async def setup_push_notifications(self, topic_name: str) -> dict:
        """
        Gmail Push Notifications kurulumu (users.watch API)
        
        Bu fonksiyon Gmail mailbox'ı için push notification'ları aktif eder.
        Yeni mail geldiğinde Gmail, belirtilen Pub/Sub topic'ine mesaj gönderir.
        
        Args:
            topic_name: Google Cloud Pub/Sub topic adı (format: projects/{project}/topics/{topic})
            
        Returns:
            Watch response (historyId, expiration vb.)
            
        Example:
            topic_name = "projects/aiassistan/topics/gmail-bildirim"
            response = await gmail_service.setup_push_notifications(topic_name)
        """
        try:
            body = {
                "labelIds": ["INBOX"],  # INBOX değişikliklerini izle
                "topicName": topic_name
            }
            
            response = await self._make_request(
                "/users/me/watch",
                method="POST",
                json_data=body
            )
            
            print(f"✅ Gmail Push Notification kuruldu")
            print(f"   History ID: {response.get('historyId')}")
            print(f"   Expiration: {response.get('expiration')} (unix timestamp ms)")
            
            return response
            
        except Exception as e:
            print(f"❌ Gmail Push Notification kurulum hatası: {e}")
            raise Exception(f"Gmail watch request hatası: {str(e)}")
    
    async def stop_push_notifications(self) -> None:
        """
        Gmail Push Notifications durdur (users.stop API)
        
        Push notification'ları devre dışı bırakır.
        """
        try:
            await self._make_request(
                "/users/me/stop",
                method="POST"
            )
            print("✅ Gmail Push Notification durduruldu")
        except Exception as e:
            print(f"⚠️ Gmail Push Notification durdurma hatası: {e}")
            raise Exception(f"Gmail stop request hatası: {str(e)}")

