use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::{Arc, Mutex};

lazy_static::lazy_static! {
    static ref ICON_CACHE: Arc<Mutex<HashMap<String, Option<PathBuf>>>> = 
        Arc::new(Mutex::new(HashMap::new()));
}

pub fn find_icon(icon_name: &str) -> Option<PathBuf> {
    if icon_name.is_empty() {
        return None;
    }

    // Check cache
    {
        let cache = ICON_CACHE.lock().unwrap();
        if let Some(result) = cache.get(icon_name) {
            return result.clone();
        }
    }

    // If absolute path, return if it exists
    let icon_path = Path::new(icon_name);
    if icon_path.is_absolute() && icon_path.exists() {
        let result = Some(icon_path.to_path_buf());
        ICON_CACHE.lock().unwrap().insert(icon_name.to_string(), result.clone());
        return result;
    }

    // Strip extension if present
    let base_name = icon_path
        .file_stem()
        .and_then(|s| s.to_str())
        .unwrap_or(icon_name);

    // Get icon search paths
    let paths = get_icon_paths();
    
    // Themes in order of preference
    let themes = vec!["Papirus", "Papirus-Dark", "hicolor", "Adwaita", "gnome"];
    
    // Sizes in order of preference
    let sizes = vec!["128x128", "scalable", "64x64", "48x48", "32x32", "24x24", "16x16"];
    
    // Categories
    let categories = vec!["apps", "applications", "places", "devices", "mimetypes", "categories"];
    
    // Extensions
    let extensions = vec!["png", "svg", "xpm"];

    // Search in themes
    for theme in &themes {
        for base_path in &paths {
            let theme_path = base_path.join(theme);
            if !theme_path.exists() {
                continue;
            }

            for size in &sizes {
                for cat in &categories {
                    let search_path = theme_path.join(size).join(cat);
                    
                    for ext in &extensions {
                        let icon_file = search_path.join(format!("{}.{}", base_name, ext));
                        if icon_file.exists() {
                            let result = Some(icon_file);
                            ICON_CACHE.lock().unwrap().insert(icon_name.to_string(), result.clone());
                            return result;
                        }
                    }
                }
            }
        }
    }

    // Try pixmaps (flat structure)
    for base_path in &paths {
        if base_path.to_str().map_or(false, |s| s.contains("pixmaps")) {
            for ext in &extensions {
                let icon_file = base_path.join(format!("{}.{}", base_name, ext));
                if icon_file.exists() {
                    let result = Some(icon_file);
                    ICON_CACHE.lock().unwrap().insert(icon_name.to_string(), result.clone());
                    return result;
                }
            }
        }
    }

    // Not found
    ICON_CACHE.lock().unwrap().insert(icon_name.to_string(), None);
    None
}

fn get_icon_paths() -> Vec<PathBuf> {
    let mut paths = Vec::new();

    // User local icons
    if let Ok(home) = std::env::var("HOME") {
        paths.push(PathBuf::from(format!("{}/.local/share/icons", home)));
        paths.push(PathBuf::from(format!("{}/.icons", home)));
    }

    // XDG_DATA_DIRS
    if let Ok(xdg_data_dirs) = std::env::var("XDG_DATA_DIRS") {
        for dir in xdg_data_dirs.split(':') {
            if !dir.is_empty() {
                paths.push(PathBuf::from(dir).join("icons"));
                paths.push(PathBuf::from(dir).join("pixmaps"));
            }
        }
    }

    // Standard paths
    paths.push(PathBuf::from("/usr/share/icons"));
    paths.push(PathBuf::from("/usr/local/share/icons"));
    paths.push(PathBuf::from("/usr/share/pixmaps"));

    paths
}
