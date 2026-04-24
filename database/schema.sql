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

------------------------
-- Trip Management --
------------------------

CREATE TABLE trips (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    trip_name TEXT NOT NULL,
    start_date TEXT NOT NULL, -- YYYY-MM-DD format
    end_date TEXT NOT NULL,   -- YYYY-MM-DD format
    budget_goal REAL,         -- NULL if no budget set
    budget_currency TEXT DEFAULT 'USD',
    created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Create index for faster queries
CREATE INDEX idx_trips_user_id ON trips(user_id);
CREATE INDEX idx_trips_dates ON trips(start_date, end_date);

-- Trigger to automatically update updated_at timestamp
CREATE TRIGGER update_trips_timestamp 
AFTER UPDATE ON trips
BEGIN
    UPDATE trips SET updated_at = strftime('%s','now') 
    WHERE id = NEW.id;
END;

------------------------
-- Expense Tracking --
------------------------

CREATE TABLE expenses (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    trip_id INTEGER NOT NULL,
    amount REAL NOT NULL,
    category TEXT NOT NULL,
    currency TEXT NOT NULL DEFAULT 'USD',
    description TEXT,
    expense_date TEXT NOT NULL, -- YYYY-MM-DD format
    created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
);

-- Create indexes for faster queries
CREATE INDEX idx_expenses_trip_id ON expenses(trip_id);
CREATE INDEX idx_expenses_category ON expenses(category);
CREATE INDEX idx_expenses_date ON expenses(expense_date);

-- Trigger to automatically update updated_at timestamp
CREATE TRIGGER update_expenses_timestamp 
AFTER UPDATE ON expenses
BEGIN
    UPDATE expenses SET updated_at = strftime('%s','now') 
    WHERE id = NEW.id;
END;

-- Predefined categories (for reference)
-- 'accommodation', 'transportation', 'food', 'activities', 'shopping', 'other'

------------------------
-- Location Management --
------------------------

CREATE TABLE locations (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    trip_id INTEGER NOT NULL,
    place_name TEXT NOT NULL,
    arrival_date TEXT NOT NULL, -- YYYY-MM-DD format
    departure_date TEXT NOT NULL, -- YYYY-MM-DD format
    notes TEXT,
    created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    FOREIGN KEY (trip_id) REFERENCES trips(id) ON DELETE CASCADE
);

-- Create indexes for faster queries
CREATE INDEX idx_locations_trip_id ON locations(trip_id);
CREATE INDEX idx_locations_dates ON locations(arrival_date, departure_date);

-- Trigger to automatically update updated_at timestamp
CREATE TRIGGER update_locations_timestamp 
AFTER UPDATE ON locations
BEGIN
    UPDATE locations SET updated_at = strftime('%s','now') 
    WHERE id = NEW.id;
END;

------------------------
-- Todo Management --
------------------------

CREATE TABLE todos (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    location_id INTEGER NOT NULL,
    description TEXT NOT NULL,
    is_completed INTEGER NOT NULL DEFAULT 0, -- 0 = false, 1 = true
    category TEXT NOT NULL DEFAULT 'other',
    due_date TEXT, -- YYYY-MM-DD format (optional)
    created_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE
);

-- Create indexes for faster queries
CREATE INDEX idx_todos_location_id ON todos(location_id);
CREATE INDEX idx_todos_completed ON todos(is_completed);
CREATE INDEX idx_todos_category ON todos(category);
CREATE INDEX idx_todos_due_date ON todos(due_date);

-- Trigger to automatically update updated_at timestamp
CREATE TRIGGER update_todos_timestamp 
AFTER UPDATE ON todos
BEGIN
    UPDATE todos SET updated_at = strftime('%s','now') 
    WHERE id = NEW.id;
END;

-- Predefined todo categories (for reference)
-- 'sightseeing', 'food', 'transport', 'accommodation', 'packing', 'booking', 'other'

------------------------
-- Gallery Management --
------------------------

CREATE TABLE gallery (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    location_id INTEGER NOT NULL,
    image_path TEXT NOT NULL, -- Local file path (e.g., /static/uploads/filename.jpg)
    caption TEXT, -- Optional description
    file_name TEXT NOT NULL, -- Original file name
    file_size INTEGER, -- File size in bytes
    mime_type TEXT, -- e.g., image/jpeg, image/png
    uploaded_at INTEGER NOT NULL DEFAULT (strftime('%s','now')),
    FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE CASCADE
);

-- Create indexes for faster queries
CREATE INDEX idx_gallery_location_id ON gallery(location_id);
CREATE INDEX idx_gallery_uploaded_at ON gallery(uploaded_at);