import re
from decimal import Decimal

from fastapi import HTTPException, status

_SYMBOL_RE = re.compile(r"^[A-Za-z0-9]{2,20}$")
_ALLOWED_TIMEFRAMES = {"1m", "5m", "15m", "1h", "4h", "1d", "1w"}


def validate_trading_symbol(symbol: str) -> str:
    if not symbol:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="symbol is required",
        )
    if not _SYMBOL_RE.match(symbol):
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="invalid symbol format",
        )
    return symbol.upper()


def validate_timeframe(timeframe: str) -> str:
    if timeframe not in _ALLOWED_TIMEFRAMES:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="invalid timeframe"
        )
    return timeframe


def validate_order_quantity(quantity: Decimal) -> Decimal:
    try:
        q = Decimal(quantity)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY, detail="invalid quantity"
        )
    if q <= 0:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail="quantity must be positive",
        )
    return q
