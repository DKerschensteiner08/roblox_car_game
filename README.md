# Drive-to-Earn Simulator (Roblox)

## Setup
1. Install Rojo from the official releases page.
2. From this repo root, run:
   ```bash
   rojo serve default.project.json
   ```
3. Open Roblox Studio and your place.
4. Open the Rojo plugin and connect to `localhost:34872`.
5. Click `Sync` in the plugin.

## Phase Test Steps

### Phase 0
1. Start `rojo serve default.project.json`.
2. Connect Rojo plugin in Studio.
3. Verify folders map into Explorer: `ReplicatedStorage`, `ServerScriptService`, `StarterPlayer`, `StarterGui`.

### Phase 1
1. Press Play Solo.
2. Confirm no errors in Output.
3. Confirm startup logs from `ServerMain`, `ClientMain`, and `UIController`.
