-- sql/000_init.sql
-- Idempotent bootstrap: extensions & schemas

-- TimescaleDB (ok to run multiple times)
CREATE EXTENSION IF NOT EXISTS timescaledb;

-- Project schemas
CREATE SCHEMA IF NOT EXISTS market;
CREATE SCHEMA IF NOT EXISTS arena;
CREATE SCHEMA IF NOT EXISTS util;
