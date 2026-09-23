from typing import Annotated

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from backend.core.supabase import get_supabase_client
from backend.schemas.auth import UserProfile

bearer = HTTPBearer(auto_error=False)


def get_current_user(
    credentials: Annotated[HTTPAuthorizationCredentials | None, Depends(bearer)],
) -> UserProfile:
    if credentials is None or credentials.scheme.lower() != "bearer":
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Authentication required")
    client = get_supabase_client()
    try:
        response = client.auth.get_user(credentials.credentials)
        if response is None or response.user is None:
            raise ValueError("Unknown user")
        row = (
            client.table("profiles")
            .select("*")
            .eq("id", str(response.user.id))
            .single()
            .execute()
            .data
        )
    except Exception as exc:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid or expired token") from exc
    if not row:
        raise HTTPException(status.HTTP_403_FORBIDDEN, "User profile is unavailable")
    if row.get("is_suspended"):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Account is suspended")
    values = dict(row)
    values.setdefault("email", response.user.email)
    return UserProfile(**values)


CurrentUser = Annotated[UserProfile, Depends(get_current_user)]
