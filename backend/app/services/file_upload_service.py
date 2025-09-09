from typing import Optional, List, Dict, Any
from fastapi import UploadFile, HTTPException
import pandas as pd
import tempfile
import os
from io import BytesIO
from google.cloud import storage
from datetime import datetime, timedelta
import hashlib
import logging
from app.core.config import settings

logger = logging.getLogger(__name__)

class FileUploadService:
    """Service for handling file uploads with GCS signed URLs"""
    
    def __init__(self):
        self.max_file_size = 10 * 1024 * 1024  # 10MB
        self.allowed_extensions = {'.csv', '.xlsx', '.xls'}
        self.bucket_name = settings.GCS_RAW_BUCKET or "htxv2-uploads"
        
        # Initialize GCS client if credentials are available
        try:
            self.gcs_client = storage.Client(project=settings.GOOGLE_CLOUD_PROJECT)
            self.bucket = self.gcs_client.bucket(self.bucket_name)
        except Exception as e:
            logger.warning(f"GCS not available, using local storage: {e}")
            self.gcs_client = None
            self.bucket = None
    
    def validate_file(self, file: UploadFile) -> Dict[str, Any]:
        """Validate uploaded file"""
        errors = []
        
        # Check file size
        if hasattr(file, 'size') and file.size and file.size > self.max_file_size:
            errors.append(f"File size {file.size} exceeds maximum {self.max_file_size} bytes")
        
        # Check file extension
        if file.filename:
            _, ext = os.path.splitext(file.filename.lower())
            if ext not in self.allowed_extensions:
                errors.append(f"File extension {ext} not allowed. Allowed: {self.allowed_extensions}")
        else:
            errors.append("Filename is required")
        
        # Check content type
        allowed_content_types = {
            'text/csv',
            'application/vnd.ms-excel',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        }
        if file.content_type not in allowed_content_types:
            errors.append(f"Content type {file.content_type} not allowed")
        
        return {
            "valid": len(errors) == 0,
            "errors": errors,
            "filename": file.filename,
            "content_type": file.content_type,
            "size": getattr(file, 'size', None)
        }
    
    async def validate_csv_content(self, file_content: bytes) -> Dict[str, Any]:
        """Validate CSV content structure"""
        try:
            # Try to read as CSV
            df = pd.read_csv(BytesIO(file_content))
            
            # Basic validation
            if df.empty:
                return {"valid": False, "errors": ["File is empty"]}
            
            if len(df.columns) == 0:
                return {"valid": False, "errors": ["No columns found"]}
            
            # Check for required columns (example for crypto data)
            required_columns = ['symbol', 'price']  # Minimal requirements
            missing_columns = [col for col in required_columns if col not in df.columns]
            
            if missing_columns:
                return {
                    "valid": False, 
                    "errors": [f"Missing required columns: {missing_columns}"]
                }
            
            return {
                "valid": True,
                "row_count": len(df),
                "column_count": len(df.columns),
                "columns": list(df.columns),
                "sample_data": df.head(3).to_dict('records') if len(df) > 0 else []
            }
            
        except Exception as e:
            return {"valid": False, "errors": [f"Invalid CSV format: {str(e)}"]}
    
    async def validate_excel_content(self, file_content: bytes) -> Dict[str, Any]:
        """Validate Excel content structure"""
        try:
            # Try to read as Excel
            df = pd.read_excel(BytesIO(file_content))
            
            # Basic validation (same as CSV)
            if df.empty:
                return {"valid": False, "errors": ["File is empty"]}
            
            if len(df.columns) == 0:
                return {"valid": False, "errors": ["No columns found"]}
            
            return {
                "valid": True,
                "row_count": len(df),
                "column_count": len(df.columns),
                "columns": list(df.columns),
                "sample_data": df.head(3).to_dict('records') if len(df) > 0 else []
            }
            
        except Exception as e:
            return {"valid": False, "errors": [f"Invalid Excel format: {str(e)}"]}
    
    def generate_filename(self, original_filename: str, user_id: Optional[int] = None) -> str:
        """Generate unique filename for storage"""
        timestamp = datetime.utcnow().strftime('%Y%m%d_%H%M%S')
        
        # Create hash from original filename and timestamp
        hash_input = f"{original_filename}_{timestamp}_{user_id or 'anonymous'}"
        file_hash = hashlib.md5(hash_input.encode()).hexdigest()[:8]
        
        name, ext = os.path.splitext(original_filename)
        return f"uploads/{timestamp}_{file_hash}_{name}{ext}"
    
    async def upload_to_gcs(self, file_content: bytes, filename: str) -> str:
        """Upload file to Google Cloud Storage"""
        if not self.gcs_client or not self.bucket:
            raise HTTPException(status_code=503, detail="GCS not available")
        
        try:
            blob = self.bucket.blob(filename)
            blob.upload_from_string(file_content)
            
            logger.info(f"File uploaded to GCS: {filename}")
            return f"gs://{self.bucket_name}/{filename}"
            
        except Exception as e:
            logger.error(f"Error uploading to GCS: {e}")
            raise HTTPException(status_code=500, detail="Upload failed")
    
    async def save_local_fallback(self, file_content: bytes, filename: str) -> str:
        """Save file locally as fallback"""
        try:
            # Create uploads directory if it doesn't exist
            upload_dir = "/tmp/uploads"
            os.makedirs(upload_dir, exist_ok=True)
            
            local_path = os.path.join(upload_dir, os.path.basename(filename))
            with open(local_path, 'wb') as f:
                f.write(file_content)
            
            logger.info(f"File saved locally: {local_path}")
            return local_path
            
        except Exception as e:
            logger.error(f"Error saving file locally: {e}")
            raise HTTPException(status_code=500, detail="Local save failed")
    
    def generate_signed_url(self, filename: str, expiration_minutes: int = 60) -> str:
        """Generate signed URL for file access"""
        if not self.gcs_client or not self.bucket:
            # Return a placeholder URL for local development
            return f"/api/v1/files/download/{os.path.basename(filename)}"
        
        try:
            blob = self.bucket.blob(filename.replace(f"gs://{self.bucket_name}/", ""))
            url = blob.generate_signed_url(
                expiration=datetime.utcnow() + timedelta(minutes=expiration_minutes),
                method='GET'
            )
            return url
            
        except Exception as e:
            logger.error(f"Error generating signed URL: {e}")
            raise HTTPException(status_code=500, detail="URL generation failed")
    
    async def process_upload(self, file: UploadFile, user_id: Optional[int] = None) -> Dict[str, Any]:
        """Complete file upload processing"""
        # Validate file
        validation = self.validate_file(file)
        if not validation["valid"]:
            raise HTTPException(status_code=400, detail={"errors": validation["errors"]})
        
        # Read file content
        file_content = await file.read()
        
        # Validate content based on file type
        _, ext = os.path.splitext(file.filename.lower())
        if ext == '.csv':
            content_validation = await self.validate_csv_content(file_content)
        elif ext in ['.xlsx', '.xls']:
            content_validation = await self.validate_excel_content(file_content)
        else:
            content_validation = {"valid": False, "errors": ["Unsupported file type"]}
        
        if not content_validation["valid"]:
            raise HTTPException(status_code=400, detail={"errors": content_validation["errors"]})
        
        # Generate unique filename
        storage_filename = self.generate_filename(file.filename, user_id)
        
        # Upload to storage
        try:
            if self.gcs_client:
                storage_path = await self.upload_to_gcs(file_content, storage_filename)
            else:
                storage_path = await self.save_local_fallback(file_content, storage_filename)
        except Exception as e:
            logger.error(f"Upload failed: {e}")
            raise HTTPException(status_code=500, detail="Upload failed")
        
        # Generate signed URL
        signed_url = self.generate_signed_url(storage_filename)
        
        return {
            "success": True,
            "filename": file.filename,
            "storage_path": storage_path,
            "signed_url": signed_url,
            "file_info": {
                "size": len(file_content),
                "rows": content_validation.get("row_count", 0),
                "columns": content_validation.get("column_count", 0),
                "sample_data": content_validation.get("sample_data", [])
            },
            "expires_at": (datetime.utcnow() + timedelta(hours=1)).isoformat()
        }