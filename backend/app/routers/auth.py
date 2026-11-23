"""Authentication-related endpoints.

Supabase Auth owns the actual login/registration/password-recovery flow (email
and Google OAuth). The backend verifies the issued JWT and provisions the
VantoPay account record against it.
"""
from __future__ import annotations

from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..db import get_db
from ..schemas import AccountOut, RegisterAccountRequest, RegisterResponse, VerifyTokenResponse
from ..security import get_current_principal, Principal
from ..services import accounts as accounts_service

router = APIRouter(prefix="/auth", tags=["auth"])


@router.get("/me", response_model=VerifyTokenResponse)
def me(principal: Principal = Depends(get_current_principal)) -> VerifyTokenResponse:
    """Return the authenticated principal for the presented token."""
    return VerifyTokenResponse(
        user_id=principal.user_id, email=principal.email, role=principal.role
    )


@router.post("/accounts", response_model=RegisterResponse)
def register_account(
    payload: RegisterAccountRequest,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> RegisterResponse:
    """Open a VantoPay account for the authenticated Supabase user."""
    account = accounts_service.open_account(
        db,
        user_id=principal.user_id,
        holder_name=payload.holder_name,
        document=payload.document,
        transaction_limit=payload.transaction_limit,
        daily_limit=payload.daily_limit,
        actor_user_id=principal.user_id,
        actor_role=principal.role,
    )
    return RegisterResponse(account=AccountOut.model_validate(account))
