"""
Kimlik doğrulama endpoint'leri
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from app.core.database import get_db
from app.core.security import create_access_token, verify_password, get_password_hash
from app.schemas.user import UserCreate, UserResponse, Token
from app.services.auth_service import AuthService

router = APIRouter()


@router.post("/register", response_model=UserResponse, status_code=status.HTTP_201_CREATED)
async def register(user_data: UserCreate, db: Session = Depends(get_db)):
    """Kullanıcı kaydı"""
    auth_service = AuthService(db)
    return await auth_service.register_user(user_data)


@router.post("/login", response_model=Token)
async def login(user_data: UserCreate, db: Session = Depends(get_db)):
    """Kullanıcı girişi"""
    auth_service = AuthService(db)
    user = await auth_service.authenticate_user(user_data.email, user_data.password)
    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect email or password"
        )
    
    access_token = create_access_token(data={"sub": user.email})
    return {"access_token": access_token, "token_type": "bearer"}


@router.post("/google")
async def google_auth(token: str, db: Session = Depends(get_db)):
    """Google OAuth ile giriş"""
    # TODO: Google token doğrulama ve kullanıcı oluşturma
    pass


@router.post("/microsoft")
async def microsoft_auth(token: str, db: Session = Depends(get_db)):
    """Microsoft OAuth ile giriş"""
    # TODO: Microsoft token doğrulama ve kullanıcı oluşturma
    pass

