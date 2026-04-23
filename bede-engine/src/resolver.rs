use crate::manifest::{Package, PackageDb};
use anyhow::{anyhow, Result};
use petgraph::graph::DiGraph;
use std::collections::HashMap;

pub fn resolve(pkg_name: &str, db: &PackageDb, preferred_version: &str) -> Result<Vec<Package>> {
    let mut graph = DiGraph::<String, ()>::new();
    let mut node_indices = HashMap::<String, petgraph::graph::NodeIndex>::new();

    fn add_package(
        pkg: &Package,
        db: &PackageDb,
        graph: &mut DiGraph<String, ()>,
        indices: &mut HashMap<String, petgraph::graph::NodeIndex>,
    ) -> Result<()> {
        if indices.contains_key(&pkg.name) {
            return Ok(());
        }
        let node_idx = graph.add_node(pkg.name.clone());
        indices.insert(pkg.name.clone(), node_idx);

        for dep_name in pkg.dependencies.keys() {
            let dep_pkg = db.resolve_best_match(dep_name, "latest")?;
            add_package(&dep_pkg, db, graph, indices)?;
            let dep_idx = *indices.get(dep_name).unwrap();
            graph.add_edge(node_idx, dep_idx, ());
        }
        Ok(())
    }

    let root = db.resolve_best_match(pkg_name, preferred_version)?;
    add_package(&root, db, &mut graph, &mut node_indices)?;

    let sorted = petgraph::algo::toposort(&graph, None)
        .map_err(|_| anyhow!("Circular dependency detected"))?;

    let mut result = Vec::new();
    for node_idx in sorted {
        let name = &graph[node_idx];
        let pkg = db.resolve_best_match(name, "latest")?;
        result.push(pkg);
    }
    Ok(result)
}

impl PackageDb {
    pub(crate) fn resolve_best_match(&self, name: &str, version_req: &str) -> Result<Package> {
        let versions = self.packages.get(name)
            .ok_or_else(|| anyhow!("Package not found: {}", name))?;
        let pkg = if version_req == "latest" {
            versions.last().unwrap()
        } else {
            versions.iter().find(|p| p.version == version_req)
                .ok_or_else(|| anyhow!("Version {} of {} not found", version_req, name))?
        };
        Ok(pkg.clone())
    }
}
