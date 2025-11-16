select * from blogs.users;
-- +----+---------------+--------------------------+--------------------------------------------------------------+-------------+-------------------------------+--------+
-- | id | username      | email                    | password_hash                                                | is_verified | created_at                    | age    |
-- |----+---------------+--------------------------+--------------------------------------------------------------+-------------+-------------------------------+--------|
-- | 2  | bob           | bob@example.com          | $2b$12$KIXpS8zKzJxTpjWQFl7y1uI0pJHqDvpN6oNxJNp9QHMG5DGnH2kla | False       | 2025-11-10 20:04:14.296178+05 | <null> |
-- | 3  | charlie       | charlie@test.org         | $2b$12$QMz8sXzLQ3pLr8xVnHzJLu5j7v9w0Rq9pTlM8nYyX5vKLpq8kM0d  | False       | 2025-11-10 20:04:14.296178+05 | <null> |
-- | 5  | valid3        | test_123@test-domain.org | hash                                                         | False       | 2025-11-10 21:39:00.844275+05 | <null> |
-- | 18 | frank         | frank@batch.com          | hash1                                                        | False       | 2025-11-11 17:38:58.208208+05 | <null> |
-- | 20 | henry         | henry@batch.com          | hash3                                                        | False       | 2025-11-11 17:38:58.208208+05 | <null> |
-- | 21 | ivy           | ivy@batch.com            | hash4                                                        | False       | 2025-11-11 17:38:58.208208+05 | <null> |
-- | 22 | jack          | jack@batch.com           | hash5                                                        | False       | 2025-11-11 17:38:58.208208+05 | <null> |
-- | 28 | xander2025    | xander@a.com             | hashed                                                       | False       | 2025-11-12 20:42:01.134994+05 | <null> |
-- | 36 | xander2024    | xander@cba.com           | hashed                                                       | False       | 2025-11-12 21:03:14.218078+05 | <null> |
-- | 42 | api_test_user | apt@test.com             | hashed                                                       | False       | 2025-11-13 02:28:05.712722+05 | <null> |
-- +----+---------------+--------------------------+--------------------------------------------------------------+-------------+-------------------------------+--------+

\copy blogs.users(username, email, password_hash, age) from '/home/proto/Documents/Database/Postgres_Journal/user_bulk.csv' delimiter ',' csv header;

select COUNT(*) from blogs.users where username in ('david','eve','franklin');
-- +-------+
-- | count |
-- |-------|
-- | 2     |
-- +-------+
select id, username, email, age from blogs.users where username in ('david', 'eve2025', 'franklin', 'grace', 'henry_123') order by id;
-- +----+-----------+--------------------+-----+
-- | id | username  | email              | age |
-- |----+-----------+--------------------+-----|
-- | 50 | david     | david@example.com  | 28  |
-- | 51 | eve2025   | eve@test.org       | 35  |
-- | 52 | franklin  | frank@punisher.com | 42  |
-- | 53 | grace     | g@test.com         | 19  |
-- | 54 | henry_123 | henry@example.com  | 31  |
-- +----+-----------+--------------------+-----+
-- CHECK CONSTRAINTS
\copy blogs.users(username, email, password_hash, age) from '/home/proto/Documents/Database/Postgres_Journal/user_bulk.csv' delimiter ',' csv header;
-- new row for relation "users" violates check constraint "users_age_check"
-- DETAIL:  Failing row contains (58, grace, g@test.com, hash_grace, f, 2025-11-15 21:09:04.207853+05, 5).
-- CONTEXT:  COPY users, line 5: "grace,g@test.com,hash_grace,5"

\copy blogs.users(username, email, password_hash, age) from '/home/proto/Documents/Database/Postgres_Journal/user_bulk.csv' delimiter ',' csv header;
-- duplicate key value violates unique constraint "users_username_key"
-- DETAIL:  Key (username)=(david) already exists.
-- CONTEXT:  COPY users, line 2

\copy blogs.users(username, email, password_hash, age) from '/home/proto/Documents/Database/Postgres_Journal/user_bulk.csv' delimiter ',' csv header;
-- new row for relation "users" violates check constraint "users_email_check"
-- DETAIL:  Failing row contains (64, Imran,  bob@example.com,  hashed, f, 2025-11-15 21:10:59.785402+05, 23).
-- CONTEXT:  COPY users, line 2: "Imran, bob@example.com, hashed, 23"
select u.id, u.username, COUNT(p.id) as post_count from blogs.users u left join blogs.posts p on u.id = p.user_id
 where u.username = 'david' group by u.id, u.username;
-- +----+----------+------------+
-- | id | username | post_count |
-- |----+----------+------------|
-- | 50 | david    | 0          |
-- +----+----------+------------+

-- +----------------------+------------+
-- | tablename            | tableowner |
-- |----------------------+------------|
-- | api_keys             | admin      |
-- | comments             | admin      |
-- | deleted_posts_backup | admin      |
-- | meeting_rooms        | admin      |
-- | nested_comments      | admin      |
-- | posts                | admin      |
-- | posts_restrict       | admin      |
-- | products             | admin      |
-- | room_bookings        | admin      |
-- | users                | admin      |
-- +----------------------+------------+
\copy blogs.users(username, email, password_hash, age) to '/home/proto/Documents/Database/Postgres_Journal/user_bulk.csv' delimiter ',' csv header;
 \copy (select id, username, email, age from blogs.users where age > 25) to '/home/proto/Documents/Database/Postgres_Journal/user_bulk.csv' delimiter ',' csv header;

-- 🎯 Section 5.1 Summary: What You Just Did
-- ✅ Created a CSV file on your host machine
-- ✅ Used \COPY to bulk import 5 users in one command
-- ✅ Verified CHECK constraints caught invalid data during import
-- ✅ Verified UNIQUE indexes prevented duplicates during import
-- ✅ Audited your schema to see what's real vs test data
-- ✅ Exported data back to CSV for backups or sharing

-- 📌 SECTION 5.2: COPY vs \COPY (Server vs Client)
-- 🎯 The Core Difference
--
-- | Command     | Runs On               | Permissions        | File Location               | When to Use                                  |
-- | ----------- | --------------------- | ------------------ | --------------------------- | -------------------------------------------- |
-- | **`\COPY`** | **pgcli client**      | Your user account  | Your laptop/host            | **Most common** - safer, no superuser needed |
-- | **`COPY`**  | **PostgreSQL server** | Postgres superuser | **Inside Docker container** | Server has direct file access                |
--
 
-- 🎯 Section 5.4: Real-World Dataset (10,000 Rows)
-- Let's import a real public dataset to see performance.
-- Step 1: Download Sample Data
 
-- Duplicate rows to make ~100 rows for testing:
-- # Quick bash trick (on host)
-- for i in {1..5}; do cat products_catalog.csv >> products_big.csv; done
