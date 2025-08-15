-- sql/010_tables.sql
-- Core tables: market data + arena scaffolding (idempotent)

-- ===== OHLCV 1-minute (Deepcoin) =====
CREATE TABLE IF NOT EXISTS market.ohlcv_1m (
  ts          TIMESTAMPTZ NOT NULL,
  symbol      TEXT NOT NULL,
  open        NUMERIC(18,8) NOT NULL,
  high        NUMERIC(18,8) NOT NULL,
  low         NUMERIC(18,8) NOT NULL,
  close       NUMERIC(18,8) NOT NULL,
  volume      NUMERIC(18,8) NOT NULL,
  buy_vol     NUMERIC(18,8),
  sell_vol    NUMERIC(18,8),
  src         TEXT NOT NULL DEFAULT 'deepcoin',
  inserted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (ts, symbol)
);
SELECT create_hypertable('market.ohlcv_1m','ts', if_not_exists => TRUE);

-- ===== Funding rates =====
CREATE TABLE IF NOT EXISTS market.funding_rates (
  ts          TIMESTAMPTZ NOT NULL,
  symbol      TEXT NOT NULL,
  rate        NUMERIC(18,10) NOT NULL,
  period_s    INT NOT NULL,
  src         TEXT NOT NULL DEFAULT 'deepcoin',
  inserted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (ts, symbol)
);
SELECT create_hypertable('market.funding_rates','ts', if_not_exists => TRUE);

-- ===== Arena scaffolding (agents, payoffs, equilibria, signals) =====
CREATE TABLE IF NOT EXISTS arena.agents (
  agent_id       SERIAL PRIMARY KEY,
  agent_type     TEXT NOT NULL,
  params         JSONB NOT NULL DEFAULT '{}'::jsonb,
  wealth         NUMERIC(18,8) NOT NULL DEFAULT 0,
  risk_aversion  NUMERIC(18,8) NOT NULL DEFAULT 0.5
);

CREATE TABLE IF NOT EXISTS arena.payoffs (
  ts       TIMESTAMPTZ NOT NULL,
  symbol   TEXT NOT NULL,
  A_long   NUMERIC(18,8) NOT NULL,
  A_short  NUMERIC(18,8) NOT NULL,
  A_hold   NUMERIC(18,8) NOT NULL,
  B_long   NUMERIC(18,8) NOT NULL,
  B_short  NUMERIC(18,8) NOT NULL,
  B_hold   NUMERIC(18,8) NOT NULL,
  PRIMARY KEY (ts, symbol)
);

CREATE TABLE IF NOT EXISTS arena.equilibria (
  ts        TIMESTAMPTZ NOT NULL,
  symbol    TEXT NOT NULL,
  p_long    NUMERIC(18,8) NOT NULL,
  p_short   NUMERIC(18,8) NOT NULL,
  p_hold    NUMERIC(18,8) NOT NULL,
  converged BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY (ts, symbol)
);

CREATE TABLE IF NOT EXISTS arena.signals (
  ts         TIMESTAMPTZ NOT NULL,
  symbol     TEXT NOT NULL,
  signal     TEXT NOT NULL CHECK (signal IN ('LONG','SHORT','HOLD')),
  confidence NUMERIC(18,8) NOT NULL DEFAULT 0.5,
  reason     TEXT,
  PRIMARY KEY (ts, symbol)
);

-- ===== Indexing strategy =====
-- BRIN for fast time-range scans on big tables
CREATE INDEX IF NOT EXISTS ohlcv_1m_brin_ts  ON market.ohlcv_1m USING BRIN (ts);
CREATE INDEX IF NOT EXISTS funding_brin_ts   ON market.funding_rates USING BRIN (ts);
-- Access patterns: latest-per-symbol & rolling windows
CREATE INDEX IF NOT EXISTS ohlcv_1m_symbol_ts ON market.ohlcv_1m (symbol, ts DESC);
