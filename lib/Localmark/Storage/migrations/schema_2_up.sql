CREATE TABLE IF NOT EXISTS comments (
       resource_id INTEGER,
       version INTEGER default 0,
       comment TEXT,
       inserted_at DATETIME
);
