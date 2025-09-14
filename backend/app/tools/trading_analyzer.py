"""
Trading Tools - Инструменты для расчетов и анализа торговых данных.
"""
import logging
import numpy as np
import pandas as pd
from typing import Dict, List, Any, Optional, Union, Tuple

logger = logging.getLogger(__name__)

class TradingAnalyzer:
    """Класс для анализа и расчетов торговых данных."""
    
    @staticmethod
    def calculate_pnl(
        trades: List[Dict[str, Any]],
        include_fees: bool = True
    ) -> Dict[str, Any]:
        """
        Расчет PnL на основе списка сделок.
        
        Args:
            trades: Список сделок, каждая сделка - словарь с данными
            include_fees: Учитывать ли комиссии при расчете
            
        Returns:
            Dict с результатами расчета PnL
        """
        if not trades:
            return {"total_pnl": 0, "winning_trades": 0, "losing_trades": 0, "win_rate": 0}
        
        df = pd.DataFrame(trades)
        
        # Проверяем наличие необходимых полей
        required_fields = ['side', 'price', 'quantity']
        if not all(field in df.columns for field in required_fields):
            missing = [f for f in required_fields if f not in df.columns]
            raise ValueError(f"Отсутствуют обязательные поля: {missing}")
        
        # Расчет базового PnL
        df['trade_value'] = df['price'] * df['quantity']
        df['direction'] = np.where(df['side'] == 'buy', 1, -1)
        df['position_value'] = df['trade_value'] * df['direction']
        
        # Учитываем комиссии, если указано
        if include_fees and 'fee' in df.columns:
            df['position_value'] = df['position_value'] - df['fee']
        
        # Общий PnL
        total_pnl = df['position_value'].sum()
        
        # Статистика по сделкам
        if 'trade_id' in df.columns:
            # Если есть идентификаторы сделок, группируем по ним
            trades_grouped = df.groupby('trade_id')
            trade_pnl = trades_grouped['position_value'].sum()
            winning_trades = (trade_pnl > 0).sum()
            losing_trades = (trade_pnl < 0).sum()
            break_even_trades = (trade_pnl == 0).sum()
            win_rate = winning_trades / len(trade_pnl) if len(trade_pnl) > 0 else 0
        else:
            # Иначе просто считаем по направлению
            winning_trades = (df['position_value'] > 0).sum()
            losing_trades = (df['position_value'] < 0).sum()
            break_even_trades = (df['position_value'] == 0).sum()
            win_rate = winning_trades / len(df) if len(df) > 0 else 0
        
        # Результат
        result = {
            "total_pnl": float(total_pnl),
            "winning_trades": int(winning_trades),
            "losing_trades": int(losing_trades),
            "break_even_trades": int(break_even_trades),
            "win_rate": float(win_rate),
            "trade_count": len(df),
        }
        
        # Добавляем дополнительную статистику, если есть соответствующие данные
        if 'timestamp' in df.columns:
            df['timestamp'] = pd.to_datetime(df['timestamp'])
            result["first_trade_date"] = df['timestamp'].min().isoformat()
            result["last_trade_date"] = df['timestamp'].max().isoformat()
            result["trading_days"] = len(df['timestamp'].dt.date.unique())
        
        return result
    
    @staticmethod
    def analyze_trades(
        trades: List[Dict[str, Any]]
    ) -> Dict[str, Any]:
        """
        Расширенный анализ сделок.
        
        Args:
            trades: Список сделок, каждая сделка - словарь с данными
            
        Returns:
            Dict с результатами анализа
        """
        if not trades:
            return {"message": "No trades to analyze"}
        
        df = pd.DataFrame(trades)
        
        # Базовые расчеты PnL
        pnl_data = TradingAnalyzer.calculate_pnl(trades)
        
        # Дополнительные метрики
        result = {
            "pnl": pnl_data,
            "metrics": {},
            "symbols": {}
        }
        
        # Анализ по символам, если доступно
        if 'symbol' in df.columns:
            symbol_stats = {}
            for symbol, group in df.groupby('symbol'):
                symbol_pnl = TradingAnalyzer.calculate_pnl(group.to_dict('records'))
                symbol_stats[symbol] = symbol_pnl
            result["symbols"] = symbol_stats
        
        # Анализ временных паттернов, если доступны временные метки
        if 'timestamp' in df.columns:
            df['timestamp'] = pd.to_datetime(df['timestamp'])
            df['hour'] = df['timestamp'].dt.hour
            df['day_of_week'] = df['timestamp'].dt.dayofweek
            
            # Активность по часам
            hourly_activity = df.groupby('hour').size().to_dict()
            result["metrics"]["hourly_activity"] = hourly_activity
            
            # Активность по дням недели
            daily_activity = df.groupby('day_of_week').size().to_dict()
            result["metrics"]["daily_activity"] = daily_activity
        
        return result