from pydantic import BaseModel


class FirebaseLoginRequest(BaseModel):
    firebase_id_token: str


class LoginResponse(BaseModel):
    user_id: str
    access_token: str
    token_type: str = "bearer"
