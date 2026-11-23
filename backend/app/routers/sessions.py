"""Device / session management endpoints."""
from __future__ import annotations

from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy.orm import Session

from ..db import get_db
from ..models import Session as SessionModel
from ..schemas import MessageResponse
from ..security import get_current_principal, Principal, hash_token, record_audit, utcnow

router = APIRouter(prefix="/sessions", tags=["sessions"])


def _client_label(request: Request) -> str:
    ua = request.headers.get("user-agent", "dispositivo")
    return ua[:200]


@router.get("")
def list_sessions(
    request: Request,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> list[dict]:
    sessions = (
        db.query(SessionModel)
        .filter(SessionModel.user_id == principal.user_id)
        .order_by(SessionModel.last_seen_at.desc())
        .all()
    )
    return [
        {
            "id": s.id,
            "device_label": s.device_label,
            "created_at": s.created_at,
            "last_seen_at": s.last_seen_at,
            "revoked": s.revoked_at is not None,
        }
        for s in sessions
    ]


@router.post("/register", response_model=MessageResponse)
def register_session(
    request: Request,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> MessageResponse:
    """Record the current device as an active session."""
    token = _bearer(request.headers.get("authorization"))
    if not token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token ausente para registrar sessão.",
        )
    s = SessionModel(
        user_id=principal.user_id,
        device_label=_client_label(request),
        token_hash=hash_token(token),
    )
    db.add(s)
    db.commit()
    return MessageResponse(detail="Sessão registrada.")


@router.delete("/{session_id}", response_model=MessageResponse)
def revoke_session(
    session_id: str,
    principal: Principal = Depends(get_current_principal),
    db: Session = Depends(get_db),
) -> MessageResponse:
    s = db.query(SessionModel).filter(
        SessionModel.id == session_id, SessionModel.user_id == principal.user_id
    ).first()
    if s is None:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Sessão não encontrada."
        )
    s.revoked_at = utcnow()
    db.commit()
    record_audit(
        db, actor_user_id=principal.user_id, actor_role=principal.role,
        action="session_revoked", target=session_id,
    )
    return MessageResponse(detail="Sessão revogada.")


def _bearer(authorization: str | None) -> str | None:
    if not authorization:
        return None
    parts = authorization.split(None, 1)
    if len(parts) == 2 and parts[0].lower() == "bearer":
        return parts[1].strip()
    return None
