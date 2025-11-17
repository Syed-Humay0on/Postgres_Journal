-- Exercise 1: Find 5 oldest users who have emails ending in 'example.com'
SELECT id, username, email, age 
FROM blogs.users 
WHERE email LIKE '%example.com' AND age IS NOT NULL
ORDER BY age DESC 
LIMIT 5;
-- Exercise 2: Find distinct tags used in published posts
SELECT DISTINCT UNNEST(tags) AS tag 
FROM blogs.posts 
WHERE published = TRUE AND tags IS NOT NULL
ORDER BY tag;
