from app.routers.profile import router as profile_router
from app.routers.contacts import router as contacts_router
from app.routers.devices import router as devices_router
from app.routers.emergencies import router as emergencies_router
from app.routers.organizations import router as organizations_router
from app.routers.admin import router as admin_router

__all__ = [
    "profile_router",
    "contacts_router",
    "devices_router",
    "emergencies_router",
    "organizations_router",
    "admin_router",
]
