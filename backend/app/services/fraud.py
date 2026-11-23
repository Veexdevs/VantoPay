"""Suspicious-activity detection.

A lightweight rule engine assigns a risk score to a movement request. Scores
are persisted as ``SuspiciousEvent`` rows; a score above the configured
threshold can automatically block further movement from the account. This is a
defensive control layer on top of idempotency and authorization — it never
alters balances itself.
"""
from __future__ import annotations

from dataclasses import dataclass

from sqlalchemy import func
from sqlalchemy.orm import Session

from ..config import settings
from ..models import SuspiciousEvent, Transaction
from ..security import record_suspicious


@dataclass
class RiskAssessment:
    score: int
    reasons: list[str]
    blocked: bool


def assess_movement(
    db: Session,
    *,
    account_id: str,
    amount: float,
    recent_count: int = 5,
    window_minutes: int = 10,
    unusual_recipient: bool = False,
    failed_attempts: int = 0,
) -> RiskAssessment:
    score = 0
    reasons: list[str] = []

    threshold = settings.suspicious_score_threshold

    # 1. Very large amount relative to recent activity.
    if amount > 0:
        recent_total = db.query(
            func.coalesce(func.sum(Transaction.amount), 0.0)
        ).filter(
            Transaction.account_id == account_id,
            Transaction.direction == "credit",
        ).scalar() or 0.0
        if float(recent_total) > 0 and amount > float(recent_total) * 5:
            score += 30
            reasons.append("Valor incomum em relação ao histórico recente.")

    # 2. High velocity of recent transactions.
    recent = (
        db.query(Transaction)
        .filter(Transaction.account_id == account_id)
        .order_by(Transaction.created_at.desc())
        .limit(recent_count)
        .all()
    )
    if len(recent) >= recent_count:
        score += 20
        reasons.append("Alta frequência de operações recentes.")

    # 3. Unusual counterparty.
    if unusual_recipient:
        score += 25
        reasons.append("Destinatário incomum.")

    # 4. Prior failed attempts (possible brute force / guessing).
    if failed_attempts >= 3:
        score += 25
        reasons.append("Múltiplas tentativas incorretas prévias.")

    blocked = score >= threshold

    if score > 0:
        record_suspicious(
            db, account_id=account_id, user_id=None, score=score,
            reason="; ".join(reasons),
            metadata={"amount": amount, "blocked": blocked},
        )

    return RiskAssessment(score=score, reasons=reasons, blocked=blocked)
