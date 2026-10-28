import os
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

from app.core.config import settings
from app.core.firebase import initialize_firebase
from app.routers import (
    profile_router,
    contacts_router,
    devices_router,
    emergencies_router,
    organizations_router,
    admin_router,
)

# Configure logging
logging.basicConfig(
    level=logging.INFO if settings.DEBUG else logging.WARNING,
    format="%(asctime)s - %(name)s - %(levelname)s - %(message)s",
)
logger = logging.getLogger("aegis_backend")

# Rate Limiter setup
limiter = Limiter(key_func=get_remote_address, default_limits=[f"{settings.RATE_LIMIT_PER_MINUTE}/minute"])


@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Initialize Firebase Admin SDK
    logger.info("Initializing AEGIS One backend services...")
    try:
        initialize_firebase()
    except Exception as e:
        logger.warning("Firebase initialization warning during startup: %s", e)
    yield
    # Shutdown
    logger.info("AEGIS One backend shut down complete.")


app = FastAPI(
    title=settings.PROJECT_NAME,
    description="Role-Based Authentication and User-Management API for AEGIS One Smart Emergency Response System.",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    lifespan=lifespan,
)

# Add Rate Limiter state and handler
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health", tags=["Health"], status_code=status.HTTP_200_OK)
async def health_check():
    """
    Health check endpoint returning system status and configuration mode.
    """
    return {
        "status": "healthy",
        "service": "AEGIS One Authentication & Access Control API",
        "environment": settings.ENVIRONMENT,
        "version": "1.0.0",
    }


# Include API v1 Routers
app.include_router(profile_router, prefix=settings.API_V1_STR)
app.include_router(contacts_router, prefix=settings.API_V1_STR)
app.include_router(devices_router, prefix=settings.API_V1_STR)
app.include_router(emergencies_router, prefix=settings.API_V1_STR)
app.include_router(organizations_router, prefix=settings.API_V1_STR)
app.include_router(admin_router, prefix=settings.API_V1_STR)

# Mount Static Web Interface
static_dir = os.path.join(os.path.dirname(os.path.dirname(__file__)), "static")
if os.path.exists(static_dir):
    from fastapi.staticfiles import StaticFiles
    from fastapi.responses import FileResponse

    @app.get("/", include_in_schema=False)
    async def serve_index():
        return FileResponse(os.path.join(static_dir, "index.html"))

    app.mount("/static", StaticFiles(directory=static_dir), name="static")

