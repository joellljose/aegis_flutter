import logging
from typing import List, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from app.auth.dependencies import get_current_user
from app.services.firestore_service import firestore_service
from app.schemas.device import DeviceRegister, DeviceResponse, DeviceStatus

logger = logging.getLogger(__name__)

router = APIRouter(prefix="/devices", tags=["Devices"])


@router.post("", response_model=DeviceResponse, status_code=status.HTTP_201_CREATED)
async def register_device(
    device_data: DeviceRegister,
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """
    Registers or pairs an AEGIS hardware device with the authenticated owner.
    Prevents claiming a device already paired with another owner.
    """
    owner_uid = current_user["uid"]
    device_id = device_data.device_id.strip()

    existing = firestore_service.get_device(device_id)
    if existing and existing.get("owner_uid") != owner_uid:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="This device is already paired to another AEGIS user.",
        )

    data = {
        "device_id": device_id,
        "owner_uid": owner_uid,
        "device_name": device_data.device_name,
        "device_status": DeviceStatus.PAIRED.value,
    }

    registered = firestore_service.register_device(device_id, data)
    # Also update user's paired_device_id in profile
    firestore_service.update_user(owner_uid, {"paired_device_id": device_id})

    logger.info("Device %s paired with owner %s", device_id, owner_uid)
    return registered


@router.get("", response_model=List[DeviceResponse])
async def list_devices(
    current_user: Dict[str, Any] = Depends(get_current_user),
):
    """
    Lists only the devices owned by the authenticated user.
    """
    owner_uid = current_user["uid"]
    return firestore_service.list_user_devices(owner_uid)
