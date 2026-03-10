import firebase_admin
from firebase_admin import auth as firebase_auth


def _ensure_app():
    if not firebase_admin._apps:
        firebase_admin.initialize_app()


def verify_firebase_token(id_token: str) -> dict:
    """Verify a Firebase ID token and return user claims."""
    _ensure_app()
    decoded = firebase_auth.verify_id_token(id_token)
    return {
        "uid": decoded["uid"],
        "email": decoded.get("email", ""),
        "name": decoded.get("name", ""),
        "picture": decoded.get("picture", ""),
    }
