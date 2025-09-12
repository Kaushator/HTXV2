-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create additional indexes for performance
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'crypto_price_data') THEN
        CREATE INDEX IF NOT EXISTS idx_crypto_prices_symbol_timestamp 
        ON crypto_price_data(symbol, timestamp DESC);
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'trading_signals') THEN
        CREATE INDEX IF NOT EXISTS idx_trading_signals_symbol_created 
        ON trading_signals(symbol, created_at DESC);
    END IF;
END $$;

-- Create function for updating updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at with table existence checks
DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'users') THEN
        DROP TRIGGER IF EXISTS update_users_updated_at ON users;
        CREATE TRIGGER update_users_updated_at
            BEFORE UPDATE ON users
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'portfolios') THEN
        DROP TRIGGER IF EXISTS update_portfolios_updated_at ON portfolios;
        CREATE TRIGGER update_portfolios_updated_at
            BEFORE UPDATE ON portfolios
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;

DO $$
BEGIN
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'positions') THEN
        DROP TRIGGER IF EXISTS update_positions_updated_at ON positions;
        CREATE TRIGGER update_positions_updated_at
            BEFORE UPDATE ON positions
            FOR EACH ROW
            EXECUTE FUNCTION update_updated_at_column();
    END IF;
END $$;