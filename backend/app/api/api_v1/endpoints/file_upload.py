"""
File Upload API - эндпойнты для загрузки и обработки файлов.
"""
import logging
import uuid
from typing import Dict, Any, List, Optional

from fastapi import APIRouter, UploadFile, File, Form, HTTPException, BackgroundTasks, Depends
from fastapi.responses import JSONResponse

from app.tools.data_processor import DataProcessor
from app.services.mcp_service import get_mcp_service, MCPService

logger = logging.getLogger(__name__)

# Создаем роутер для API загрузки файлов
router = APIRouter()

@router.post("/upload", response_model=Dict[str, Any])
async def upload_file(
    background_tasks: BackgroundTasks,
    file: UploadFile = File(...),
    notify_clients: bool = Form(False),
    mcp_service: MCPService = Depends(get_mcp_service)
):
    """
    Загрузка и обработка файла (CSV, XLSX).
    
    - **file**: Файл для загрузки (CSV или XLSX)
    - **notify_clients**: Уведомлять ли клиентов через WebSocket о загрузке файла
    
    Returns:
        Dict с информацией о загруженном файле и результатами обработки
    """
    # Проверка типа файла
    filename = file.filename
    if not filename:
        raise HTTPException(status_code=400, detail="Файл без имени")
    
    # Проверка расширения
    if not (filename.endswith('.csv') or filename.endswith('.xlsx') or filename.endswith('.xls')):
        raise HTTPException(
            status_code=400, 
            detail="Неподдерживаемый формат файла. Поддерживаются только CSV и XLSX/XLS."
        )
    
    try:
        # Чтение содержимого файла
        file_content = await file.read()
        if not file_content:
            raise HTTPException(status_code=400, detail="Пустой файл")
        
        # Обработка файла
        result = await DataProcessor.process_file(
            file_content=file_content,
            filename=filename
        )
        
        # Генерируем уникальный ID для загрузки
        upload_id = str(uuid.uuid4())
        result["upload_id"] = upload_id
        
        # Сохраняем результат в кэше MCP
        mcp_service.data_cache[f"upload_{upload_id}"] = result
        
        # Если указано, отправляем уведомление клиентам через WebSocket
        if notify_clients:
            background_tasks.add_task(
                mcp_service.broadcast_message,
                {
                    "type": "file_uploaded",
                    "upload_id": upload_id,
                    "filename": filename,
                    "rows": result["rows"],
                    "columns": result["columns"]
                }
            )
        
        return {
            "status": "success",
            "upload_id": upload_id,
            "filename": filename,
            "rows": result["rows"],
            "columns": result["columns"],
            "preview": result["data"][:10]  # Возвращаем только первые 10 строк для превью
        }
    
    except ValueError as e:
        logger.error(f"Ошибка при обработке файла: {str(e)}")
        raise HTTPException(status_code=400, detail=str(e))
    
    except Exception as e:
        logger.exception(f"Неожиданная ошибка при загрузке файла: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Ошибка сервера: {str(e)}")

@router.get("/uploads/{upload_id}", response_model=Dict[str, Any])
async def get_upload_data(
    upload_id: str,
    mcp_service: MCPService = Depends(get_mcp_service)
):
    """
    Получение данных загруженного файла по ID.
    
    - **upload_id**: ID загрузки
    
    Returns:
        Dict с данными загруженного файла
    """
    # Получаем данные из кэша MCP
    data = mcp_service.data_cache.get(f"upload_{upload_id}")
    if not data:
        raise HTTPException(status_code=404, detail=f"Данные загрузки с ID {upload_id} не найдены")
    
    return data