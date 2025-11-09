CREATE SCHEMA IF NOT EXISTS app;

CREATE TABLE app.users(
id SERIAL PRIMARY KEY,
email VARCHAR(255) UNIQUE NOT NULL,
name VARCHAR(100),
bio TEXT,
is_active BOOLEAN DEFAULT TRUE,
age INTEGER CHECK (age >=0),
balance DECIMAL(10,2),
last_login timestamptz,
created_at timestamptz DEFAULT NOW(),
metadata jsonb,
CONSTRAINT email_format CHECK (email ~* '^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,}$') 
)

INSERT INTO app.users (name, email, is_active, age, metadata) 
VALUES ('Humayoon', 'Humayoon@gmail.com', TRUE, 23, '{"skin":"Brown", "lang":"Urdu"}');

SELECT email, metadata->>'skin'  AS SKIN, metadata->>'lang' AS LANG FROM app.users;
