-- ==========================================
-- DAY 5: CSV Import/Export Mastery
-- PostgreSQL 30-Day Mastery Journey
-- ==========================================
--
-- What this file does:
-- 1. Imports users from CSV file into blogs.users
-- 2. Exports users to CSV file for backup/sharing
-- 3. Shows how Day 4 constraints protect imports
--
-- HOW TO RUN:
-- 1. Create the CSV files (see comments below)
-- 2. In pgcli: \i /path/to/day05.sql
-- 3. Check output with separate queries
-- ==========================================


-- ==========================================
-- SECTION 5.1: CSV Import
-- ==========================================

-- PREPARE: Create this CSV file on your host machine:
-- File: /home/proto/Documents/Database/Postgres_Journal/day05_import.csv
-- Content:
--   id,username,email,password_hash,age
--   100,test_user_100,test100@example.com,hash_100,30
--   101,test_user_101,test101@example.com,hash_101,25
--   102,test_user_102,test102@example.com,hash_102,40
--   103,test_user_103,test103@example.com,hash_103,35
--   104,test_user_104,test104@example.com,hash_104,28
--   105,test_user_105,test105@example.com,hash_105,33

-- Import the CSV (bulk insert)
\copy blogs.users(id, username, email, password_hash, age) 
FROM '/home/proto/Documents/Database/Postgres_Journal/day05_import.csv' 
DELIMITER ',' CSV HEADER;


-- ==========================================
-- SECTION 5.2: Test Day 4 Constraints
-- ==========================================

-- This will FAIL (CHECK constraint blocks age=5)
-- PREPARE: Create day05_invalid_age.csv with: 200,bad_user,bad@example.com,hash,5
\copy blogs.users(id, username, email, password_hash, age) FROM '/home/proto/Documents/Database/Postgres_Journal/day05_invalid_age.csv' DELIMITER ',' CSV HEADER;

-- This will FAIL (UNIQUE constraint blocks duplicate username)
-- PREPARE: Create day05_duplicate.csv with: 201,test_user_100,duplicate@example.com,hash,30
\copy blogs.users(id, username, email, password_hash, age)  FROM '/home/proto/Documents/Database/Postgres_Journal/day05_duplicate.csv' DELIMITER ',' CSV HEADER;


-- ==========================================
-- SECTION 5.3: CSV Export
-- ==========================================

-- Export ALL users
\copy blogs.users TO '/home/proto/Documents/Database/Postgres_Journal/day05_export_all.csv' DELIMITER ',' CSV HEADER;

-- Export filtered data (age > 25)
-- IMPORTANT: Wrap SELECT in parentheses!
\copy (SELECT id, username, email, age FROM blogs.users WHERE age > 25) TO '/home/proto/Documents/Database/Postgres_Journal/day05_export_active.csv' DELIMITER ',' CSV HEADER;


-- ==========================================
-- SECTION 5.4: Cleanup
-- ==========================================

-- Clean up test users (start fresh next time)
DELETE FROM blogs.users WHERE id BETWEEN 100 AND 105;

-- ==========================================
-- DAY 5 COMPLETE!
-- ==========================================
