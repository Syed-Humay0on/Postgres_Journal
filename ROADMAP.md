# PostgreSQL 30-Day Mastery Roadmap

## Week 1: DDL & DML
- **Day 1**: Databases & Schemas (`\l`, `\c`, `\dn`, `CREATE SCHEMA`)
- **Day 2**: Tables, Data Types & Indexing (GIN, B-tree, CHECK constraints) ✅
- **Day 3**: CRUD Mastery (`INSERT RETURNING`, `UPDATE ... FROM`, `DELETE CASCADE`)
- **Day 4**: Advanced Constraints (`ALTER TABLE`, regex validation, `ADD CONSTRAINT`)
- **Day 5**: CSV Import/Export (`\COPY` via `docker exec`)

## Week 2: Querying & Joins
- **Day 6**: SELECT Deep Dive (`DISTINCT`, `LIMIT/OFFSET`, `FILTER`, window functions)
- **Day 7**: JOINs (`INNER`, `LEFT`, `RIGHT`, self-joins)
- **Day 8**: Subqueries & CTEs (`WITH`, `LATERAL`)
- **Day 9**: Set Operations (`UNION`, `INTERSECT`, `EXCEPT`)
- **Day 10**: Window Functions (`ROW_NUMBER()`, `RANK()`, `LAG()`, `LEAD()`)

## Week 3: Performance & Transactions
- **Day 11**: Indexing Strategy (`EXPLAIN ANALYZE`, composite indexes, query tuning)
- **Day 12**: Advanced Indexes (Partial, Unique, GIN for JSONB/arrays)
- **Day 13**: ACID Transactions (`BEGIN`, `COMMIT`, `ROLLBACK`)
- **Day 14**: Isolation Levels (`READ COMMITTED`, `REPEATABLE READ`, `SERIALIZABLE`)
- **Day 15**: Locking & Deadlocks (`FOR UPDATE`, `pg_locks`, deadlock prevention)

## Week 4: Production-Ready Skills
- **Day 16**: Backup & Restore (`pg_dump`, `pg_restore`, `pg_basebackup`)
- **Day 17**: Security & RLS (`CREATE ROLE`, `GRANT`, Row-Level Security)
- **Day 18**: Connection Pooling (PgBouncer, pgpool-II)
- **Day 19**: Monitoring (`pg_stat_activity`, slow query log, index bloat)
- **Day 20**: Elixir Ecto Integration (migrations, schemas, associations)

## Week 5: Advanced Features
- **Day 21**: Full-Text Search (`tsvector`, `to_tsquery`, `ts_headline`)
- **Day 22**: JSONB vs MongoDB (`@&gt;`, `?`, `?|`, `?&`, GIN indexes)
- **Day 23**: Table Partitioning (`PARTITION BY RANGE`, `FOR VALUES FROM`)
- **Day 24**: Streaming Replication (primary/replica, `wal_level`, `hot_standby`)
- **Day 25**: Materialized Views (`REFRESH MATERIALIZED VIEW CONCURRENTLY`)

## Week 6: Programmability
- **Day 26**: PL/pgSQL Functions (`CREATE FUNCTION`, `RETURNS TABLE`)
- **Day 27**: Triggers & Auditing (`CREATE TRIGGER`, `row_to_json(NEW/OLD)`)
- **Day 28**: TimescaleDB (hypertables, time-series optimization)
- **Day 29**: Zero-Downtime Migrations (backfill strategies, `CREATE INDEX CONCURRENTLY`)
- **Day 30**: Performance Tuning (`work_mem`, `shared_buffers`, cache hit ratio)

---

## Quick Commands
```bash
# Connect via pgcli
pgcli -h localhost -p 5433 -U admin -d mydatabase

# Docker logs
docker compose logs -f postgres

# Backup
docker exec -t database-postgres-1 pg_dump -U admin -d mydatabase -Fc &gt; backup.dump
