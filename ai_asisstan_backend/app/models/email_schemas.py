"""
Email Pydantic şemaları (Request/Response modelleri)
"""
from pydantic import BaseModel, EmailStr, Field, ConfigDict
from datetime import datetime
from typing import Optional, List
from enum import Enum


class EmailCategory(str, Enum):
    """Email kategorileri"""
    INBOX = "inbox"  # Gelen kutusu
    SENT = "sent"  # Giden kutusu
    SPAM = "spam"  # Spam
    DRAFTS = "drafts"  # Taslaklar
    JUNK = "junk"  # Junk (Outlook)
    PROMOTIONS = "promotions"  # Tanıtım (Gmail)
    SOCIAL = "social"  # Sosyal (Gmail)
    UPDATES = "updates"  # Güncellemeler (Gmail)
    FORUMS = "forums"  # Forumlar (Gmail)


class Email(BaseModel):
    """Email modeli"""
    id: str = Field(..., description="Email ID (Microsoft Graph message ID)")
    subject: str = Field(..., description="Email konusu")
    sender: str = Field(..., description="Gönderen email adresi")
    recipient: Optional[str] = Field(None, description="Alıcı email adresi")
    preview: Optional[str] = Field(None, description="Email önizlemesi")
    plain_text: Optional[str] = Field(None, description="Email düz metin içeriği")
    html_content: Optional[str] = Field(None, description="Email HTML içeriği")
    received_date: datetime = Field(..., description="Alınma tarihi")
    is_read: bool = Field(default=False, description="Okundu mu?")
    category: EmailCategory = Field(..., description="Email kategorisi")
    has_attachments: bool = Field(default=False, description="Ek dosya var mı?")
    
    model_config = ConfigDict(
        populate_by_name=True,
        use_enum_values=True,  # Enum'ları string olarak serialize et
        json_schema_extra={
            "example": {
                "id": "AAMkAGI1...",
                "subject": "Test Email",
                "sender": "sender@example.com",
                "recipient": "recipient@example.com",
                "preview": "Bu bir test emailidir...",
                "received_date": "2024-01-15T10:30:00Z",
                "is_read": False,
                "category": "inbox",
                "has_attachments": False
            }
        }
    )


class EmailListResponse(BaseModel):
    """Email listesi response modeli"""
    emails: List[Email] = Field(..., description="Email listesi")
    total: int = Field(..., description="Toplam email sayısı")
    category: str = Field(..., description="Kategori filtresi")
    
    model_config = ConfigDict(
        json_schema_extra={
            "example": {
                "emails": [],
                "total": 0,
                "category": "inbox"
            }
        }
    )


class SendEmailRequest(BaseModel):
    """Email gönderme request modeli"""
    to_emails: List[str] = Field(..., description="Alıcı email adresleri")
    subject: str = Field(..., description="Email konusu")
    plain_text: Optional[str] = Field(None, description="Düz metin içerik")
    html_content: Optional[str] = Field(None, description="HTML içerik")
    cc_emails: Optional[List[str]] = Field(None, description="CC alıcıları")
    bcc_emails: Optional[List[str]] = Field(None, description="BCC alıcıları")


class SaveDraftRequest(BaseModel):
    """Email taslağı kaydetme request modeli"""
    subject: str = Field(..., description="Email konusu")
    plain_text: Optional[str] = Field(None, description="Düz metin içerik")
    html_content: Optional[str] = Field(None, description="HTML içerik")
    to_emails: Optional[List[str]] = Field(None, description="Alıcı email adresleri")
    cc_emails: Optional[List[str]] = Field(None, description="CC alıcıları")
    bcc_emails: Optional[List[str]] = Field(None, description="BCC alıcıları")
    draft_id: Optional[str] = Field(None, description="Draft ID (güncelleme için)")


class ToggleImportantRequest(BaseModel):
    """Email önemli işaretleme request modeli"""
    is_important: bool = Field(..., description="True ise önemli işaretle, False ise kaldır")
