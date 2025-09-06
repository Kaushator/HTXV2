-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create function for updating updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Note: Tables will be created by SQLAlchemy migrations
-- Additional indexes and triggers will be added after table creation