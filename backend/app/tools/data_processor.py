"""
CSV/XLSX Data Processor - Инструменты для обработки загруженных файлов.
"""
import asyncio
import logging
from pathlib import Path
from typing import Dict, List, Any, Optional, Union, Tuple
import pandas as pd
import io

logger = logging.getLogger(__name__)

class DataProcessor:
    """Класс для обработки данных из CSV/XLSX файлов."""
    
    @staticmethod
    async def process_file(
        file_content: bytes, 
        filename: str, 
        file_type: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Асинхронно обрабатывает содержимое файла.
        
        Args:
            file_content: Содержимое файла в байтах
            filename: Имя файла
            file_type: Тип файла (опционально, если не указан - определяется по расширению)
            
        Returns:
            Dict с информацией о файле и обработанными данными
        """
        # Определение типа файла по расширению, если не указан явно
        if not file_type:
            file_ext = Path(filename).suffix.lower()
            if file_ext == '.csv':
                file_type = 'csv'
            elif file_ext in ['.xlsx', '.xls']:
                file_type = 'excel'
            else:
                raise ValueError(f"Неподдерживаемый тип файла: {file_ext}")
        
        logger.info(f"Обработка файла {filename} типа {file_type}")
        
        # Запуск обработки в отдельном потоке, чтобы не блокировать event loop
        loop = asyncio.get_event_loop()
        result = await loop.run_in_executor(
            None, 
            DataProcessor._process_file_sync, 
            file_content, 
            filename, 
            file_type
        )
        
        return result
    
    @staticmethod
    def _process_file_sync(
        file_content: bytes, 
        filename: str, 
        file_type: str
    ) -> Dict[str, Any]:
        """
        Синхронная обработка файла (запускается в отдельном потоке).
        
        Args:
            file_content: Содержимое файла в байтах
            filename: Имя файла
            file_type: Тип файла ('csv' или 'excel')
            
        Returns:
            Dict с информацией о файле и обработанными данными
        """
        file_stream = io.BytesIO(file_content)
        
        try:
            # Загрузка данных в pandas DataFrame
            if file_type == 'csv':
                # Пробуем разные разделители и кодировки
                try:
                    df = pd.read_csv(file_stream)
                except:
                    # Если не удалось, пробуем другие разделители
                    file_stream.seek(0)
                    df = pd.read_csv(file_stream, sep=';')
            elif file_type == 'excel':
                df = pd.read_excel(file_stream)
            else:
                raise ValueError(f"Неподдерживаемый тип файла: {file_type}")
            
            # Базовая валидация и очистка данных
            df = DataProcessor._clean_dataframe(df)
            
            # Анализ данных
            stats = DataProcessor._analyze_data(df)
            
            # Подготовка результата
            result = {
                "filename": filename,
                "type": file_type,
                "rows": len(df),
                "columns": df.columns.tolist(),
                "stats": stats,
                # Преобразуем DataFrame в список словарей для JSON
                "data": df.head(100).to_dict(orient="records"),
                "preview_limit": 100
            }
            
            return result
        
        except Exception as e:
            logger.error(f"Ошибка при обработке файла {filename}: {e}")
            raise ValueError(f"Ошибка при обработке файла: {e}")
    
    @staticmethod
    def _clean_dataframe(df: pd.DataFrame) -> pd.DataFrame:
        """
        Базовая очистка и нормализация DataFrame.
        
        Args:
            df: Исходный DataFrame
            
        Returns:
            Очищенный DataFrame
        """
        # Удаление дубликатов
        df = df.drop_duplicates()
        
        # Нормализация названий столбцов (нижний регистр, без пробелов)
        df.columns = [col.strip().lower().replace(' ', '_') for col in df.columns]
        
        # Удаление строк, где все значения отсутствуют
        df = df.dropna(how='all')
        
        return df
    
    @staticmethod
    def _analyze_data(df: pd.DataFrame) -> Dict[str, Any]:
        """
        Анализ данных в DataFrame.
        
        Args:
            df: DataFrame для анализа
            
        Returns:
            Dict с результатами анализа
        """
        stats = {
            "missing_values": df.isna().sum().to_dict(),
            "dtypes": {col: str(dtype) for col, dtype in df.dtypes.items()},
            "summary": {}
        }
        
        # Статистика для числовых столбцов
        numeric_cols = df.select_dtypes(include=['number']).columns
        if not numeric_cols.empty:
            stats["summary"]["numeric"] = df[numeric_cols].describe().to_dict()
        
        # Информация о категориальных данных
        cat_cols = df.select_dtypes(include=['object']).columns
        if not cat_cols.empty:
            stats["summary"]["categorical"] = {}
            for col in cat_cols:
                # Количество уникальных значений
                stats["summary"]["categorical"][col] = {
                    "unique_values": df[col].nunique(),
                    "top_values": df[col].value_counts().head(5).to_dict()
                }
        
        return stats