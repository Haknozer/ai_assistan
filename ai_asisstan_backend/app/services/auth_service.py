"""
Kimlik doğrulama servisi
"""
from sqlalchemy.orm import Session
from app.models.user import User
from app.schemas.user import UserCreate, UserResponse
from app.core.security import get_password_hash, verify_password


class AuthService:
    """Kimlik doğrulama servisi"""
    
    def __init__(self, db: Session):
        self.db = db
    
    async def register_user(self, user_data: UserCreate) -> UserResponse:
        """Yeni kullanıcı kaydı"""
        # Email kontrolü
        existing_user = self.db.query(User).filter(User.email == user_data.email).first()
        if existing_user:
            raise ValueError("Email already registered")
        
        # Yeni kullanıcı oluştur
        hashed_password = get_password_hash(user_data.password)
        new_user = User(
            email=user_data.email,
            hashed_password=hashed_password,
            full_name=user_data.full_name
        )
        
        self.db.add(new_user)
        self.db.commit()
        self.db.refresh(new_user)
        
        return UserResponse.model_validate(new_user)
    
    async def authenticate_user(self, email: str, password: str) -> User | None:
        """Kullanıcı kimlik doğrulama"""
        user = self.db.query(User).filter(User.email == email).first()
        if not user:
            return None
        
        if not user.hashed_password:
            return None
        
        if not verify_password(password, user.hashed_password):
            return None
        
        return user

