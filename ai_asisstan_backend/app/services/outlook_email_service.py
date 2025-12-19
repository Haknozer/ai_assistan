"""
Outlook Email Servisi - Microsoft Graph API entegrasyonu
"""
import httpx
from typing import List, Optional
from datetime import datetime
from app.models.email_schemas import Email, EmailCategory
from app.core.config import settings
from app.core.exceptions import UnauthorizedError


class OutlookEmailService:
    """Outlook email işlemleri servisi"""
    
    GRAPH_API_BASE = "https://graph.microsoft.com/v1.0"
    
    def __init__(self, access_token: str):
        """
        Outlook email servisi başlat
        
        Args:
            access_token: Microsoft Graph API access token
        """
        self.access_token = access_token
        self.headers = {
            "Authorization": f"Bearer {access_token}",
            "Content-Type": "application/json"
        }
    
    async def _make_request(self, endpoint: str, method: str = "GET", params: Optional[dict] = None, json_data: Optional[dict] = None) -> dict:
        """
        Microsoft Graph API'ye istek at
        
        Args:
            endpoint: API endpoint (örn: /me/messages)
            method: HTTP method (GET, POST, PUT, PATCH, DELETE)
            params: Query parametreleri
            json_data: Request body (POST/PUT/PATCH için)
            
        Returns:
            API response dict
        """
        url = f"{self.GRAPH_API_BASE}{endpoint}"
        
        async with httpx.AsyncClient() as client:
            if method == "GET":
                response = await client.get(url, headers=self.headers, params=params)
            elif method == "POST":
                response = await client.post(url, headers=self.headers, params=params, json=json_data)
            elif method == "PUT":
                response = await client.put(url, headers=self.headers, params=params, json=json_data)
            elif method == "PATCH":
                response = await client.patch(url, headers=self.headers, params=params, json=json_data)
            elif method == "DELETE":
                response = await client.delete(url, headers=self.headers, params=params)
            else:
                raise ValueError(f"Unsupported HTTP method: {method}")
            
            # 401 hatası için özel kontrol - token yenileme için
            if response.status_code == 401:
                raise UnauthorizedError("Geçersiz access token. Token'ı yenileyin.")
            
            response.raise_for_status()
            return response.json() if response.content else {}
    
    def _determine_category(self, message: dict) -> EmailCategory:
        """
        Email kategorisini belirle
        
        Args:
            message: Microsoft Graph message objesi
            
        Returns:
            EmailCategory enum değeri
        """
        # Microsoft Graph'te email kategorileri
        # isRead: False -> genelde inbox
        # parentFolderId veya folderId kontrolü yapılabilir
        
        # Spam/Junk klasörü kontrolü
        folder_id = message.get("parentFolderId", "")
        if "junk" in folder_id.lower() or "spam" in folder_id.lower():
            return EmailCategory.SPAM
        
        # Sent Items kontrolü
        if message.get("isDraft", False):
            return EmailCategory.DRAFTS
        
        # Gönderen kontrolü (basit spam tespiti)
        sender = message.get("from", {}).get("emailAddress", {}).get("address", "").lower()
        subject = message.get("subject", "").lower()
        
        # Spam kelimeleri kontrolü (basit)
        spam_keywords = ["spam", "junk", "unsubscribe", "promo", "promotion"]
        if any(keyword in subject for keyword in spam_keywords):
            return EmailCategory.SPAM
        
        # Sent Items klasörü kontrolü
        # Not: Microsoft Graph'te sent items için özel kontrol gerekebilir
        # Şimdilik inbox olarak işaretle, router'da sent filtresi uygulanacak
        
        return EmailCategory.INBOX
    
    def _parse_email(self, message: dict, category: Optional[EmailCategory] = None) -> Email:
        """
        Microsoft Graph message objesini Email modeline çevir
        
        Args:
            message: Microsoft Graph message objesi
            category: Email kategorisi (None ise otomatik belirlenir)
            
        Returns:
            Email modeli
        """
        if category is None:
            category = self._determine_category(message)
        
        sender_info = message.get("from", {}).get("emailAddress", {})
        sender_email = sender_info.get("address", "unknown")
        sender_name = sender_info.get("name", "")
        sender = f"{sender_name} <{sender_email}>" if sender_name else sender_email
        
        # Alıcı bilgisi (toRecipients)
        recipients = message.get("toRecipients", [])
        recipient = recipients[0].get("emailAddress", {}).get("address", "") if recipients else None
        
        # Tarih parse (güvenli)
        received_date_str = message.get("receivedDateTime") or message.get("sentDateTime")
        if not received_date_str:
            # Tarih yoksa şu anki zamanı kullan
            from datetime import datetime, timezone
            received_date = datetime.now(timezone.utc)
        else:
            try:
                received_date = datetime.fromisoformat(received_date_str.replace("Z", "+00:00"))
            except Exception as e:
                print(f"⚠️ Tarih parse hatası: {e}, şu anki zaman kullanılıyor")
                from datetime import datetime, timezone
                received_date = datetime.now(timezone.utc)
        
        # Body preview
        body_preview = message.get("bodyPreview") or message.get("preview") or ""
        
        # Body içeriğini çıkar (plainText ve htmlContent)
        plain_text = None
        html_content = None
        
        body_obj = message.get("body", {})
        if body_obj:
            body_content = body_obj.get("content", "")
            body_type = body_obj.get("contentType", "").lower()
            
            if body_content:
                if body_type == "text":
                    plain_text = body_content
                elif body_type == "html":
                    html_content = body_content
        
        # Subject ve is_read None olabilir, default değerler kullan
        subject = message.get("subject")
        if not subject or subject == "":
            subject = "(Konu yok)"
        
        is_read = message.get("isRead")
        if is_read is None:
            is_read = False
        
        # Email ID kontrolü
        email_id = message.get("id")
        if not email_id:
            raise ValueError("Email ID bulunamadı")
        
        return Email(
            id=email_id,
            subject=subject,
            sender=sender,
            recipient=recipient,
            preview=body_preview,
            plain_text=plain_text,
            html_content=html_content,
            received_date=received_date,
            is_read=bool(is_read),  # Kesinlikle boolean yap
            category=category,
            has_attachments=bool(message.get("hasAttachments", False))
        )
    
    async def fetch_emails(
        self, 
        category: Optional[EmailCategory] = None,
        limit: int = 10
    ) -> List[Email]:
        """
        Outlook'tan email'leri çek
        
        Args:
            category: Email kategorisi filtresi (None = tüm klasörlerden çek)
            limit: Kaç email getirilecek (her klasör için limit/4 kadar çekilir)
            
        Returns:
            Email listesi
        """
        # Eğer kategori belirtilmişse sadece o klasörden çek
        if category is not None:
            if category == EmailCategory.SENT:
                endpoint = "/me/mailFolders/sentItems/messages"
            elif category == EmailCategory.DRAFTS:
                endpoint = "/me/mailFolders/drafts/messages"
            elif category == EmailCategory.SPAM:
                endpoint = "/me/mailFolders/junkEmail/messages"
            else:
                endpoint = "/me/messages"
            
            return await self._fetch_emails_from_endpoint(endpoint, limit, category)
        
        # Kategori belirtilmemişse TÜM klasörlerden çek
        all_emails = []
        
        # Her klasörden email çek (limit/4 kadar her birinden)
        per_folder_limit = max(limit // 4, 5)  # En az 5 email
        
        folders_to_fetch = [
            ("/me/messages", None),  # Inbox - kategori otomatik belirlenecek
            ("/me/mailFolders/sentItems/messages", EmailCategory.SENT),
            ("/me/mailFolders/junkEmail/messages", EmailCategory.SPAM),
            ("/me/mailFolders/drafts/messages", EmailCategory.DRAFTS),
        ]
        
        for endpoint, cat in folders_to_fetch:
            try:
                folder_emails = await self._fetch_emails_from_endpoint(endpoint, per_folder_limit, cat)
                all_emails.extend(folder_emails)
            except Exception as e:
                print(f"⚠️ Klasör {cat} çekilemedi: {e}")
                continue
        
        # Tarihe göre sırala ve limit'e göre kes
        all_emails.sort(key=lambda x: x.received_date, reverse=True)
        return all_emails[:limit]
    
    async def _fetch_emails_from_endpoint(
        self,
        endpoint: str,
        limit: int,
        category: Optional[EmailCategory] = None
    ) -> List[Email]:
        """Belirli bir endpoint'ten email'leri çek"""
        params = {
            "$top": limit,
            "$orderby": "receivedDateTime desc",
            "$select": "id,subject,from,toRecipients,receivedDateTime,sentDateTime,isRead,bodyPreview,hasAttachments,parentFolderId,isDraft"
        }
        
        try:
            response = await self._make_request(endpoint, method="GET", params=params)
            messages = response.get("value", [])
            
            # Email'leri parse et - her biri için detay çek
            emails = []
            for msg in messages:
                message_id = msg.get("id")
                if not message_id:
                    continue
                
                try:
                    # Tam email detayını çek (body içeriği için)
                    detail_params = {
                        "$select": "id,subject,from,toRecipients,receivedDateTime,sentDateTime,isRead,bodyPreview,body,hasAttachments,parentFolderId,isDraft"
                    }
                    detail_response = await self._make_request(
                        f"/me/messages/{message_id}",
                        method="GET",
                        params=detail_params
                    )
                    email = self._parse_email(detail_response, category)
                    emails.append(email)
                except Exception as e:
                    print(f"⚠️ Email {message_id} detayı çekilemedi: {e}")
                    # Detay çekilemezse sadece preview ile parse et
                    email = self._parse_email(msg, category)
                    emails.append(email)
            
            return emails
            
        except httpx.HTTPStatusError as e:
            if e.response.status_code == 401:
                raise UnauthorizedError("Geçersiz access token. Token'ı yenileyin.")
            elif e.response.status_code == 403:
                raise Exception("Email okuma yetkisi yok. Lütfen izinleri kontrol edin.")
            else:
                raise Exception(f"Microsoft Graph API hatası: {e.response.status_code}")
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
        Email gönder (Microsoft Graph API)
        
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
        # Microsoft Graph API message body oluştur
        message_body = {
            'message': {
                'toRecipients': [{'emailAddress': {'address': email}} for email in to_emails],
                'subject': subject,
                'body': {
                    'contentType': 'html' if html_content else 'text',
                    'content': html_content or plain_text or ''
                }
            }
        }
        
        if cc_emails:
            message_body['message']['ccRecipients'] = [{'emailAddress': {'address': email}} for email in cc_emails]
        
        if bcc_emails:
            message_body['message']['bccRecipients'] = [{'emailAddress': {'address': email}} for email in bcc_emails]
        
        # Email gönder (Microsoft Graph API sendMail endpoint'i response döndürmez)
        await self._make_request(
            "/me/sendMail",
            method="POST",
            json_data=message_body
        )
        
        # Gönderilen email'i sent items'dan çek (kısa bir bekleme ile)
        import asyncio
        await asyncio.sleep(0.5)  # Email'in sent items'a kaydedilmesi için bekle
        
        # Sent items'dan en son gönderilen email'i çek
        sent_response = await self._make_request(
            "/me/mailFolders/sentItems/messages",
            method="GET",
            params={
                "$top": 1,
                "$orderby": "sentDateTime desc",
                "$select": "id,subject,from,toRecipients,receivedDateTime,sentDateTime,isRead,bodyPreview,hasAttachments"
            }
        )
        
        sent_messages = sent_response.get("value", [])
        if not sent_messages:
            raise Exception("Email gönderildi ancak sent items'dan alınamadı")
        
        return self._parse_email(sent_messages[0], EmailCategory.SENT)
    
    async def mark_as_read(self, message_id: str) -> Email:
        """
        Email'i okundu olarak işaretle
        
        Args:
            message_id: Email message ID
            
        Returns:
            Güncellenmiş Email modeli
        """
        await self._make_request(
            f"/me/messages/{message_id}",
            method="PATCH",
            json_data={'isRead': True}
        )
        
        # Güncellenmiş email'i getir
        message_response = await self._make_request(f"/me/messages/{message_id}", method="GET")
        return self._parse_email(message_response)
    
    async def mark_as_unread(self, message_id: str) -> Email:
        """
        Email'i okunmamış olarak işaretle
        
        Args:
            message_id: Email message ID
            
        Returns:
            Güncellenmiş Email modeli
        """
        await self._make_request(
            f"/me/messages/{message_id}",
            method="PATCH",
            json_data={'isRead': False}
        )
        
        # Güncellenmiş email'i getir
        message_response = await self._make_request(f"/me/messages/{message_id}", method="GET")
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
        importance = 'high' if is_important else 'normal'
        await self._make_request(
            f"/me/messages/{message_id}",
            method="PATCH",
            json_data={'importance': importance}
        )
        
        # Güncellenmiş email'i getir
        message_response = await self._make_request(f"/me/messages/{message_id}", method="GET")
        return self._parse_email(message_response)
    
    async def delete_email(self, message_id: str) -> None:
        """
        Email'i sil
        
        Args:
            message_id: Email message ID
        """
        await self._make_request(
            f"/me/messages/{message_id}",
            method="DELETE"
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
        # Microsoft Graph API message body oluştur
        message_body = {
            'subject': subject,
            'body': {
                'contentType': 'html' if html_content else 'text',
                'content': html_content or plain_text or ''
            },
            'isDraft': True
        }
        
        if to_emails:
            message_body['toRecipients'] = [{'emailAddress': {'address': email}} for email in to_emails]
        
        if cc_emails:
            message_body['ccRecipients'] = [{'emailAddress': {'address': email}} for email in cc_emails]
        
        if bcc_emails:
            message_body['bccRecipients'] = [{'emailAddress': {'address': email}} for email in bcc_emails]
        
        if draft_id:
            # Güncelle
            response = await self._make_request(
                f"/me/messages/{draft_id}",
                method="PATCH",
                json_data=message_body
            )
            message_id = draft_id
        else:
            # Yeni oluştur
            response = await self._make_request(
                "/me/messages",
                method="POST",
                json_data=message_body
            )
            message_id = response.get('id')
        
        if not message_id:
            raise Exception("Draft kaydedildi ancak message ID alınamadı")
        
        # Kaydedilen draft'ı getir
        message_response = await self._make_request(f"/me/messages/{message_id}")
        return self._parse_email(message_response, EmailCategory.DRAFTS)

