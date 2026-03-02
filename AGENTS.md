# AGENTS.md

## Project Rules
- Keep the game playable after every phase.
- Server authoritative for cash, distance, purchases, zone unlocks, rebirth, and saves.
- Never trust client-reported speed, distance, or currency values.
- Keep scripts modular. Avoid giant monolithic files.
- Use `ReplicatedStorage/Modules` for shared config/util modules.
- Use `ServerScriptService/Services` for server systems.
- Use remotes listed in `ReplicatedStorage/Modules/Shared/RemoteNames.lua`.
- Add debug logs only behind config/debug flags when possible.

## Coding Standards
- Luau `--!strict` for all scripts/modules.
- Clear function names and service APIs.
- Keep remote payloads small and explicit.
- Validate all client requests server-side.

## Testing Standard (every phase)
- Play Solo should run with no errors.
- Confirm Output logs startup and key events.
- Confirm no client can directly set server cash/progression.
