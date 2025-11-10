-- ==========================================
-- Day 2: Production-Ready Blog Schema
-- PostgreSQL 30-Day Mastery Journey
-- Generated: 2025-11-10
-- ==========================================

-- Section 1: Clean Slate - Drop and Recreate Schema
-- ------------------------------------------------
-- WARNING: This wipes ALL data in the 'blogs' schema
DROP SCHEMA IF EXISTS blogs CASCADE;
CREATE SCHEMA blogs;


-- Section 2: Table Definitions with Constraints
-- ---------------------------------------------
-- Users table with email validation and unique constraints
CREATE TABLE blogs.users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL CHECK (email ~* '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$'),
    password_hash VARCHAR(60) NOT NULL,
    is_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Posts table with foreign key and array/GIN support
CREATE TABLE blogs.posts (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES blogs.users(id) ON DELETE CASCADE,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    published BOOLEAN DEFAULT FALSE,
    published_at TIMESTAMPTZ,
    tags TEXT[],
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Comments table with nested self-referencing comments
CREATE TABLE blogs.comments (
    id SERIAL PRIMARY KEY,
    post_id INTEGER REFERENCES blogs.posts(id) ON DELETE CASCADE,
    user_id INTEGER REFERENCES blogs.users(id) ON DELETE CASCADE,
    parent_id INTEGER REFERENCES blogs.comments(id),
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);


-- Section 3: Indexes (B-tree and GIN)
-- ------------------------------------
-- B-tree indexes for foreign keys and sorting
CREATE INDEX idx_posts_user_id ON blogs.posts(user_id);
CREATE INDEX idx_posts_published ON blogs.posts(published, published_at DESC);
CREATE INDEX idx_comments_post_id ON blogs.comments(post_id);

-- GIN index for array tag searches (super fast @> queries)
CREATE INDEX idx_posts_tags ON blogs.posts USING GIN(tags);


-- Section 4: Initial Data Seed (Realistic)
-- -----------------------------------------
-- Insert test users (password hashes are fake bcrypt for demo)
INSERT INTO blogs.users (username, email, password_hash) VALUES
    ('alice', 'alice@example.com', '$2b$12$R9h/cIPz0gi.OWNNv9aaI.sjdvswxS2HvvZsX..aZNRbRzKVjWwy'),
    ('bob', 'bob@example.com', '$2b$12$KIXpS8zKzJxTpjWQFl7y1uI0pJHqDvpN6oNxJNp9QHMG5DGnH2kla'),
    ('charlie', 'charlie@test.org', '$2b$12$QMz8sXzLQ3pLr8xVnHzJLu5j7v9w0Rq9pTlM8nYyX5vKLpq8kM0d');

-- Insert sample posts
INSERT INTO blogs.posts (user_id, title, content, published, tags, metadata) VALUES
    (1, 'PostgreSQL for Beginners', 'This is the content of the beginner post', TRUE, ARRAY['postgres', 'tutorial'], '{"views": 150}'::jsonb),
    (1, 'Advanced Indexing', 'Deep dive into GIN indexes', TRUE, ARRAY['postgres', 'performance'], '{"views": 89}'::jsonb),
    (2, 'Why I Love SQL', 'SQL is awesome', TRUE, ARRAY['sql', 'opinion'], '{"views": 234}'::jsonb),
    (1, 'Draft: GIN Deep Dive', 'Work in progress', FALSE, ARRAY['postgres', 'draft'], '{"draft_notes": "Finish this soon"}'::jsonb);

-- Insert nested comments (demonstrates self-referencing FK)
-- Note: Must insert parent comment first, then child comment
INSERT INTO blogs.comments (post_id, user_id, content, parent_id) VALUES
    (1, 2, 'Great tutorial! Very helpful.', NULL),
    (1, 1, 'Thanks! More coming soon.', NULL),
    (1, 3, 'I agree with bob!', 2);  -- Reply to comment #2


-- Section 5: GIN Index Stress Test - Generate 10,000 Rows
-- --------------------------------------------------------
-- This demonstrates generate_series and array population
INSERT INTO blogs.posts (user_id, title, published, tags)
SELECT 
    (random()*2)::INT + 1,  -- Random user_id: 1, 2, or 3
    'Bulk Post ' || i,        -- Title: "Bulk Post 1", "Bulk Post 2", etc.
    random() > 0.5,           -- 50% chance of published=TRUE
    ARRAY[(ARRAY['postgres', 'sql', 'tutorial', 'performance'])[1 + (random()*3)::INT]]
FROM generate_series(1, 10000) i;


-- Section 6: Constraint Validation Tests
-- --------------------------------------
-- These queries should be run individually to verify constraints

-- ✅ Email validation (PASS)
-- INSERT INTO blogs.users (username, email, password_hash) VALUES
--     ('valid_test', 'user+tag@sub.domain.co.uk', 'hash');

-- ❌ Email validation (FAIL - no @)
-- INSERT INTO blogs.users (username, email, password_hash) VALUES
--     ('invalid_test', 'noatsign.com', 'hash');

-- ❌ Unique username (FAIL - duplicate)
-- INSERT INTO blogs.users (username, email, password_hash) VALUES
--     ('alice', 'different@email.com', 'hash');

-- ❌ Foreign key (FAIL - user doesn't exist)
-- INSERT INTO blogs.posts (user_id, title, published, tags) VALUES
--     (999, 'Invalid User Post', TRUE, ARRAY['postgres']);

-- ✅ Foreign key cascade (DELETE user removes posts)
-- DELETE FROM blogs.users WHERE username = 'charlie';
-- SELECT COUNT(*) FROM blogs.posts WHERE user_id NOT IN (SELECT id FROM blogs.users); -- Should be 0


-- Section 7: EXPLAIN ANALYZE Examples
-- ------------------------------------
-- Run these to see index behavior

-- Test 1: Seq Scan (LIMIT 5 - early stopping)
-- EXPLAIN ANALYZE SELECT title, tags FROM blogs.posts WHERE tags @> ARRAY['postgres'] LIMIT 5;

-- Test 2: GIN Index (COUNT all - no early stopping)
-- EXPLAIN ANALYZE SELECT COUNT(*) FROM blogs.posts WHERE tags @> ARRAY['postgres'];

-- Test 3: GIN Index (SELECT all - must fetch all rows)
-- EXPLAIN ANALYZE SELECT title, tags FROM blogs.posts WHERE tags @> ARRAY['postgres'];

-- Test 4: Show all postgres-tagged posts
-- SELECT title, tags FROM blogs.posts WHERE tags @> ARRAY['postgres'] LIMIT 10;

-- Test 5: Tag frequency analysis
-- SELECT 
--     tag, 
--     COUNT(*) 
-- FROM (
--     SELECT unnest(tags) AS tag FROM blogs.posts
-- ) sub 
-- WHERE tag IN ('postgres', 'sql', 'tutorial', 'performance')
-- GROUP BY tag;


-- Section 8: Verification Queries
-- --------------------------------
-- Run these to verify your schema is correct

-- Count rows in each table
SELECT 'users' AS table_name, COUNT(*) AS row_count FROM blogs.users
UNION ALL
SELECT 'posts', COUNT(*) FROM blogs.posts
UNION ALL
SELECT 'comments', COUNT(*) FROM blogs.comments;

-- Verify indexes exist
SELECT tablename, indexname, indexdef 
FROM pg_indexes 
WHERE schemaname = 'blogs'
ORDER BY tablename;
