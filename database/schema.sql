------------------------
-- Schema for TourBud --
------------------------

CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL, -- No hashing because we are building a demo MVP
    full_name TEXT,
    contact_number TEXT,
    date_of_birth TEXT, -- Stored as YYYY-MM-DD format
    created_at INTEGER NOT NULL DEFAULT (strftime('%s','now'))
);

CREATE TABLE sessions (
    token TEXT PRIMARY KEY,
    user_id INTEGER NOT NULL,
    expires_at INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Remove expired user session tokens
CREATE TRIGGER cleanup_sessions
BEFORE INSERT ON sessions
BEGIN
    DELETE FROM sessions
    WHERE expires_at <= strftime('%s','now');
END;