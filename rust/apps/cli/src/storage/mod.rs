use crate::Result;
use rusqlite::Connection;
use serde::{Deserialize, Serialize};
use std::path::{Path, PathBuf};

pub mod account;
pub mod config;
pub mod schema;
pub mod sync;

pub use account::AccountStore;
pub use config::ConfigStore;
pub use sync::SyncStore;

pub struct Storage {
    conn: Connection,
    path: Option<PathBuf>,
}

impl Storage {
    pub fn new<P: AsRef<Path>>(path: P) -> Result<Self> {
        let path_buf = path.as_ref().to_path_buf();
        let conn = Connection::open(&path_buf)?;

        conn.execute("PRAGMA foreign_keys = ON", [])?;

        schema::create_tables(&conn)?;

        Ok(Self {
            conn,
            path: Some(path_buf),
        })
    }

    pub fn new_in_memory() -> Result<Self> {
        let conn = Connection::open_in_memory()?;
        conn.execute("PRAGMA foreign_keys = ON", [])?;
        schema::create_tables(&conn)?;
        Ok(Self { conn, path: None })
    }

    pub fn conn(&self) -> &Connection {
        &self.conn
    }

    pub fn transaction<F, R>(&mut self, f: F) -> Result<R>
    where
        F: FnOnce(&rusqlite::Transaction) -> Result<R>,
    {
        let tx = self.conn.transaction()?;
        let result = f(&tx)?;
        tx.commit()?;
        Ok(result)
    }

    pub fn accounts(&self) -> AccountStore<'_> {
        AccountStore::new(&self.conn)
    }

    pub fn config(&self) -> ConfigStore<'_> {
        ConfigStore::new(&self.conn)
    }

    pub fn sync(&self) -> SyncStore<'_> {
        SyncStore::new(&self.conn)
    }

    pub fn db_path(&self) -> Option<&Path> {
        self.path.as_deref()
    }
}

pub trait JsonValue: Serialize + for<'de> Deserialize<'de> {
    fn to_json(&self) -> Result<String> {
        Ok(serde_json::to_string(self)?)
    }

    fn from_json(json: &str) -> Result<Self> {
        Ok(serde_json::from_str(json)?)
    }
}

impl<T> JsonValue for T where T: Serialize + for<'de> Deserialize<'de> {}
