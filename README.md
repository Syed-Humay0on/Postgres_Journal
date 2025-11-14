# PostgreSQL 30-Day Mastery Journey 🐘

Tracking my daily PostgreSQL learning with Docker + pgcli + Ecto.

## Progress
- ✅ Day 1: Docker Setup (postgres + pgadmin)
- ✅ Day 2: Production-Ready Blog Schema (10,104 rows)
- ✅ Day 3: Complete CRUD Mastery (200+ lines, all patterns)
- ✅ Day 4: Advanced Constraints (CHECK, UNIQUE, Partial Indexes, FOREIGN KEY Cascades, EXCLUSION)

## Daily Logs
- `day01-setup.sql` - Initial database creation
- `day02-tables.sql` - Complete blog schema with GIN indexes + 10K test rows
- `day03-crud.sql` - Comprehensive CRUD operations (INSERT, SELECT, UPDATE, DELETE, Upserts, Transactions)
- `day04.sql` - Advanced Constraints:
  - CHECK constraints (age validation, regex patterns)
  - UNIQUE & Partial Indexes (case-insensitive emails, one active key per user)
  - FOREIGN KEY Cascades (ON DELETE CASCADE/SET NULL/RESTRICT)
  - EXCLUSION Constraints (meeting room double-booking prevention)

## Quick Commands
```bash
# Connect via pgcli
pgcli -h localhost -p 5433 -U admin -d mydatabase

# Docker logs
docker compose logs -f postgres

# Backup
docker exec -t database-postgres-1 pg_dump -U admin -d mydatabase -Fc &gt; backup.dump

# View constraints
\d blogs.users
SELECT conname, contype FROM pg_constraint WHERE connamespace = 'blogs'::regnamespace;
