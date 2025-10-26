"""
Encrypted Secret Vault API
A password-protected API key storage system accessible via web and programmatically.
"""

import json
import base64
import hashlib
from datetime import datetime
from typing import Dict, Any, Optional
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from fastapi import APIRouter, HTTPException, Depends, Request
from pydantic import BaseModel
import os

router = APIRouter(prefix="/api/vault", tags=["vault"])

VAULT_FILE = "/home/ubuntu/archon/vault/encrypted_secrets.vault"
SALT_FILE = "/home/ubuntu/archon/vault/salt.key"

class VaultAccess(BaseModel):
    password: str

class SecretData(BaseModel):
    password: str
    secrets: Dict[str, Any]

class SecretUpdate(BaseModel):
    password: str
    key: str
    value: str

class SecretDelete(BaseModel):
    password: str
    key: str

def ensure_vault_directory():
    """Ensure vault directory exists"""
    os.makedirs("/home/ubuntu/archon/vault", exist_ok=True)

def get_or_create_salt() -> bytes:
    """Get existing salt or create new one"""
    ensure_vault_directory()

    if os.path.exists(SALT_FILE):
        with open(SALT_FILE, 'rb') as f:
            return f.read()

    # Generate new salt
    salt = os.urandom(16)
    with open(SALT_FILE, 'wb') as f:
        f.write(salt)
    return salt

def derive_key_from_password(password: str) -> bytes:
    """Derive encryption key from password using PBKDF2"""
    salt = get_or_create_salt()
    kdf = PBKDF2HMAC(
        algorithm=hashes.SHA256(),
        length=32,
        salt=salt,
        iterations=100000,
    )
    key = base64.urlsafe_b64encode(kdf.derive(password.encode()))
    return key

def encrypt_data(data: str, password: str) -> str:
    """Encrypt data with password-derived key"""
    key = derive_key_from_password(password)
    f = Fernet(key)
    encrypted = f.encrypt(data.encode())
    return base64.urlsafe_b64encode(encrypted).decode()

def decrypt_data(encrypted_data: str, password: str) -> str:
    """Decrypt data with password-derived key"""
    try:
        key = derive_key_from_password(password)
        f = Fernet(key)
        encrypted_bytes = base64.urlsafe_b64decode(encrypted_data.encode())
        decrypted = f.decrypt(encrypted_bytes)
        return decrypted.decode()
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid password or corrupted data")

def load_vault(password: str) -> Dict[str, Any]:
    """Load and decrypt vault data"""
    ensure_vault_directory()

    if not os.path.exists(VAULT_FILE):
        return {}

    with open(VAULT_FILE, 'r') as f:
        encrypted_data = f.read().strip()

    if not encrypted_data:
        return {}

    try:
        decrypted_json = decrypt_data(encrypted_data, password)
        return json.loads(decrypted_json)
    except json.JSONDecodeError:
        raise HTTPException(status_code=500, detail="Vault data corruption")

def save_vault(data: Dict[str, Any], password: str):
    """Encrypt and save vault data"""
    ensure_vault_directory()

    # Add metadata
    data["_metadata"] = {
        "last_updated": datetime.utcnow().isoformat(),
        "version": "1.0"
    }

    json_data = json.dumps(data, indent=2)
    encrypted_data = encrypt_data(json_data, password)

    with open(VAULT_FILE, 'w') as f:
        f.write(encrypted_data)

@router.post("/unlock")
async def unlock_vault(request: VaultAccess):
    """Unlock vault and return decrypted secrets"""
    try:
        secrets = load_vault(request.password)

        # Remove metadata from response
        response_data = {k: v for k, v in secrets.items() if k != "_metadata"}

        return {
            "success": True,
            "secrets": response_data,
            "last_updated": secrets.get("_metadata", {}).get("last_updated"),
            "count": len(response_data)
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Vault access error: {str(e)}")

@router.post("/save")
async def save_secrets(request: SecretData):
    """Save all secrets to vault (overwrites existing)"""
    try:
        save_vault(request.secrets, request.password)

        return {
            "success": True,
            "message": "Secrets saved successfully",
            "count": len(request.secrets),
            "timestamp": datetime.utcnow().isoformat()
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Save error: {str(e)}")

@router.post("/update")
async def update_secret(request: SecretUpdate):
    """Update a single secret in the vault"""
    try:
        # Load existing secrets
        secrets = load_vault(request.password)

        # Update the specific key
        secrets[request.key] = request.value

        # Save back
        save_vault(secrets, request.password)

        return {
            "success": True,
            "message": f"Secret '{request.key}' updated successfully",
            "timestamp": datetime.utcnow().isoformat()
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Update error: {str(e)}")

@router.post("/delete")
async def delete_secret(request: SecretDelete):
    """Delete a secret from the vault"""
    try:
        # Load existing secrets
        secrets = load_vault(request.password)

        if request.key not in secrets:
            raise HTTPException(status_code=404, detail=f"Secret '{request.key}' not found")

        # Delete the key
        del secrets[request.key]

        # Save back
        save_vault(secrets, request.password)

        return {
            "success": True,
            "message": f"Secret '{request.key}' deleted successfully",
            "timestamp": datetime.utcnow().isoformat()
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Delete error: {str(e)}")

@router.post("/get/{key}")
async def get_secret(key: str, request: VaultAccess):
    """Get a specific secret from the vault"""
    try:
        secrets = load_vault(request.password)

        if key not in secrets:
            raise HTTPException(status_code=404, detail=f"Secret '{key}' not found")

        return {
            "success": True,
            "key": key,
            "value": secrets[key],
            "timestamp": datetime.utcnow().isoformat()
        }
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Get error: {str(e)}")

@router.get("/status")
async def vault_status():
    """Get vault status without revealing contents"""
    ensure_vault_directory()

    vault_exists = os.path.exists(VAULT_FILE)
    salt_exists = os.path.exists(SALT_FILE)

    file_size = 0
    if vault_exists:
        file_size = os.path.getsize(VAULT_FILE)

    return {
        "vault_exists": vault_exists,
        "salt_exists": salt_exists,
        "vault_size_bytes": file_size,
        "vault_encrypted": vault_exists and file_size > 0,
        "endpoint": "/api/vault",
        "available_operations": [
            "POST /unlock - Decrypt and view all secrets",
            "POST /save - Save all secrets (overwrites)",
            "POST /update - Update single secret",
            "POST /delete - Delete single secret",
            "POST /get/{key} - Get specific secret",
            "GET /status - This status endpoint"
        ]
    }