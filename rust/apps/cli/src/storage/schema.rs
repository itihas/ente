use crate::Result;
use rusqlite::Connection;

pub fn create_tables(conn: &Connection) -> Result<()> {
    // A user can have accounts for multiple apps, so the key includes the app.
    conn.execute(
        "CREATE TABLE IF NOT EXISTS accounts (
            user_id INTEGER NOT NULL,
            app TEXT NOT NULL,
            email TEXT NOT NULL,
            endpoint TEXT NOT NULL DEFAULT 'https://api.ente.com',
            export_dir TEXT,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            PRIMARY KEY (user_id, app),
            UNIQUE(email, app, endpoint)
        )",
        [],
    )?;

    conn.execute(
        "CREATE TABLE IF NOT EXISTS secrets (
            user_id INTEGER NOT NULL,
            app TEXT NOT NULL,
            token BLOB NOT NULL,
            master_key BLOB NOT NULL,
            secret_key BLOB NOT NULL,
            public_key BLOB NOT NULL,
            updated_at INTEGER NOT NULL,
            PRIMARY KEY (user_id, app),
            FOREIGN KEY (user_id, app) REFERENCES accounts(user_id, app) ON DELETE CASCADE
        )",
        [],
    )?;

    conn.execute(
        "CREATE TABLE IF NOT EXISTS config (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_at INTEGER NOT NULL
        )",
        [],
    )?;

    // Collection IDs are global; owner records the owning user.
    conn.execute(
        "CREATE TABLE IF NOT EXISTS collections (
            collection_id INTEGER PRIMARY KEY,
            owner INTEGER NOT NULL,
            name TEXT NOT NULL,
            type TEXT NOT NULL,
            is_deleted INTEGER NOT NULL DEFAULT 0,
            metadata TEXT,
            updated_at INTEGER NOT NULL
        )",
        [],
    )?;

    // File IDs are global; owner_id records the owning user.
    conn.execute(
        "CREATE TABLE IF NOT EXISTS files (
            file_id INTEGER PRIMARY KEY,
            owner_id INTEGER NOT NULL,
            collection_id INTEGER NOT NULL,
            encrypted_key TEXT NOT NULL,
            key_decryption_nonce TEXT NOT NULL,
            file_info TEXT NOT NULL,
            metadata TEXT NOT NULL,
            pub_magic_metadata TEXT,
            content_hash TEXT,
            is_deleted INTEGER NOT NULL DEFAULT 0,
            is_synced_locally INTEGER NOT NULL DEFAULT 0,
            local_path TEXT,
            updated_at INTEGER NOT NULL,
            FOREIGN KEY (collection_id) REFERENCES collections(collection_id)
        )",
        [],
    )?;

    conn.execute(
        "CREATE TABLE IF NOT EXISTS album_files (
            album_id INTEGER NOT NULL,
            file_id INTEGER NOT NULL,
            synced_locally INTEGER NOT NULL DEFAULT 0,
            created_at INTEGER NOT NULL,
            PRIMARY KEY (album_id, file_id),
            FOREIGN KEY (album_id) REFERENCES collections(collection_id),
            FOREIGN KEY (file_id) REFERENCES files(file_id)
        )",
        [],
    )?;

    conn.execute(
        "CREATE TABLE IF NOT EXISTS sync_state (
            user_id INTEGER NOT NULL,
            app TEXT NOT NULL,
            last_file_sync INTEGER,
            last_collection_sync INTEGER,
            last_album_sync INTEGER,
            sync_status TEXT,
            PRIMARY KEY (user_id, app),
            FOREIGN KEY (user_id, app) REFERENCES accounts(user_id, app) ON DELETE CASCADE
        )",
        [],
    )?;

    conn.execute(
        "CREATE TABLE IF NOT EXISTS collection_sync_state (
            user_id INTEGER NOT NULL,
            collection_id INTEGER NOT NULL,
            last_sync_time INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            PRIMARY KEY (user_id, collection_id),
            FOREIGN KEY (collection_id) REFERENCES collections(collection_id) ON DELETE CASCADE
        )",
        [],
    )?;

    conn.execute(
        "CREATE INDEX IF NOT EXISTS idx_files_collection 
         ON files(collection_id)",
        [],
    )?;

    conn.execute(
        "CREATE INDEX IF NOT EXISTS idx_files_owner 
         ON files(owner_id)",
        [],
    )?;

    conn.execute(
        "CREATE INDEX IF NOT EXISTS idx_album_files_album 
         ON album_files(album_id)",
        [],
    )?;

    conn.execute(
        "CREATE INDEX IF NOT EXISTS idx_collections_owner 
         ON collections(owner)",
        [],
    )?;

    conn.execute(
        "CREATE INDEX IF NOT EXISTS idx_accounts_email 
         ON accounts(email)",
        [],
    )?;

    conn.execute(
        "CREATE INDEX IF NOT EXISTS idx_collection_sync_state 
         ON collection_sync_state(user_id, collection_id)",
        [],
    )?;

    conn.execute(
        "CREATE INDEX IF NOT EXISTS idx_files_hash 
         ON files(owner_id, content_hash) 
         WHERE content_hash IS NOT NULL AND is_deleted = 0",
        [],
    )?;

    Ok(())
}
