# PostgreSQL 30-Day Mastery Journey 🐘

Tracking my daily PostgreSQL learning with Docker + pgcli + Ecto.

## Progress
- ✅ Day 1: Docker Setup (postgres + pgadmin)
- ✅ Day 2: Production-Ready Blog Schema (10,104 rows)
- ✅ Day 3: Complete CRUD Mastery (200+ lines, all patterns)

## Daily Logs
- `day01-setup.sql` - Initial database creation
- `day02-tables.sql` - Complete blog schema with GIN indexes + 10K test rows
- `day03-crud.sql` - Comprehensive CRUD operations (INSERT, SELECT, UPDATE, DELETE, Upserts, Transactions)

## Usage
```bash
docker compose up -d
pgcli -h localhost -p 5433 -U admin -d mydatabase
