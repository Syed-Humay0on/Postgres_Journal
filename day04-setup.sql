-- 📌 Day 4 Roadmap (4 Sections)
--
--     CHECK Constraints Deep Dive (we start here)
--     UNIQUE Constraints & Partial Indexes
--     FOREIGN KEY Nuances & Cascade Behaviors
--     EXCLUSION Constraints (Advanced)

-- Add an age column with CHECK constraint
ALTER TABLE blogs.users 
ADD COLUMN age INT CHECK (age >= 13 AND age <= 120);

-- Test valid age
UPDATE blogs.users SET age = 25 WHERE username = 'valid_email' RETURNING username, age;

-- Test invalid age (too young)
UPDATE blogs.users SET age = 12 WHERE username = 'valid_email';

-- RegEx wildcard so insteda of [A-Za-z0-9_]+ we can simply write \w+ and catpuring group ( \w+){0,3} where it captures a space followed by a word 0-3 times; 
alter table blogs.users add constraint users_username_format check (username ~* '^\w+( \w+){0,3}$');
update blogs.users set username = 'Queen Elizabeth of England' where id = 19;

update blogs.posts set metadata = metadata || '{"views" : 150}'::JSONB where user_id = 19 Returning id, title, metadata;

-- You're about to run a destructive command.
-- Do you want to proceed? [y/N]: y
-- Your call!
-- +-------+--------------------+----------------+
-- | id    | title              | metadata       |
-- |-------+--------------------+----------------|
-- | 10510 | Transactional Post | {"views": 150} |
-- +-------+--------------------+----------------+
--
update blogs.posts set metadata = metadata || '{"views" : -150}'::JSONB where user_id = 19 Returning id, title, metadata;
-- You're about to run a destructive command.
-- Do you want to proceed? [y/N]: y
-- Your call!
-- new row for relation "posts" violates check constraint "check_value_positive"
-- DETAIL:  Failing row contains (10510, 19, Transactional Post, null, t, null, {transaction,published}, {"views": -150}, 2025-11-11 22:08:15.916363+05, 2025-11-11 22:08>

  -- 🔍 Query 1: View All CHECK Constraints in the blogs Schema
select conname as contraint_name, conrelid::REGCLASS as table_name, pg_get_constraintdef(oid) as definition from pg_constraint where connamespace = 'blogs'::regnamespace and contype = 'c' order by conrelid, conname;
-- +-----------------------+----------------+----------------------------------------------------------------------------+
-- | contraint_name        | table_name     | definition                                                                 |
-- |-----------------------+----------------+----------------------------------------------------------------------------|
-- | users_age_check       | blogs.users    | CHECK (((age >= 13) AND (age <= 120)))                                     |
-- | users_email_check     | blogs.users    | CHECK (((email)::text ~* '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$'::text)) |
-- | users_username_format | blogs.users    | CHECK (((username)::text ~* '^\w+( \w+){0,3}$'::text))                     |
-- | check_value_positive  | blogs.posts    | CHECK ((((metadata ->> 'views'::text))::integer >= 0))                     |
-- | mix_max_stock_check   | blogs.products | CHECK ((min_stock < max_stock))                                            |
-- | price_discount_check  | blogs.products | CHECK (((discount_price IS NULL) OR (discount_price < price)))             |
-- | stock_bound_check     | blogs.products | CHECK (((stock_quantity >= min_stock) AND (stock_quantity <= max_stock)))  |
-- +-----------------------+----------------+----------------------------------------------------------------------------+

create unique index user_email_unique_lower on blogs.users (LOWER(email));
-- CREATE INDEX
-- Time: 0.008s

insert into blogs.users (username, email, password_hash) values ('BOB', 'BOB@EXAMPLE.COM', 'hasheh_bob');
-- duplicate key value violates unique constraint "user_email_unique_lower"
-- DETAIL:  Key (lower(email::text))=(bob@example.com) already exists.

insert into blogs.users (username, email, password_hash) values ('charlie', 'CHARlie@test.ORG', 'hasheh_bob');
-- duplicate key value violates unique constraint "users_username_key"
-- DETAIL:  Key (username)=(charlie) already exists.

insert into blogs.users (username, email, password_hash) values ('charli3', 'CHARlie@test.ORG', 'hasheh_bob');
-- duplicate key value violates unique constraint "user_email_unique_lower"
-- DETAIL:  Key (lower(email::text))=(charlie@test.org) already exists.

