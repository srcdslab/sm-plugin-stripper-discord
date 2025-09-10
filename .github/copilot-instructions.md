# Copilot Instructions for sm-plugin-stripper-discord

## Repository Overview
This repository contains a SourcePawn plugin for SourceMod that integrates Stripper config error monitoring with Discord webhook notifications. The plugin automatically sends Discord messages when errors are detected while loading Stripper configurations, providing real-time alerts for server administrators.

## Project Purpose
- **Plugin Name**: Stripper Discord
- **Version**: 1.1.2
- **Author**: .Rushaway
- **Functionality**: Sends Discord webhook notifications when Stripper config loading errors occur
- **Platform**: SourceMod 1.11+ for Source engine games

## Dependencies & Requirements
- **SourceMod**: 1.11.0+ (minimum required version)
- **External Plugins Required**:
  - [Stripper plugin](https://github.com/srcdslab/sm-plugin-stripper) - Provides the error callback API
  - [DiscordWebhookAPI](https://github.com/srcdslab/sm-plugin-DiscordWebhookAPI) - Handles Discord webhook communication

## Build System & Tools
- **Primary Build Tool**: SourceKnight (configured via `sourceknight.yaml`)
- **CI/CD**: GitHub Actions using `maxime1907/action-sourceknight@v1`
- **Compiler**: SourcePawn compiler (spcomp) via SourceKnight
- **Package Output**: `.sourceknight/package/` directory
- **Compiled Plugin Output**: `addons/sourcemod/plugins/`

### Build Commands
```bash
# The repository uses SourceKnight for building
# Local builds would use: sourceknight build
# CI builds are automated via GitHub Actions
```

## Project Structure
```
├── addons/sourcemod/scripting/
│   └── Stripper_Discord.sp          # Main plugin source file
├── .github/
│   ├── workflows/ci.yml             # CI/CD pipeline
│   └── dependabot.yml              # Dependency updates
├── sourceknight.yaml               # Build configuration
├── README.md                       # Basic project documentation
└── .gitignore                      # Git ignore rules
```

## SourcePawn Coding Standards (Project Specific)
This project follows strict SourcePawn conventions:

### Code Style
- **Indentation**: 4 spaces (tabs converted to spaces)
- **Variable Naming**:
  - Global variables: Prefix with `g_` (e.g., `g_cvWebhook`)
  - Local variables: camelCase (e.g., `sMessage`, `iTime`)
  - Functions: PascalCase (e.g., `SendWebHook`, `OnWebHookExecuted`)
  - ConVars: Descriptive names with `g_cv` prefix

### Required Pragmas
```sourcepawn
#pragma semicolon 1
#pragma newdecls required
```

### Memory Management
- Always use `delete` for cleanup (no null checks needed)
- Avoid `.Clear()` on StringMap/ArrayList - use `delete` and recreate
- Proper DataPack management with explicit deletion

### Error Handling
- Implement proper error logging with descriptive messages
- Use retry mechanisms for network operations (webhook calls)
- Validate configuration parameters before use

## Key Components & APIs

### ConVar Configuration
The plugin uses several ConVars for configuration:
- `sm_stripper_webhook`: Discord webhook URL (protected)
- `sm_stripper_webhook_retry`: Retry count for failed webhooks
- `sm_stripper_channel_type`: Channel type (0=text, 1=thread)
- `sm_stripper_threadname`: Thread name for forum channels
- `sm_stripper_threadid`: Specific thread ID for messages

### Main Callback
- `Stripper_OnErrorLogged()`: Called by Stripper plugin when errors occur
- Formats error messages with timestamps
- Sanitizes content for Discord (removes quotes)
- Triggers webhook sending with retry logic

### Discord Integration
- Uses DiscordWebhookAPI for webhook communication
- Supports both regular channels and thread-based channels
- Implements retry logic for failed webhook deliveries
- Handles different HTTP response codes appropriately

## Development Guidelines

### When Adding Features
1. Follow existing ConVar naming patterns
2. Implement proper error handling and logging
3. Use DataPack for asynchronous operations if needed
4. Add configuration validation in `OnPluginStart()`
5. Maintain backward compatibility when possible

### Testing Considerations
- Test webhook delivery with both successful and failed scenarios
- Verify retry logic works correctly
- Test with different Discord channel types (text/thread)
- Ensure proper error message formatting

### Common Patterns in This Codebase
```sourcepawn
// ConVar creation with protection
g_cvWebhook = CreateConVar("sm_stripper_webhook", "", "Description", FCVAR_PROTECTED);

// String handling with size safety
char sMessage[WEBHOOK_MSG_MAX_SIZE];
Format(sMessage, sizeof(sMessage), "Format string", args);

// Memory management
DataPack pack = new DataPack();
// ... use pack ...
delete pack;
```

## CI/CD Workflow
- **Triggers**: Push, Pull Request, Manual dispatch
- **Build Process**: Automated via SourceKnight action
- **Artifacts**: Packaged plugins uploaded as build artifacts
- **Releases**: Automatic tagging and release creation
- **Versioning**: Uses semantic versioning with automatic 'latest' tag

## Release Process
1. Code changes trigger CI build
2. Successful builds create artifacts
3. Master/main branch pushes create 'latest' releases
4. Git tags create versioned releases
5. Packages include compiled `.smx` files and directory structure

## External API Dependencies
This plugin relies on external APIs and should be tested against:
- Stripper plugin API changes
- DiscordWebhookAPI updates
- SourceMod API compatibility
- Discord webhook endpoint changes

## Troubleshooting Common Issues
1. **Webhook failures**: Check URL validity and Discord channel permissions
2. **Build failures**: Verify SourceKnight dependencies are available
3. **Plugin loading errors**: Ensure all required dependencies are installed
4. **Thread creation issues**: Validate Discord forum channel permissions

## Performance Considerations
- Webhook calls are asynchronous to prevent server performance impact
- Error message formatting is minimal to reduce string operations
- Retry logic prevents infinite loops with maximum attempt limits
- Memory cleanup is immediate after webhook completion

## Security Notes
- Webhook URLs are marked as FCVAR_PROTECTED
- No sensitive data logging in error messages
- Input sanitization for Discord message content
- No direct file system or database access