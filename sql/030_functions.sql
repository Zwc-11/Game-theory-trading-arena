-- sql/030_functions.sql
-- Utility SQL functions used by analytics & game-theory layers.

-- minute_return(sym, at_ts)
-- Returns (close_t - close_{t-1min}) / close_{t-1min}
-- Notes:
-- - We floor "at_ts" to the minute to match our 1-minute bars.
-- - Returns NULL if either bar is missing or if the previous close is zero.
-- - Marked STABLE (reads tables) — not IMMUTABLE.

CREATE OR REPLACE FUNCTION market.minute_return(sym TEXT, at_ts TIMESTAMPTZ)
RETURNS NUMERIC
LANGUAGE SQL
STABLE
AS $$
  WITH t AS (
    SELECT date_trunc('minute', at_ts) AS ts_m
  ),
  cur AS (
    SELECT close::NUMERIC AS c
    FROM market.ohlcv_1m
    WHERE symbol = sym
      AND ts = (SELECT ts_m FROM t)
  ),
  prev AS (
    SELECT close::NUMERIC AS c
    FROM market.ohlcv_1m
    WHERE symbol = sym
      AND ts = (SELECT ts_m FROM t) - INTERVAL '1 minute'
  )
  SELECT (cur.c - prev.c) / NULLIF(prev.c, 0)
  FROM cur, prev;
$$;
