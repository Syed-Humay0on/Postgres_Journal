-- ==========================================
-- DAY 4: Advanced Constraints Mastery
-- PostgreSQL 30-Day Mastery Journey
-- Generated: 2025-11-14
-- ==========================================
--
-- In this file, you'll practice 4 powerful constraint types:
-- 1. CHECK Constraints (Data Validation)
-- 2. UNIQUE & Partial Indexes (No Duplicates)
-- 3. FOREIGN KEY Cascades (Referential Integrity)
-- 4. EXCLUSION Constraints (No Overlaps)
--
-- How to practice: Run each section one at a time in pgcli
--                  Use \d blogs.table_name to verify each step
-- ==========================================


-- ==========================================
-- SECTION 1: CHECK CONSTRAINTS DEEP DIVE
-- What: Validate data before it enters the table
-- Why: Keep bad data out (negative ages, invalid emails)
-- ==========================================

-- Add age column with CHECK constraint (valid ages: 13-120)
ALTER TABLE blogs.users 
ADD COLUMN age INT CHECK (age >= 13 AND age <= 120);

-- Test valid age (should succeed)
UPDATE blogs.users SET age = 25 WHERE username = 'bob';

-- Test invalid age (should FAIL - too young)
UPDATE blogs.users SET age = 12 WHERE username = 'bob';
-- ERROR: age violates check constraint "users_age_check"


-- Add CHECK constraint on username format (3-20 chars, letters/numbers/underscores)
ALTER TABLE blogs.users 
ADD CONSTRAINT users_username_format 
CHECK (username ~* '^[a-z0-9_]{3,20}$');

-- Test valid username (should succeed)
UPDATE blogs.users SET username = 'alice_2025' WHERE id = 2;

-- Test invalid username (should FAIL - too short)
UPDATE blogs.users SET username = 'ab' WHERE id = 2;
-- ERROR: username violates check constraint "users_username_format"


-- Add CHECK constraint on product prices (must be positive)
CREATE TABLE blogs.products (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    price DECIMAL(10,2) NOT NULL,
    CHECK (price > 0)  -- Inline CHECK
);

-- Test invalid price (should FAIL)
INSERT INTO blogs.products (name, price) VALUES ('Bad Product', -5);
-- ERROR: price violates check constraint "products_price_check"


-- View all CHECK constraints in your schema
SELECT 
    conname AS constraint_name,
    conrelid::regclass AS table_name,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE connamespace = 'blogs'::regnamespace
  AND contype = 'c'  -- 'c' = CHECK constraint
ORDER BY conrelid, conname;


-- ==========================================
-- SECTION 2: UNIQUE CONSTRAINTS & PARTIAL INDEXES
-- What: Prevent duplicates (emails, usernames)
-- Why: Unique indexes = faster queries + data integrity
-- ==========================================

-- Create case-insensitive UNIQUE index on email
-- Step 1: Drop old case-sensitive constraint (if exists)
ALTER TABLE blogs.users DROP CONSTRAINT IF EXISTS users_email_key;

-- Step 2: Create case-insensitive UNIQUE index
CREATE UNIQUE INDEX users_email_unique_lower 
ON blogs.users (LOWER(email));

-- Test case-insensitive uniqueness (FAIL - bob@example.com exists)
INSERT INTO blogs.users (username, email, password_hash) VALUES
    ('newbob', 'BOB@EXAMPLE.COM', 'hash');
-- ERROR: duplicate key value violates unique constraint "users_email_unique_lower"


-- Create partial UNIQUE index (one active API key per user)
CREATE TABLE blogs.api_keys (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES blogs.users(id),
    key_hash VARCHAR(64) NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE
);

-- This index only enforces uniqueness on ACTIVE keys
CREATE UNIQUE INDEX one_active_key_per_user 
ON blogs.api_keys (user_id) 
WHERE is_active = TRUE;

-- Test: Multiple inactive keys allowed (SUCCESS)
INSERT INTO blogs.api_keys (user_id, key_hash, is_active) VALUES
    (2, 'inactive_1', FALSE),
    (2, 'inactive_2', FALSE);

-- Test: Only ONE active key allowed (FAIL on second)
INSERT INTO blogs.api_keys (user_id, key_hash, is_active) VALUES
    (2, 'active_1', TRUE);

INSERT INTO blogs.api_keys (user_id, key_hash, is_active) VALUES
    (2, 'active_2', TRUE);
-- ERROR: duplicate key value violates unique constraint "one_active_key_per_user"


-- View all UNIQUE indexes in your schema
SELECT 
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'blogs'
  AND indexdef LIKE '%UNIQUE%'
ORDER BY tablename, indexname;


-- ==========================================
-- SECTION 3: FOREIGN KEY CASCADE BEHAVIORS
-- What: Control what happens when parent data is deleted
-- Why: Prevent orphans or auto-cleanup related data
-- ==========================================

-- Check current foreign keys
SELECT 
    conname AS constraint_name,
    conrelid::regclass AS table_name,
    confrelid::regclass AS referenced_table,
    pg_get_constraintdef(oid) AS definition
FROM pg_constraint
WHERE connamespace = 'blogs'::regnamespace
  AND contype = 'f'  -- 'f' = FOREIGN KEY
ORDER BY conrelid;


-- Create table with ON DELETE CASCADE (auto-delete children)
CREATE TABLE blogs.user_profiles (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES blogs.users(id) ON DELETE CASCADE,
    bio TEXT,
    website VARCHAR(200)
);

-- Insert test data
INSERT INTO blogs.users (username, email, password_hash) VALUES
    ('cascade_user', 'cascade@test.com', 'hash') RETURNING id;
-- Assume returned id = 999

INSERT INTO blogs.user_profiles (user_id, bio) VALUES
    (999, 'This will be deleted automatically');

-- Delete the user - CASCADE deletes profile automatically!
DELETE FROM blogs.users WHERE id = 999;

-- Verify profile is gone
SELECT * FROM blogs.user_profiles WHERE user_id = 999;
-- Returns: 0 rows (CASCADE worked!)


-- Create table with ON DELETE SET NULL (keep child, nullify FK)
CREATE TABLE blogs.posts_with_category (
    id SERIAL PRIMARY KEY,
    user_id INT NOT NULL REFERENCES blogs.users(id),
    category_id INT REFERENCES blogs.categories(id) ON DELETE SET NULL,
    title VARCHAR(200) NOT NULL
);

-- Insert category and post
INSERT INTO blogs.categories (name) VALUES ('Tech') RETURNING id;
-- Assume id = 1

INSERT INTO blogs.posts_with_category (user_id, category_id, title) VALUES
    (2, 1, 'Tech Post');

-- Delete category - post survives, category_id becomes NULL
DELETE FROM blogs.categories WHERE id = 1;

-- Check post (category_id is NULL)
SELECT id, title, category_id FROM blogs.posts_with_category 
WHERE title = 'Tech Post';
-- Returns: category_id = NULL


-- Create self-referencing table (comments that reply to comments)
CREATE TABLE blogs.nested_comments (
    id SERIAL PRIMARY KEY,
    parent_comment_id INT REFERENCES blogs.nested_comments(id) ON DELETE CASCADE,
    user_id INT NOT NULL REFERENCES blogs.users(id),
    content TEXT
);

-- Build a comment thread
INSERT INTO blogs.nested_comments (user_id, content) VALUES (2, 'Root comment') RETURNING id;
-- Result: id = 1

INSERT INTO blogs.nested_comments (user_id, parent_comment_id, content) VALUES (2, 1, 'Reply to root') RETURNING id;
-- Result: id = 2

INSERT INTO blogs.nested_comments (user_id, parent_comment_id, content) VALUES (3, 2, 'Reply to reply');

-- Delete root comment - CASCADE deletes ALL children recursively!
DELETE FROM blogs.nested_comments WHERE id = 1;

-- Verify entire thread is gone
SELECT * FROM blogs.nested_comments;
-- Returns: 0 rows (entire tree deleted!)


-- ==========================================
-- SECTION 4: EXCLUSION CONSTRAINTS (ADVANCED)
-- What: Prevent overlapping ranges (time, dates, numbers)
-- Why: Meeting rooms, price schedules, resource booking
-- ==========================================

-- Install required extension (do ONCE per database)
CREATE EXTENSION IF NOT EXISTS btree_gist;

-- Create meeting rooms table (simple lookup)
CREATE TABLE blogs.meeting_rooms (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50) UNIQUE NOT NULL,
    capacity INT CHECK (capacity > 0)
);

-- Insert rooms
INSERT INTO blogs.meeting_rooms (name, capacity) VALUES
    ('Conference Room A', 10),
    ('Conference Room B', 8),
    ('Boardroom', 15);


-- Create bookings table with EXCLUSION constraint
CREATE TABLE blogs.room_bookings (
    id SERIAL PRIMARY KEY,
    room_id INT NOT NULL REFERENCES blogs.meeting_rooms(id) ON DELETE CASCADE,
    booked_by INT NOT NULL REFERENCES blogs.users(id),
    title VARCHAR(100) NOT NULL,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    
    -- 🎯 THIS IS THE MAGIC: Prevents double-booking!
    CONSTRAINT no_overlapping_booking 
        EXCLUDE USING GIST (
            room_id WITH =,
            tstzrange(start_time, end_time) WITH &&  -- "&&" = overlaps
        )
);

-- Insert a valid booking for Room A
INSERT INTO blogs.room_bookings (room_id, booked_by, title, start_time, end_time) VALUES
    (
        1,  -- Room A
        2,  -- Bob (user_id = 2)
        'Team Meeting',
        '2025-11-15 10:00:00+05',
        '2025-11-15 11:00:00+05'
    );

-- Try to insert OVERLAPPING booking (FAIL!)
INSERT INTO blogs.room_bookings (room_id, booked_by, title, start_time, end_time) VALUES
    (
        1,  -- Same Room A
        3,  -- Charlie
        'Conflicting Meeting',
        '2025-11-15 10:30:00+05',  -- Overlaps with 10:00-11:00
        '2025-11-15 11:30:00+05'
    );
-- ERROR: conflicting key value violates exclusion constraint "no_overlapping_booking"

-- Insert non-overlapping booking (SUCCESS!)
INSERT INTO blogs.room_bookings (room_id, booked_by, title, start_time, end_time) VALUES
    (
        2,  -- Different room (Room B)
        3,
        'Different Room Meeting',
        '2025-11-15 10:30:00+05',
        '2025-11-15 11:30:00+05'
    );
-- SUCCESS: Different room = no conflict


-- ==========================================
-- VERIFICATION QUERIES: Test Your Knowledge
-- ==========================================

-- 1. Count all constraint types
SELECT 
    contype,
    COUNT(*) AS count,
    CASE contype
        WHEN 'c' THEN 'CHECK'
        WHEN 'f' THEN 'FOREIGN KEY'
        WHEN 'p' THEN 'PRIMARY KEY'
        WHEN 'u' THEN 'UNIQUE'
        WHEN 'x' THEN 'EXCLUSION'
    END AS type
FROM pg_constraint
WHERE connamespace = 'blogs'::regnamespace
GROUP BY contype
ORDER BY contype;

-- 2. List all CHECK constraints
SELECT conname, pg_get_constraintdef(oid) 
FROM pg_constraint 
WHERE contype = 'c' AND connamespace = 'blogs'::regnamespace;

-- 3. List all FOREIGN KEYs with CASCADE
SELECT conname, conrelid::regclass, pg_get_constraintdef(oid)
FROM pg_constraint
WHERE contype = 'f' AND pg_get_constraintdef(oid) LIKE '%CASCADE%'
ORDER BY conrelid;

-- 4. Show all indexes (including partial)
SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'blogs'
ORDER BY tablename, indexname;

-- 5. Verify no overlapping bookings exist
SELECT room_id, start_time, end_time, COUNT(*) 
FROM blogs.room_bookings 
GROUP BY room_id, start_time, end_time 
HAVING COUNT(*) > 1;
-- Should return 0 rows (exclusion constraint working!)


-- ==========================================
-- PRACTICE EXERCISES (Try These!)
-- ==========================================

-- Exercise 1: Try to insert an invalid age (should fail)
UPDATE blogs.users SET age = 200 WHERE id = 2;

-- Exercise 2: Try to create duplicate active API key (should fail)
INSERT INTO blogs.api_keys (user_id, key_hash, is_active) VALUES (2, 'another_active', TRUE);

-- Exercise 3: Delete a user and watch CASCADE work
-- (First, create user with profile, then delete user)

-- Exercise 4: Try to double-book a room (should fail)
-- (Insert booking, then try overlapping time for same room)


-- ==========================================
-- CLEANUP (Optional - Remove Test Tables)
-- ==========================================

-- Drop test tables if you want a clean slate
DROP TABLE IF EXISTS blogs.user_profiles CASCADE;
DROP TABLE IF EXISTS blogs.posts_with_category CASCADE;
DROP TABLE IF EXISTS blogs.nested_comments CASCADE;
DROP TABLE IF EXISTS blogs.product_prices CASCADE;
DROP TABLE IF EXISTS blogs.room_bookings CASCADE;
DROP TABLE IF EXISTS blogs.meeting_rooms CASCADE;

-- ==========================================
-- DAY 4 COMPLETE!
-- What You Can Now Do:
-- ✅ Validate data with CHECK constraints (ages, emails, prices)
-- ✅ Prevent duplicates with UNIQUE indexes (case-insensitive!)
-- ✅ Create partial indexes (one active item per user)
-- ✅ Control deletion behavior with CASCADE/SET NULL/RESTRICT
-- ✅ Build self-referencing tables (comment threads)
-- ✅ Prevent double-booking with EXCLUSION constraints
-- ==========================================
