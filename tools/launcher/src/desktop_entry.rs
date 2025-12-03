use anyhow::Result;
use configparser::ini::Ini;
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};

#[derive(Clone, Debug)]
pub struct DesktopEntry {
    pub name: String,
    pub comment: String,
    pub icon: String,
    pub exec: String,
    pub categories: Vec<String>,
    pub terminal: bool,
}

impl DesktopEntry {
    pub fn from_file(path: &Path) -> Result<Self> {
        let mut conf = Ini::new();
        conf.load(path.to_str().unwrap())
            .map_err(|e| anyhow::anyhow!("Failed to load desktop file: {}", e))?;
        
        let section_name = "Desktop Entry";
        if conf.get(section_name, "NoDisplay").unwrap_or(String::from("false")) == "true" {
            return Err(anyhow::anyhow!("NoDisplay is true"));
        }

        let name = conf.get(section_name, "Name").unwrap_or(String::from(""));
        if name.is_empty() {
            return Err(anyhow::anyhow!("No name"));
        }

        let comment = conf.get(section_name, "Comment").unwrap_or(String::from(""));
        let icon = conf.get(section_name, "Icon").unwrap_or(String::from(""));
        let exec = conf.get(section_name, "Exec").unwrap_or(String::from(""));
        
        let categories_str = conf.get(section_name, "Categories").unwrap_or(String::from(""));
        let categories = categories_str
            .split(';')
            .filter(|s| !s.is_empty())
            .map(|s| s.to_string())
            .collect();

        let terminal = conf.get(section_name, "Terminal").unwrap_or(String::from("false")) == "true";

        Ok(DesktopEntry {
            name,
            comment,
            icon,
            exec,
            categories,
            terminal,
        })
    }
}

pub fn load_desktop_entries() -> Result<Vec<DesktopEntry>> {
    let home = std::env::var("HOME")?;
    let search_paths = vec![
        PathBuf::from("/usr/share/applications"),
        PathBuf::from("/usr/local/share/applications"),
        PathBuf::from(format!("{}/.local/share/applications", home)),
    ];

    let mut entries = Vec::new();

    for path in search_paths {
        if !path.exists() {
            continue;
        }

        if let Ok(dir_entries) = fs::read_dir(&path) {
            for entry in dir_entries.flatten() {
                let path = entry.path();
                // Only look at launcher-*.desktop files
                if let Some(filename) = path.file_name().and_then(|n| n.to_str()) {
                    if filename.starts_with("launcher-") && filename.ends_with(".desktop") {
                        if let Ok(desktop_entry) = DesktopEntry::from_file(&path) {
                            entries.push(desktop_entry);
                        }
                    }
                }
            }
        }
    }

    Ok(entries)
}

/// Map freedesktop.org categories to display names
fn map_category_display(category: &str) -> String {
    match category {
        "Office" => "Thinking".to_string(),
        "Utility" => "File Openers".to_string(),
        "Game" => "Games".to_string(),
        "Graphics" => "Art".to_string(),
        "Video" => "Video Editing".to_string(),
        "Audio" => "Music".to_string(),
        "Development" => "Programming".to_string(),
        "Education" => "World Knowledge".to_string(),
        _ => category.to_string(),
    }
}

pub fn categorize_entries(entries: Vec<DesktopEntry>) -> HashMap<String, Vec<DesktopEntry>> {
    let mut categorized: HashMap<String, Vec<DesktopEntry>> = HashMap::new();

    for entry in entries {
        if entry.categories.is_empty() {
            categorized
                .entry("Other".to_string())
                .or_insert_with(Vec::new)
                .push(entry);
        } else {
            for cat in &entry.categories {
                // Map to display name
                let display_name = map_category_display(cat);
                categorized
                    .entry(display_name)
                    .or_insert_with(Vec::new)
                    .push(entry.clone());
            }
        }
    }

    // Sort apps alphabetically within each category
    for apps in categorized.values_mut() {
        apps.sort_by(|a, b| a.name.to_lowercase().cmp(&b.name.to_lowercase()));
    }

    categorized
}
