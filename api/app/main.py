from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.routers import auth
from app.routers import land
from app.routers import oilseed
from app.routers import price
from app.routers import scheme
from app.routers import user

app = FastAPI(title="Tilahan Saathi API")

# Dev-only: wide open so local test pages / the Flutter web build can call the API.
# Tighten this to specific origins before shipping.
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(user.router)
app.include_router(land.router)
app.include_router(oilseed.router)
app.include_router(scheme.router)
app.include_router(price.router)