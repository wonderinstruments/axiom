mod desktop_entry;
mod icon_finder;

use anyhow::Result;
use crossterm::{
    event::{self, DisableMouseCapture, EnableMouseCapture, Event, KeyCode},
    execute,
    terminal::{disable_raw_mode, enable_raw_mode, EnterAlternateScreen, LeaveAlternateScreen},
};
use desktop_entry::{categorize_entries, load_desktop_entries, DesktopEntry};
use icon_finder::find_icon;
use ratatui::{
    backend::CrosstermBackend,
    layout::{Constraint, Direction, Layout, Rect},
    style::{Color, Modifier, Style},
    widgets::{Block, Borders, List, ListItem, ListState, Paragraph},
    Frame, Terminal,
};
use ratatui_image::{
    picker::Picker,
    protocol::StatefulProtocol,
    StatefulImage,
    Resize,
    FilterType,
};
use std::collections::HashMap;
use std::io;
use std::os::unix::process::CommandExt;
use std::path::Path;
use std::process::Command;

#[derive(PartialEq)]
enum Pane {
    Categories,
    Apps,
}

struct App {
    categories: Vec<String>,
    categorized_apps: HashMap<String, Vec<DesktopEntry>>,
    category_state: ListState,
    app_state: ListState,
    focused_pane: Pane,
    picker: Picker,
    icon_states: HashMap<String, StatefulProtocol>,
}

impl App {
    fn new(entries: Vec<DesktopEntry>) -> Result<Self> {
        let categorized_apps = categorize_entries(entries);
        let mut categories: Vec<String> = categorized_apps.keys().cloned().collect();
        categories.sort();

        let mut category_state = ListState::default();
        category_state.select(Some(0));

        // Query terminal for font size and graphics protocol via stdio
        let picker = Picker::from_query_stdio()
            .unwrap_or_else(|_| Picker::from_fontsize((8, 16)));

        Ok(Self {
            categories,
            categorized_apps,
            category_state,
            app_state: ListState::default(),
            focused_pane: Pane::Categories,
            picker,
            icon_states: HashMap::new(),
        })
    }

    fn get_current_apps(&self) -> Option<&Vec<DesktopEntry>> {
        let selected = self.category_state.selected()?;
        let category = self.categories.get(selected)?;
        self.categorized_apps.get(category)
    }


    fn next_category(&mut self) {
        let i = match self.category_state.selected() {
            Some(i) => {
                if i >= self.categories.len() - 1 {
                    i
                } else {
                    i + 1
                }
            }
            None => 0,
        };
        self.category_state.select(Some(i));
        // Don't pre-select app if we're not in apps pane
        if self.focused_pane == Pane::Apps {
            self.app_state.select(Some(0));
        }
    }

    fn previous_category(&mut self) {
        let i = match self.category_state.selected() {
            Some(i) => {
                if i == 0 {
                    0
                } else {
                    i - 1
                }
            }
            None => 0,
        };
        self.category_state.select(Some(i));
        // Don't pre-select app if we're not in apps pane
        if self.focused_pane == Pane::Apps {
            self.app_state.select(Some(0));
        }
    }

    fn next_app(&mut self) {
        if let Some(apps) = self.get_current_apps() {
            let i = match self.app_state.selected() {
                Some(i) => {
                    if i >= apps.len() - 1 {
                        i
                    } else {
                        i + 1
                    }
                }
                None => 0,
            };
            self.app_state.select(Some(i));
        }
    }

    fn previous_app(&mut self) {
        if let Some(_apps) = self.get_current_apps() {
            let i = match self.app_state.selected() {
                Some(i) => {
                    if i == 0 {
                        0
                    } else {
                        i - 1
                    }
                }
                None => 0,
            };
            self.app_state.select(Some(i));
        }
    }

    fn launch_selected(&self) -> bool {
        if let Some(apps) = self.get_current_apps() {
            if let Some(selected) = self.app_state.selected() {
                if let Some(app) = apps.get(selected) {
                    return launch_app(&app.exec, app.terminal);
                }
            }
        }
        false
    }
}

fn get_next_empty_workspace() -> u32 {
    // Get occupied workspaces from i3
    let output = Command::new("i3-msg")
        .args(["-t", "get_workspaces"])
        .output();

    if let Ok(output) = output {
        if let Ok(json_str) = String::from_utf8(output.stdout) {
            // Parse workspace numbers (simple approach without serde_json)
            let mut occupied = Vec::new();
            for num in 1..=10 {
                if json_str.contains(&format!("\"num\":{}", num)) {
                    occupied.push(num);
                }
            }

            // Find first empty workspace
            for i in 1..=10 {
                if !occupied.contains(&i) {
                    return i;
                }
            }

            // All 1-10 occupied, use next one
            return occupied.iter().max().unwrap_or(&10) + 1;
        }
    }

    // Fallback to workspace 1
    1
}

fn load_image_from_path(path: &Path) -> Result<image::DynamicImage> {
    // Check if it's an SVG file
    if let Some(ext) = path.extension() {
        if ext.eq_ignore_ascii_case("svg") || ext.eq_ignore_ascii_case("svgz") {
            // Load and render SVG
            let svg_data = std::fs::read(path)?;
            let opt = usvg::Options::default();
            let tree = usvg::Tree::from_data(&svg_data, &opt)
                .map_err(|e| anyhow::anyhow!("Failed to parse SVG: {}", e))?;
            
            let size = tree.size();
            let width = size.width() as u32;
            let height = size.height() as u32;
            
            // Render to a pixmap
            let mut pixmap = tiny_skia::Pixmap::new(width, height)
                .ok_or_else(|| anyhow::anyhow!("Failed to create pixmap"))?;
            
            resvg::render(&tree, tiny_skia::Transform::default(), &mut pixmap.as_mut());
            
            // Convert to image::DynamicImage
            let img = image::RgbaImage::from_raw(width, height, pixmap.take())
                .ok_or_else(|| anyhow::anyhow!("Failed to convert pixmap to image"))?;
            
            return Ok(image::DynamicImage::ImageRgba8(img));
        }
    }
    
    // For non-SVG files, use image::open
    Ok(image::open(path)?)
}

fn launch_app(exec: &str, terminal: bool) -> bool {
    // Parse exec string and remove field codes
    let parts: Vec<&str> = exec.split_whitespace().collect();
    if parts.is_empty() {
        return false;
    }

    let clean_parts: Vec<&str> = parts
        .iter()
        .filter(|p| !p.starts_with('%'))
        .copied()
        .collect();

    if clean_parts.is_empty() {
        return false;
    }

    if terminal {
        // For terminal apps, exec in the same terminal by using shell exec
        // This replaces the current process
        let cmd = clean_parts.join(" ");
        let _ = Command::new("sh")
            .args(["-c", &format!("exec {}", cmd)])
            .exec();
        // If exec returns, it failed, but we still want to exit
        true
    } else {
        // Get next empty workspace
        let workspace = get_next_empty_workspace();

        // Launch in new workspace using i3-msg, detached from terminal
        let cmd = clean_parts.join(" ");
        let _ = Command::new("i3-msg")
            .args([
                &format!("workspace number {}; exec {}", workspace, cmd)
            ])
            .stdin(std::process::Stdio::null())
            .stdout(std::process::Stdio::null())
            .stderr(std::process::Stdio::null())
            .spawn();
        false
    }
}

fn main() -> Result<()> {
    // Load desktop entries
    let entries = load_desktop_entries()?;
    let mut app = App::new(entries)?;

    // Setup terminal
    enable_raw_mode()?;
    let mut stdout = io::stdout();
    execute!(stdout, EnterAlternateScreen, EnableMouseCapture)?;
    let backend = CrosstermBackend::new(stdout);
    let mut terminal = Terminal::new(backend)?;

    let res = run_app(&mut terminal, &mut app);

    // Restore terminal
    disable_raw_mode()?;
    execute!(
        terminal.backend_mut(),
        LeaveAlternateScreen,
        DisableMouseCapture
    )?;
    terminal.show_cursor()?;

    if let Err(err) = res {
        println!("Error: {:?}", err);
    }

    Ok(())
}

fn run_app<B: ratatui::backend::Backend>(
    terminal: &mut Terminal<B>,
    app: &mut App,
) -> Result<()> {
    loop {
        terminal.draw(|f| ui(f, app))?;

        if let Event::Key(key) = event::read()? {
            match key.code {
                KeyCode::Char('q') => return Ok(()),
                KeyCode::Char('j') | KeyCode::Down => {
                    if app.focused_pane == Pane::Categories {
                        app.next_category();
                    } else {
                        app.next_app();
                    }
                }
                KeyCode::Char('k') | KeyCode::Up => {
                    if app.focused_pane == Pane::Categories {
                        app.previous_category();
                    } else {
                        app.previous_app();
                    }
                }
                KeyCode::Char('l') | KeyCode::Right => {
                    if app.focused_pane == Pane::Categories {
                        if let Some(apps) = app.get_current_apps() {
                            if !apps.is_empty() {
                                app.focused_pane = Pane::Apps;
                                app.app_state.select(Some(0));
                            }
                        }
                    }
                }
                KeyCode::Char('h') | KeyCode::Left => {
                    if app.focused_pane == Pane::Apps {
                        app.focused_pane = Pane::Categories;
                        app.app_state.select(None);
                    }
                }
                KeyCode::Enter => {
                    if app.focused_pane == Pane::Apps {
                        if app.get_current_apps().is_some() && app.app_state.selected().is_some() {
                            let should_exit = app.launch_selected();
                            if should_exit {
                                // Exit the TUI before executing terminal app
                                return Ok(());
                            }
                            // For GUI apps, also exit after launching
                            return Ok(());
                        }
                    }
                }
                _ => {}
            }
        }
    }
}

fn ui(f: &mut Frame, app: &mut App) {
    let chunks = Layout::default()
        .direction(Direction::Vertical)
        .constraints([Constraint::Min(0), Constraint::Length(1)])
        .split(f.area());

    let main_chunks = Layout::default()
        .direction(Direction::Horizontal)
        .constraints([Constraint::Percentage(30), Constraint::Percentage(70)])
        .split(chunks[0]);

    // Categories pane
    let categories: Vec<ListItem> = app
        .categories
        .iter()
        .map(|cat| ListItem::new(cat.as_str()))
        .collect();

    let categories_block = Block::default()
        .title("Categories")
        .borders(Borders::ALL)
        .border_style(if app.focused_pane == Pane::Categories {
            Style::default().fg(Color::Blue)
        } else {
            Style::default().fg(Color::DarkGray)
        });

    let categories_list = List::new(categories)
        .block(categories_block)
        .highlight_style(Style::default().bg(Color::DarkGray).add_modifier(Modifier::BOLD))
        .highlight_symbol("> ");

    f.render_stateful_widget(categories_list, main_chunks[0], &mut app.category_state);

    // Apps pane
    render_apps_pane(f, app, main_chunks[1]);

    // Help text (using base16 green for visibility)
    let help = Paragraph::new("j/k: navigate • h/l: switch panes • enter: launch • q: quit")
        .style(Style::default().fg(Color::Green));
    f.render_widget(help, chunks[1]);
}

fn render_apps_pane(f: &mut Frame, app: &mut App, area: Rect) {
    let apps_block = Block::default()
        .title("Applications")
        .borders(Borders::ALL)
        .border_style(if app.focused_pane == Pane::Apps {
            Style::default().fg(Color::Blue)
        } else {
            Style::default().fg(Color::DarkGray)
        });

    let inner_area = apps_block.inner(area);
    f.render_widget(apps_block, area);

    if let Some(apps) = app.get_current_apps() {
        if apps.is_empty() {
            return;
        }

        // Clone the apps to avoid borrow checker issues
        let apps_clone = apps.clone();

        // Calculate how many apps we can show and where to start
        let selected = app.app_state.selected();
        let icon_height = 4; // Height per app (icon + text, no extra space)
        let available_height = inner_area.height as usize;
        let max_visible = available_height / icon_height;
        
        let start_idx = if let Some(sel) = selected {
            if sel >= max_visible {
                sel - max_visible + 1
            } else {
                0
            }
        } else {
            0
        };
        let end_idx = (start_idx + max_visible).min(apps_clone.len());

        // Calculate scroll indicator position
        let total_items = apps_clone.len();
        let scroll_area_height = inner_area.height.saturating_sub(2) as usize;
        let scrollbar_height = if total_items > max_visible {
            (scroll_area_height * max_visible / total_items).max(1)
        } else {
            scroll_area_height
        };
        let scrollbar_position = if total_items > max_visible {
            (scroll_area_height * start_idx / total_items).min(scroll_area_height - scrollbar_height)
        } else {
            0
        };

        // Reserve space for scroll indicator (2 columns on the right)
        let content_width = inner_area.width.saturating_sub(2);
        let mut current_y = inner_area.y + 1; // Add top padding
        
        for (idx, app_entry) in apps_clone.iter().enumerate().skip(start_idx).take(end_idx - start_idx) {
            if current_y >= inner_area.y + inner_area.height {
                break;
            }

            let is_selected = selected.is_some() && idx == selected.unwrap();

            // Draw selection border first so icon/text can overlap its top edge
            if is_selected {
                let border_area = Rect {
                    x: inner_area.x + 1,
                    y: current_y,
                    width: content_width.saturating_sub(2),
                    height: 4,
                };
                let selection_border = Block::default()
                    .borders(Borders::ALL)
                    .border_style(Style::default().fg(Color::Magenta));
                f.render_widget(selection_border, border_area);
            }

            // Icon area (4x4 cells for better visibility) with left padding
            let icon_area = Rect {
                x: inner_area.x + 2,
                y: current_y,
                width: 6,
                height: 4,
            };


            // Load and render icon if available
            if !app_entry.icon.is_empty() {
                if let Some(icon_path) = find_icon(&app_entry.icon) {
                    // Load icon into state if not already loaded
                    if !app.icon_states.contains_key(&app_entry.icon) {
                        if let Ok(img) = load_image_from_path(&icon_path) {
                            let protocol = app.picker.new_resize_protocol(img);
                            app.icon_states.insert(app_entry.icon.clone(), protocol);
                        }
                    }

                    // Render icon
                    if let Some(icon_state) = app.icon_states.get_mut(&app_entry.icon) {
                        // Use a higher-quality downscaling filter so icons look less blocky
                        let image = StatefulImage::new()
                            .resize(Resize::Fit(Some(FilterType::Lanczos3)));
                        f.render_stateful_widget(image, icon_area, icon_state);
                    }
                }
            }

            // Render text components separately to avoid overwriting the top border
            // with empty space
            
            // 1. Render Title (Name)
            let name = app_entry.name.as_str();
            let name_width = name.len() as u16;
            let max_width = content_width.saturating_sub(11);
            let actual_name_width = name_width.min(max_width);
            
            let name_area = Rect {
                x: inner_area.x + 9,
                y: current_y,
                width: actual_name_width,
                height: 1,
            };
            
            let style = if is_selected {
                Style::default().fg(Color::White).add_modifier(Modifier::BOLD)
            } else {
                Style::default().fg(Color::White)
            };
            
            f.render_widget(Paragraph::new(name).style(style), name_area);
            
            // 2. Render Comment (Description)
            if !app_entry.comment.is_empty() {
                let comment_area = Rect {
                    x: inner_area.x + 9,
                    y: current_y + 1,
                    width: max_width,
                    height: 2, // Use remaining 2 lines
                };
                // Use default style for comment
                 let comment_style = if is_selected {
                    Style::default().fg(Color::White).add_modifier(Modifier::BOLD)
                } else {
                    Style::default().fg(Color::White)
                };
                f.render_widget(Paragraph::new(app_entry.comment.as_str()).style(comment_style), comment_area);
            }

            current_y += icon_height as u16;
        }

        // Draw scroll indicator on the right side
        if total_items > max_visible {
            let scrollbar_x = inner_area.x + inner_area.width - 1;
            for i in 0..scroll_area_height {
                let y = inner_area.y + 1 + i as u16;
                let symbol = if i >= scrollbar_position && i < scrollbar_position + scrollbar_height {
                    "█"
                } else {
                    "│"
                };
                let style = if i >= scrollbar_position && i < scrollbar_position + scrollbar_height {
                    Style::default().fg(Color::Blue)
                } else {
                    Style::default().fg(Color::DarkGray)
                };
                f.render_widget(Paragraph::new(symbol).style(style), Rect {
                    x: scrollbar_x,
                    y,
                    width: 1,
                    height: 1,
                });
            }
        }
    } else {
        let no_apps = Paragraph::new("No applications")
            .style(Style::default().fg(Color::DarkGray));
        f.render_widget(no_apps, inner_area);
    }
}
