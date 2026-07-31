import firebase_admin
from firebase_admin import auth as firebase_auth
from firebase_admin import credentials

from app.core.config import settings

_cred = credentials.Certificate(settings.firebase_credentials_path)
firebase_app = firebase_admin.initialize_app(_cred)


class FirebaseUser:
    def __init__(self, uid: str, email: str | None, name: str | None):
        self.uid = uid
        self.email = email
        self.name = name


def verify_firebase_id_token(id_token: str) -> FirebaseUser:
    """Verifies a Firebase ID token and returns the decoded user info.

    Raises firebase_admin.auth.InvalidIdTokenError / ExpiredIdTokenError / etc. on failure.
    """
    decoded = firebase_auth.verify_id_token(id_token)
    return FirebaseUser(
        uid=decoded["uid"],
        email=decoded.get("email"),
        name=decoded.get("name"),
    )
