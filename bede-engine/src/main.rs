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
    /// Remove installed packages
    Remove {
        #[arg(required = true)]
        packages: Vec<String>,
    },
    /// List installed packages
    List,
}

#[tokio::main]
async fn main() -> Result<()> {
    let cli = Cli::parse();
    match cli.cmd {
        Command::Fetch { packages, version, repo, dest } => {
            let repo_path = repo.unwrap_or_else(|| PathBuf::from("repo.json"));
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
        Command::Remove { packages } => {
            let install_dir = dirs::home_dir()
                .unwrap()
                .join(".local/share/bedepacko/installed");
            for pkg in packages {
                let pkg_path = install_dir.join(&pkg);
                if pkg_path.exists() {
                    std::fs::remove_dir_all(&pkg_path)?;
                    println!("Removed: {}", pkg);
                } else {
                    eprintln!("Package not installed: {}", pkg);
                }
            }
        }
        Command::List => {
            let install_dir = dirs::home_dir()
                .unwrap()
                .join(".local/share/bedepacko/installed");
            if install_dir.exists() {
                for entry in std::fs::read_dir(install_dir)? {
                    let entry = entry?;
                    println!("{}", entry.file_name().to_string_lossy());
                }
            } else {
                println!("No packages installed.");
            }
        }
    }
    Ok(())
}
