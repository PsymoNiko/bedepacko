mod downloader;
mod lockfile;
mod manifest;
mod resolver;

use anyhow::Result;
use clap::{Parser, Subcommand};
use std::path::PathBuf;

#[derive(Parser)]
#[command(name = "bede-engine", about = "High-performance backend for bedepacko")]
struct Cli {
    #[command(subcommand)]
    cmd: Command,
}

#[derive(Subcommand)]
enum Command {
    /// Fetch and download packages (parallel)
    Fetch {
        #[arg(required = true)]
        packages: Vec<String>,
        #[arg(short, long, default_value = "latest")]
        version: String,
        #[arg(short, long)]
        repo: Option<PathBuf>,
        #[arg(short, long, default_value = "./packages")]
        dest: PathBuf,
    },
    /// Resolve dependencies without downloading
    Resolve {
        package: String,
        #[arg(short, long, default_value = "latest")]
        version: String,
    },
    /// Generate lockfile
    Lock {
        package: String,
        #[arg(short, long, default_value = "bede.lock")]
        output: PathBuf,
    },
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();
    match cli.cmd {
        Command::Fetch { packages, version, repo, dest } => {
            let repo_path = repo.unwrap_or_else(|| PathBuf::from("./repo.json"));
            let db = manifest::PackageDb::from_json(repo_path.to_str().unwrap())?;
            let mut all_pkgs = Vec::new();
            for p in packages {
                let resolved = resolver::resolve(&p, &db, &version)?;
                all_pkgs.extend(resolved);
            }
            let downloaded = downloader::download_packages(&all_pkgs, &dest).await?;
            for f in downloaded {
                println!("DOWNLOADED: {}", f);
            }
        }
        Command::Resolve { package, version } => {
            let db = manifest::PackageDb::from_json("repo.json")?;
            let resolved = resolver::resolve(&package, &db, &version)?;
            for pkg in resolved {
                println!("{} {}", pkg.name, pkg.version);
            }
        }
        Command::Lock { package, output } => {
            let db = manifest::PackageDb::from_json("repo.json")?;
            let resolved = resolver::resolve(&package, &db, "latest")?;
            let mut lock = lockfile::Lockfile::new();
            for pkg in resolved {
                lock.insert(pkg.name, lockfile::LockEntry {
                    version: pkg.version,
                    url: pkg.download_url,
                    sha256: pkg.sha256,
                });
            }
            lockfile::write_lockfile(&lock, &output)?;
            println!("Lockfile written to {}", output.display());
        }
    }
    Ok(())
}
