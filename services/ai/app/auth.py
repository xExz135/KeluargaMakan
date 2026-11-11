"""Authentication between the API and the AI service.

The API presents a shared secret as a bearer token. The secret comes from
configuration (Secret Manager in staging and production); a previous token can
be configured during rotation. Comparison is constant-time.
"""

from __future__ import annotations

import hmac

from fastapi import Request

from app.errors import ErrorCode, RequestRejectedError


def require_internal_token(request: Request) -> None:
    """FastAPI dependency: reject the call unless it carries a configured token."""
    tokens: tuple[str, ...] = request.app.state.settings.auth_tokens
    header = request.headers.get("authorization", "")
    scheme, _, presented = header.partition(" ")
    if scheme.lower() != "bearer" or not presented:
        raise RequestRejectedError(401, ErrorCode.UNAUTHORIZED)
    presented_bytes = presented.strip().encode()
    # Check every token so timing does not reveal which one matched.
    matched = False
    for token in tokens:
        matched |= hmac.compare_digest(presented_bytes, token.encode())
    if not matched:
        raise RequestRejectedError(401, ErrorCode.UNAUTHORIZED)
