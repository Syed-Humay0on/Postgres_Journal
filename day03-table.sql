-- ==========================================
-- Day 3: Complete CRUD Operations Mastery
-- PostgreSQL 30-Day Mastery Journey
-- Generated: 2025-11-11
-- ==========================================

-- ==========================================
-- SECTION 1: CREATE (INSERT) Patterns
-- ==========================================

-- 1.1 Simple INSERT (single row)
INSERT INTO blogs.users (username, email, password_hash) VALUES
    ('crud_demo', 'demo@crud.com', 'fake_hash_123');

-- 1.2 INSERT with RETURNING (get generated ID)
INSERT INTO blogs.users (username, email, password_hash) VALUES
    ('returning_demo', 'returning@demo.com', 'hash456')
RETURNING id, username, email, created_at;

-- 1.3 Batch INSERT (multiple rows, one command)
INSERT INTO blogs.users (username, email, password_hash) VALUES
    ('batch1', 'batch1@example.com', 'hash1'),
    ('batch2', 'batch2@example.com', 'hash2'),
    ('batch3', 'batch3@example.com', 'hash3'),
    ('batch4', 'batch4@example.com', 'hash4'),
    ('batch5', 'batch5@example.com', 'hash5')
RETURNING id, username;

-- 1.4 INSERT with subquery (dynamic user_id)
INSERT INTO blogs.posts (user_id, title, published, tags) VALUES
    (
        (SELECT id FROM blogs.users WHERE username = 'crud_demo' LIMIT 1),
        'Dynamic User Post',
        TRUE,
        ARRAY['subquery', 'demo']
    )
RETURNING id, title, user_id;

-- 1.5 INSERT from SELECT (copy data)
CREATE TABLE IF NOT EXISTS blogs.users_backup AS
SELECT * FROM blogs.users WHERE FALSE;  -- Empty structure

INSERT INTO blogs.users_backup 
SELECT * FROM blogs.users WHERE username LIKE 'batch%'
RETURNING id, username;


-- ==========================================
-- SECTION 2: READ (SELECT) Patterns
-- ==========================================

-- 2.1 Basic SELECT with JSONB extraction
SELECT 
    title,
    metadata->>'views' AS view_count,
    metadata->>'draft_notes' AS notes
FROM blogs.posts
WHERE metadata ? 'views'
LIMIT 5;

-- 2.2 Type casting for math on JSONB values
SELECT 
    title,
    (metadata->>'views')::INT + 100 AS inflated_views
FROM blogs.posts
WHERE metadata ? 'views';

-- 2.3 INNER JOIN (posts with authors)
SELECT 
    u.username,
    p.title,
    p.published,
    p.tags
FROM blogs.users u
INNER JOIN blogs.posts p ON u.id = p.user_id
WHERE u.username IN ('batch1', 'batch2')
LIMIT 10;

-- 2.4 LEFT JOIN (all users, even without posts)
SELECT 
    u.username,
    COUNT(p.id) AS post_count
FROM blogs.users u
LEFT JOIN blogs.posts p ON u.id = p.user_id
GROUP BY u.username
ORDER BY post_count DESC;

-- 2.5 Array operators (GIN index usage)
-- Contains all (AND logic)
SELECT title, tags FROM blogs.posts 
WHERE tags @> ARRAY['postgres', 'performance']
LIMIT 5;

-- Overlaps (OR logic)
SELECT title, tags FROM blogs.posts 
WHERE tags && ARRAY['sql', 'postgres']
LIMIT 5;

-- 2.6 Unnest arrays to rows
SELECT DISTINCT tag FROM (
    SELECT unnest(tags) AS tag FROM blogs.posts
) sub 
WHERE tag IN ('postgres', 'sql', 'tutorial', 'performance')
ORDER BY tag;


-- ==========================================
-- SECTION 3: UPDATE Patterns
-- ==========================================

-- 3.1 Simple UPDATE with RETURNING
UPDATE blogs.users SET is_verified = TRUE 
WHERE username = 'batch1'
RETURNING id, username, is_verified;

-- 3.2 UPDATE JSONB (concatenation)
UPDATE blogs.posts 
SET metadata = metadata || '{"category": "database"}'::jsonb
WHERE id = 2
RETURNING id, title, metadata;

-- 3.3 UPDATE with complex subquery (power users)
UPDATE blogs.posts 
SET published = true, published_at = NOW()
WHERE 
    published = false 
    AND user_id IN (
        SELECT user_id 
        FROM blogs.posts 
        GROUP BY user_id 
        HAVING COUNT(*) > 100
    )
RETURNING id, title, user_id, published_at;

-- 3.4 UPDATE with GIN index (mass tag update)
UPDATE blogs.posts 
SET metadata = metadata || '{"priority": "high"}'::jsonb
WHERE tags @> ARRAY['postgres']
RETURNING id, title, tags;

-- 3.5 UPDATE with jsonb_set (modify specific key)
UPDATE blogs.posts 
SET metadata = jsonb_set(metadata, '{views}', '100'::jsonb)
WHERE id = 2
RETURNING id, title, metadata;


-- ==========================================
-- SECTION 4: DELETE Patterns
-- ==========================================

-- 4.1 Simple DELETE with RETURNING
DELETE FROM blogs.users WHERE username = 'batch5'
RETURNING id, username, 'DELETED' AS status;

-- 4.2 DELETE with CASCADE (setup + execute)
-- Setup test user with post
INSERT INTO blogs.users (username, email, password_hash) VALUES
    ('cascade_test', 'test@cascade.com', 'hash');
INSERT INTO blogs.posts (user_id, title, published) VALUES
    ((SELECT id FROM blogs.users WHERE username = 'cascade_test'), 'Cascade Test Post', TRUE);

-- Verify posts exist
SELECT COUNT(*) FROM blogs.posts WHERE user_id = (SELECT id FROM blogs.users WHERE username = 'cascade_test');

-- DELETE user (cascades to posts)
DELETE FROM blogs.users WHERE username = 'cascade_test'
RETURNING id, username;

-- Verify cascade worked
SELECT COUNT(*) FROM blogs.posts WHERE user_id = (SELECT id FROM blogs.users WHERE username = 'cascade_test');

-- 4.3 DELETE with CTE (complex cleanup)
WITH draft_posts AS (
    SELECT p.id, p.title 
    FROM blogs.posts p
    WHERE p.published = false AND p.created_at < NOW() - INTERVAL '1 year'
)
DELETE FROM blogs.posts 
WHERE id IN (SELECT id FROM draft_posts)
RETURNING id, title, 'DELETED' AS reason;


-- ==========================================
-- SECTION 5: ON CONFLICT (Upserts)
-- ==========================================

-- 5.1 INSERT or UPDATE (upsert)
INSERT INTO blogs.users (username, email, password_hash) VALUES
    ('batch3', 'newemail@upsert.com', 'new_hash')
ON CONFLICT (username) DO UPDATE
SET 
    email = EXCLUDED.email,
    password_hash = EXCLUDED.password_hash,
    is_verified = TRUE
RETURNING id, username, email, 'UPSERTED' AS action;

-- 5.2 INSERT or IGNORE (do nothing on conflict)
INSERT INTO blogs.users (username, email, password_hash) VALUES
    ('batch4', 'batch4@exists.com', 'hash'),
    ('new_user_unique', 'unique@user.com', 'hash')
ON CONFLICT (username) DO NOTHING
RETURNING id, username;


-- ==========================================
-- SECTION 6: Transactions (All-or-Nothing)
-- ==========================================

-- 6.1 Multi-step transaction
BEGIN;

-- Create a post
INSERT INTO blogs.posts (user_id, title, published, tags) VALUES
    (
        (SELECT id FROM blogs.users WHERE username = 'batch2' LIMIT 1),
        'Transactional Post',
        FALSE,
        ARRAY['transaction', 'demo']
    ) RETURNING id, title;

-- Update it
UPDATE blogs.posts 
SET published = TRUE, tags = ARRAY['transaction', 'published']
WHERE title = 'Transactional Post'
RETURNING id, title, published;

-- Verify
SELECT id, title, published, tags FROM blogs.posts 
WHERE title = 'Transactional Post';

COMMIT;

-- 6.2 Transaction with ROLLBACK example
BEGIN;

INSERT INTO blogs.users (username, email, password_hash) VALUES
    ('rollback_test', 'rollback@test.com', 'hash') RETURNING id;

-- Oops, made a mistake!
ROLLBACK;  -- Undoes the insert

-- Verify it was rolled back
SELECT id, username FROM blogs.users WHERE username = 'rollback_test';
-- Should return 0 rows


-- ==========================================
-- SECTION 7: Index & Performance Verification
-- ==========================================

-- 7.1 Create GIN index for metadata (if not exists)
DROP INDEX IF EXISTS blogs.idx_posts_metadata;
CREATE INDEX idx_posts_metadata ON blogs.posts USING GIN(metadata);

-- 7.2 Verify index usage
EXPLAIN (ANALYZE, BUFFERS) SELECT title, metadata->>'category' 
FROM blogs.posts 
WHERE metadata ? 'category' 
LIMIT 5;

-- 7.3 Force index scan (demonstration)
SET enable_seqscan = OFF;
EXPLAIN (ANALYZE, BUFFERS) SELECT title, metadata->>'category' 
FROM blogs.posts 
WHERE metadata ? 'category';
SET enable_seqscan = ON;


-- ==========================================
-- SECTION 8: Common Pitfalls & Best Practices
-- ==========================================

-- PITFALL 1: WHERE clause cannot have AS alias
-- ❌ WRONG: SELECT title FROM posts WHERE id AS post_id = 4;
-- ✅ CORRECT: SELECT title, id AS post_id FROM posts WHERE id = 4;

-- PITFALL 2: WHERE needs boolean, not text
-- ❌ WRONG: SELECT title FROM posts WHERE metadata->>'key';
-- ✅ CORRECT: SELECT title FROM posts WHERE metadata ? 'key';

-- PITFALL 3: Querying JSONB value as key
-- ❌ WRONG: SELECT metadata->>'database' FROM posts;  -- Looking for value as key
-- ✅ CORRECT: SELECT metadata->>'category' FROM posts;  -- Use actual key name

-- PITFALL 4: UPDATE 0 is not an error
-- Always verify rows exist before UPDATE
SELECT id FROM posts WHERE condition;  -- Verify first
UPDATE posts SET ... WHERE condition RETURNING *;  -- Then update

-- PITFALL 5: Forgetting to create GIN index on JSONB
-- Always index frequently queried JSONB columns
CREATE INDEX idx_posts_metadata ON posts USING GIN(metadata);


-- ==========================================
-- SECTION 9: Verification Queries
-- ==========================================

-- Final counts
SELECT 'users' AS table_name, COUNT(*) AS row_count FROM blogs.users
UNION ALL SELECT 'posts', COUNT(*) FROM blogs.posts
UNION ALL SELECT 'comments', COUNT(*) FROM blogs.comments;

-- Check indexes exist
SELECT schemaname, tablename, indexname, indexdef 
FROM pg_indexes 
WHERE schemaname = 'blogs'
ORDER BY tablename, indexname;

-- Sample data integrity check
SELECT u.username, COUNT(p.id) AS posts, COUNT(c.id) AS comments
FROM blogs.users u
LEFT JOIN blogs.posts p ON u.id = p.user_id
LEFT JOIN blogs.comments c ON u.id = c.user_id
GROUP BY u.username
ORDER BY posts DESC
LIMIT 10;
