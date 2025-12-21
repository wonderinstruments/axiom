use anyhow::{Context, Result};
use hocon::HoconLoader;
use serde_json::Value as JsonValue;

/// Parse HOCON content and convert to JSON
pub fn hocon_to_json(hocon_content: &str) -> Result<JsonValue> {
    let hocon = HoconLoader::new()
        .load_str(hocon_content)
        .context("Failed to parse HOCON")?
        .hocon()
        .context("Failed to resolve HOCON")?;
    
    hocon_value_to_json(&hocon)
}

fn hocon_value_to_json(value: &hocon::Hocon) -> Result<JsonValue> {
    match value {
        hocon::Hocon::Null => Ok(JsonValue::Null),
        hocon::Hocon::Boolean(b) => Ok(JsonValue::Bool(*b)),
        hocon::Hocon::Integer(i) => Ok(JsonValue::Number((*i).into())),
        hocon::Hocon::Real(f) => {
            let n = serde_json::Number::from_f64(*f)
                .context("Invalid float value")?;
            Ok(JsonValue::Number(n))
        }
        hocon::Hocon::String(s) => Ok(JsonValue::String(s.clone())),
        hocon::Hocon::Array(arr) => {
            let values: Result<Vec<JsonValue>> = arr.iter()
                .map(hocon_value_to_json)
                .collect();
            Ok(JsonValue::Array(values?))
        }
        hocon::Hocon::Hash(map) => {
            let mut obj = serde_json::Map::new();
            for (k, v) in map {
                obj.insert(k.clone(), hocon_value_to_json(v)?);
            }
            Ok(JsonValue::Object(obj))
        }
        hocon::Hocon::BadValue(err) => {
            anyhow::bail!("Invalid HOCON value: {:?}", err)
        }
    }
}

/// Convert JSON to HOCON format string
pub fn json_to_hocon(json: &JsonValue, indent: usize) -> String {
    let indent_str = "  ".repeat(indent);
    let next_indent = "  ".repeat(indent + 1);
    
    match json {
        JsonValue::Null => "null".to_string(),
        JsonValue::Bool(b) => b.to_string(),
        JsonValue::Number(n) => n.to_string(),
        JsonValue::String(s) => format!("\"{}\"", escape_hocon_string(s)),
        JsonValue::Array(arr) => {
            if arr.is_empty() {
                "[]".to_string()
            } else {
                let items: Vec<String> = arr.iter()
                    .map(|v| format!("{}{}", next_indent, json_to_hocon(v, indent + 1)))
                    .collect();
                format!("[\n{}\n{}]", items.join(",\n"), indent_str)
            }
        }
        JsonValue::Object(obj) => {
            if obj.is_empty() {
                "{}".to_string()
            } else {
                let items: Vec<String> = obj.iter()
                    .map(|(k, v)| {
                        let key = if needs_quoting(k) {
                            format!("\"{}\"", k)
                        } else {
                            k.clone()
                        };
                        format!("{}{} = {}", next_indent, key, json_to_hocon(v, indent + 1))
                    })
                    .collect();
                format!("{{\n{}\n{}}}", items.join("\n"), indent_str)
            }
        }
    }
}

fn escape_hocon_string(s: &str) -> String {
    s.replace('\\', "\\\\")
        .replace('"', "\\\"")
        .replace('\n', "\\n")
        .replace('\r', "\\r")
        .replace('\t', "\\t")
}

fn needs_quoting(key: &str) -> bool {
    key.is_empty() 
        || key.contains(|c: char| !c.is_alphanumeric() && c != '_' && c != '-')
        || key.chars().next().map(|c| c.is_numeric()).unwrap_or(false)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_hocon_to_json() {
        let hocon = r#"
            theme {
                colors = "everforest"
                windows {
                    gap.size = 10
                }
            }
        "#;
        
        let json = hocon_to_json(hocon).unwrap();
        assert_eq!(json["theme"]["colors"], "everforest");
        assert_eq!(json["theme"]["windows"]["gap"]["size"], 10);
    }

    #[test]
    fn test_json_to_hocon() {
        let json: JsonValue = serde_json::json!({
            "name": "test",
            "count": 42,
            "enabled": true
        });
        
        let hocon = json_to_hocon(&json, 0);
        assert!(hocon.contains("name = \"test\""));
        assert!(hocon.contains("count = 42"));
        assert!(hocon.contains("enabled = true"));
    }
}
