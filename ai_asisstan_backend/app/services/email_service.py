"""
Email servisi
"""
from sqlalchemy.orm import Session


class EmailService:
    """Email işlemleri servisi"""
    
    def __init__(self, db: Session):
        self.db = db
    
    async def get_user_accounts(self, user_id: int):
        """Kullanıcının email hesaplarını getir"""
        # TODO: Implement
        pass
    
    async def sync_messages(self, account_id: int):
        """Email mesajlarını senkronize et"""
        # TODO: Implement Gmail/Outlook API entegrasyonu
        pass

