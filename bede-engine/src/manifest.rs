use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Package {
    pub name: String,
    pub version: String,
    pub dependencies: HashMap<String, String>,
    pub download_url: String,
    pub sha256: String,
}

#[derive(Debug, Default)]
pub struct PackageDb {
    pub packages: HashMap<String, Vec<Package>>, // name -> versions
}

impl PackageDb {
    pub fn from_json(path: &str) -> anyhow::Result<Self> {
        let data = std::fs::read_to_string(path)?;
        let pkgs: Vec<Package> = serde_json::from_str(&data)?;
        let mut db = PackageDb::default();
        for pkg in pkgs {
            db.packages.entry(pkg.name.clone()).or_default().push(pkg);
        }
        Ok(db)
    }
}
