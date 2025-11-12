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
