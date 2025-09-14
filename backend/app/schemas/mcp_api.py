"""
Дополнительные схемы данных для MCP API.
"""
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from datetime import datetime
from enum import Enum

# Импортируем базовые схемы
from app.schemas.mcp import TaskStatus

class TaskCreate(BaseModel):
    """Схема для создания новой задачи."""
    name: str
    params: Dict[str, Any] = Field(default_factory=dict)

class DataRequest(BaseModel):
    """Схема для запроса данных."""
    data_type: str
    params: Dict[str, Any] = Field(default_factory=dict)

class AnalysisRequest(BaseModel):
    """Схема для запроса анализа данных."""
    analysis_type: str = "full"
    include_fees: bool = True
    data: Dict[str, Any]

class ETLPipelineStep(BaseModel):
    """Схема для шага ETL пайплайна."""
    type: str  # extract, transform, load, analyze
    params: Dict[str, Any] = Field(default_factory=dict)

class ETLPipelineRequest(BaseModel):
    """Схема для запроса ETL пайплайна."""
    config: Dict[str, Any]

class FileProcessingRequest(BaseModel):
    """Схема для запроса обработки файла."""
    filename: str
    file_type: Optional[str] = None

class WebSocketSubscription(BaseModel):
    """Схема для подписки на WebSocket события."""
    topics: List[str]

class WebSocketUnsubscription(BaseModel):
    """Схема для отписки от WebSocket событий."""
    topics: Optional[List[str]] = None  # Если None, отписаться от всех