use dirs;
use std::path::PathBuf;

pub fn get_cli_config_dir() -> crate::Result<PathBuf> {
    if let Ok(config_dir) = std::env::var("ENTE_CLI_CONFIG_DIR") {
        return Ok(PathBuf::from(config_dir));
    }

    // Use platform-specific config directory
    // On Linux: ~/.config/ente-cli
    // On macOS: ~/Library/Application Support/ente-cli
    // On Windows: %APPDATA%/ente-cli
    let config_dir = dirs::config_dir()
        .ok_or_else(|| crate::Error::Generic("Could not determine config directory".into()))?;

    let cli_path = config_dir.join("ente-cli");

    if !cli_path.exists() {
        std::fs::create_dir_all(&cli_path)?;
    }

    Ok(cli_path)
}
