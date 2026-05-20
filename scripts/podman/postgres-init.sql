-- PostgreSQL initialization script for WideWorldImporters migration target
-- Mounted to /docker-entrypoint-initdb.d/01-init.sql in the postgres container

-- Create extensions (postgis is pre-installed in postgis/postgis image)
CREATE EXTENSION IF NOT EXISTS ltree;
CREATE EXTENSION IF NOT EXISTS postgis;

-- Create application schemas matching WideWorldImporters structure
CREATE SCHEMA IF NOT EXISTS warehouse;
CREATE SCHEMA IF NOT EXISTS sales;
CREATE SCHEMA IF NOT EXISTS purchasing;
CREATE SCHEMA IF NOT EXISTS application;
CREATE SCHEMA IF NOT EXISTS integration;
CREATE SCHEMA IF NOT EXISTS sequences;
CREATE SCHEMA IF NOT EXISTS website;

-- Grant schema usage to the postgres (already the DB owner via POSTGRES_USER)
GRANT ALL ON SCHEMA warehouse TO postgres;
GRANT ALL ON SCHEMA sales TO postgres;
GRANT ALL ON SCHEMA purchasing TO postgres;
GRANT ALL ON SCHEMA application TO postgres;
GRANT ALL ON SCHEMA integration TO postgres;
GRANT ALL ON SCHEMA sequences TO postgres;
GRANT ALL ON SCHEMA website TO postgres;

-- Lock down public schema (sec-006)
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
