CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE IF NOT EXISTS orders (
    order_id UUID PRIMARY KEY,
    customer_id TEXT NOT NULL,
    product_id TEXT NOT NULL,
    total_amount NUMERIC(12,2) NOT NULL,
    coupon_code TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS outbox_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_type TEXT NOT NULL,
    aggregate_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    payload JSONB NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_outbox_events_aggregate_id ON outbox_events (aggregate_id);
CREATE INDEX IF NOT EXISTS idx_outbox_events_event_type ON outbox_events (event_type);

CREATE TABLE IF NOT EXISTS orders_status_readmodel (
    order_id TEXT PRIMARY KEY,
    status TEXT NOT NULL,
    payment_status TEXT,
    inventory_status TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS raw_event_analytics (
    event_id BIGSERIAL PRIMARY KEY,
    topic TEXT NOT NULL,
    partition_id INT NOT NULL,
    event_key TEXT,
    payload JSONB,
    ingested_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DROP PUBLICATION IF EXISTS dbz_publication;
CREATE PUBLICATION dbz_publication FOR TABLE outbox_events;
