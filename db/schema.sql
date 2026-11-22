-- Reference schema (PostgreSQL / Azure SQL friendly in spirit).
-- The sample APIs do not use it yet: they hold data in memory.
-- It is here so you can talk about migrations, backups, private access and failover.

CREATE TABLE events (
    event_id      VARCHAR(20)  PRIMARY KEY,
    event_type    VARCHAR(20)  NOT NULL,          -- Trading Event or Pulse
    starts_utc    TIMESTAMP    NOT NULL,
    status        VARCHAR(20)  NOT NULL
);

CREATE TABLE bidders (
    bidder_id     VARCHAR(40)  PRIMARY KEY,
    display_name  VARCHAR(120) NOT NULL
);

CREATE TABLE bids (
    bid_id           UUID         PRIMARY KEY,
    event_id         VARCHAR(20)  NOT NULL REFERENCES events(event_id),
    bidder_id        VARCHAR(40)  NOT NULL REFERENCES bidders(bidder_id),
    product_code     VARCHAR(8)   NOT NULL,
    round_no         INT          NOT NULL,
    quantity_mt      NUMERIC(12,2) NOT NULL CHECK (quantity_mt > 0),
    idempotency_key  VARCHAR(80)  NOT NULL,
    accepted_utc     TIMESTAMP    NOT NULL,
    CONSTRAINT uq_bid_idempotency UNIQUE (idempotency_key)
);

CREATE INDEX ix_bids_event_round ON bids (event_id, round_no);
CREATE INDEX ix_bids_bidder      ON bids (bidder_id, event_id);

-- Append-only audit trail. Nothing here is ever updated or deleted.
CREATE TABLE audit_log (
    audit_id      BIGINT       PRIMARY KEY,
    occurred_utc  TIMESTAMP    NOT NULL,
    actor         VARCHAR(120) NOT NULL,
    action        VARCHAR(60)  NOT NULL,
    detail        TEXT
);
