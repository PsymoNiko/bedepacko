use hex;
use anyhow::Result;
use futures::stream::{self, StreamExt};
use indicatif::{ProgressBar, ProgressStyle};
use reqwest::Client;
use sha2::{Digest, Sha256};
use std::fs::File;
use std::io::Write;
use std::path::Path;

pub async fn download_packages(packages: &[crate::manifest::Package], dest_dir: &Path) -> Result<Vec<String>> {
    let client = Client::new();
    let pb = ProgressBar::new(packages.len() as u64);
    pb.set_style(ProgressStyle::default_bar()
        .template("{spinner:.green} [{elapsed_precise}] [{bar:40.cyan/blue}] {pos}/{len} ({eta})")?
        .progress_chars("#>-"));

    let downloads = stream::iter(packages)
        .map(|pkg| download_one(&client, pkg, dest_dir))
        .buffer_unordered(10); // 10 concurrent downloads

    let results: Vec<_> = downloads.collect().await;
    pb.finish_with_message("all packages downloaded");

    let mut downloaded = Vec::new();
    for res in results {
        downloaded.push(res?);
    }
    Ok(downloaded)
}

async fn download_one(client: &Client, pkg: &crate::manifest::Package, dest_dir: &Path) -> Result<String> {
    let resp = client.get(&pkg.download_url).send().await?;
    let bytes = resp.bytes().await?;
    
    // verify checksum
    let mut hasher = Sha256::new();
    hasher.update(&bytes);
    let hash = hex::encode(hasher.finalize());
    if hash != pkg.sha256 {
        anyhow::bail!("Checksum mismatch for {}", pkg.name);
    }
    
    let path = dest_dir.join(format!("{}-{}.pkg", pkg.name, pkg.version));
    let mut file = File::create(&path)?;
    file.write_all(&bytes)?;
    Ok(path.to_string_lossy().to_string())
}
