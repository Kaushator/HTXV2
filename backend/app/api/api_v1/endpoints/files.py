from fastapi import APIRouter, UploadFile, File, Depends, HTTPException
from fastapi.responses import FileResponse
from typing import Optional
import os
from app.services.file_upload_service import FileUploadService
from app.core.security import get_current_user
from app.models.user import User

router = APIRouter()

@router.post("/upload")
async def upload_file(
    file: UploadFile = File(...),
    current_user: Optional[User] = Depends(get_current_user)
):
    """
    Upload CSV/XLSX file with validation and get signed URL
    
    - **file**: CSV or Excel file to upload
    - Returns: File info with signed URL for access
    """
    upload_service = FileUploadService()
    
    user_id = current_user.id if current_user else None
    result = await upload_service.process_upload(file, user_id)
    
    return result

@router.get("/download/{filename}")
async def download_file(filename: str):
    """
    Download file endpoint for local development
    (In production, would use GCS signed URLs directly)
    """
    file_path = f"/tmp/uploads/{filename}"
    
    if not os.path.exists(file_path):
        raise HTTPException(status_code=404, detail="File not found")
    
    return FileResponse(
        path=file_path,
        filename=filename,
        media_type='application/octet-stream'
    )

@router.get("/validate")
async def validate_file_format(
    file: UploadFile = File(...)
):
    """
    Validate file format without uploading
    
    - **file**: File to validate
    - Returns: Validation results
    """
    upload_service = FileUploadService()
    
    # Validate file metadata
    validation = upload_service.validate_file(file)
    if not validation["valid"]:
        return {
            "valid": False,
            "errors": validation["errors"]
        }
    
    # Read and validate content
    file_content = await file.read()
    
    _, ext = os.path.splitext(file.filename.lower())
    if ext == '.csv':
        content_validation = await upload_service.validate_csv_content(file_content)
    elif ext in ['.xlsx', '.xls']:
        content_validation = await upload_service.validate_excel_content(file_content)
    else:
        content_validation = {"valid": False, "errors": ["Unsupported file type"]}
    
    return content_validation