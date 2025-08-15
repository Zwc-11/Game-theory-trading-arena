-- sql/020_views.sql
CREATE OR REPLACE VIEW market.latest_close AS
SELECT DISTINCT ON (symbol) symbol, ts, close
FROM market.ohlcv_1m
ORDER BY symbol, ts DESC;
