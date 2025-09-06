from sqlalchemy import Column, Integer, String, Numeric, DateTime, JSON, Text, Index, Boolean
from sqlalchemy.sql import func
from app.db.session import Base


class CryptoPriceData(Base):
    """Cryptocurrency price data model"""
    __tablename__ = "crypto_price_data"
    
    id = Column(Integer, primary_key=True, index=True)
    timestamp = Column(DateTime(timezone=True), nullable=False, index=True)
    symbol = Column(String(20), nullable=False, index=True)
    exchange = Column(String(50), nullable=False, index=True)
    
    # Price data
    price = Column(Numeric(20, 8), nullable=False)
    volume_24h = Column(Numeric(20, 8), nullable=True)
    market_cap = Column(Numeric(20, 2), nullable=True)
    price_change_24h = Column(Numeric(10, 4), nullable=True)
    high_24h = Column(Numeric(20, 8), nullable=True)
    low_24h = Column(Numeric(20, 8), nullable=True)
    
    # Supply data
    circulating_supply = Column(Numeric(20, 2), nullable=True)
    total_supply = Column(Numeric(20, 2), nullable=True)
    
    # Metadata
    metadata = Column(JSON, nullable=True)
    data_source = Column(String(50), nullable=False)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Create composite indexes for efficient querying
    __table_args__ = (
        Index('idx_symbol_timestamp', 'symbol', 'timestamp'),
        Index('idx_exchange_timestamp', 'exchange', 'timestamp'),
        Index('idx_symbol_exchange_timestamp', 'symbol', 'exchange', 'timestamp'),
    )
    
    def __repr__(self):
        return f"<CryptoPriceData(symbol='{self.symbol}', price={self.price}, timestamp='{self.timestamp}')>"


class Portfolio(Base):
    """User portfolio model"""
    __tablename__ = "portfolios"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, nullable=False, index=True)
    name = Column(String(100), nullable=False)
    description = Column(Text, nullable=True)
    is_active = Column(Boolean, default=True)
    
    # Portfolio settings
    base_currency = Column(String(10), default="USD")
    risk_tolerance = Column(String(20), default="medium")  # low, medium, high
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    def __repr__(self):
        return f"<Portfolio(id={self.id}, user_id={self.user_id}, name='{self.name}')>"


class Position(Base):
    """Portfolio position model"""
    __tablename__ = "positions"
    
    id = Column(Integer, primary_key=True, index=True)
    portfolio_id = Column(Integer, nullable=False, index=True)
    symbol = Column(String(20), nullable=False, index=True)
    
    # Position data
    quantity = Column(Numeric(20, 8), nullable=False)
    average_price = Column(Numeric(20, 8), nullable=False)
    current_price = Column(Numeric(20, 8), nullable=True)
    
    # P&L data
    unrealized_pnl = Column(Numeric(20, 8), nullable=True)
    realized_pnl = Column(Numeric(20, 8), default=0)
    
    # Position type
    position_type = Column(String(10), default="long")  # long, short
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    def __repr__(self):
        return f"<Position(portfolio_id={self.portfolio_id}, symbol='{self.symbol}', quantity={self.quantity})>"


class TradingSignal(Base):
    """Trading signal model"""
    __tablename__ = "trading_signals"
    
    id = Column(Integer, primary_key=True, index=True)
    symbol = Column(String(20), nullable=False, index=True)
    signal_type = Column(String(10), nullable=False)  # buy, sell, hold
    confidence = Column(Numeric(5, 4), nullable=False)  # 0.0 to 1.0
    
    # Signal data
    target_price = Column(Numeric(20, 8), nullable=True)
    stop_loss = Column(Numeric(20, 8), nullable=True)
    timeframe = Column(String(10), nullable=False)  # 1m, 5m, 1h, 1d, etc.
    
    # Source information
    source = Column(String(50), nullable=False)  # ai_model, technical_analysis, etc.
    model_version = Column(String(50), nullable=True)
    
    # Metadata
    features = Column(JSON, nullable=True)
    metadata = Column(JSON, nullable=True)
    
    # Status
    is_active = Column(Boolean, default=True)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    expires_at = Column(DateTime(timezone=True), nullable=True)
    
    def __repr__(self):
        return f"<TradingSignal(symbol='{self.symbol}', signal_type='{self.signal_type}', confidence={self.confidence})>"