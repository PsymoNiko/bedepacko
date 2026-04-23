use serde::{Serialize, Deserialize};
use std::collections::HashMap;
use std::fs;
use std::path::Path;

#[derive(Debug, Serialize, Deserialize)]
pub struct LockEntry {
    pub version: String,
    pub url: String,
    pub sha256: String,
}

pub type Lockfile = HashMap<String, LockEntry>;

pub fn read_lockfile(path: &Path) -> anyhow::Result<Option<Lockfile>> {
    if !path.exists() {
        return Ok(None);
    }
    let content = fs::read_to_string(path)?;
    Ok(Some(toml::from_str(&content)?))
}

pub fn write_lockfile(lock: &Lockfile, path: &Path) -> anyhow::Result<()> {
    let toml = toml::to_string_pretty(lock)?;
    fs::write(path, toml)?;
    Ok(())
}
