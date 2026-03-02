# Drive-to-Earn Simulator (Roblox)

## Setup
1. Install Rojo from official releases.
2. From this repo root run:
   ```bash
   rojo serve default.project.json
   ```
3. Open Roblox Studio and your place.
4. Open Rojo plugin and connect to `localhost:34872`.
5. Click Sync.

## Phase Testing

### Phase 0
1. Start `rojo serve default.project.json`.
2. Connect plugin.
3. Verify `ReplicatedStorage`, `ServerScriptService`, `StarterPlayer`, `StarterGui` map correctly.

### Phase 1
1. Play Solo.
2. Confirm no errors.
3. Confirm startup logs from server and client scripts.

### Phase 2
1. Play Solo.
2. Car spawns automatically.
3. Drive with seat controls.
4. Press `R` to flip/reset and `T` to respawn.
5. Confirm follow camera tracks car smoothly.

### Phase 3
1. Drive continuously in starter zone.
2. Confirm Cash increases in HUD and leaderstats.
3. Force large position jump in Studio (move car far instantly) and confirm tick is ignored with anti-cheat message.

### Phase 4
1. Drive to earn enough cash for first upgrade.
2. Press `Buy Upgrade`.
3. Confirm server validates purchase (cash deducted, level increases).
4. Confirm insufficient funds shows failure message and no upgrade applied.

### Phase 5
1. Earn enough cash for `desert_runner`.
2. Buy from dealership section.
3. Confirm it becomes owned and equipped.
4. Re-equip between owned cars and verify spawn uses selected car.

### Phase 6
1. Attempt entering locked zone without unlock.
2. Confirm gate/zone access is enforced and you are moved back.
3. Unlock next zone from HUD.
4. Re-enter and confirm higher zone multiplier applies.

### Phase 7
1. In Studio enable API Services for DataStore testing.
2. Earn cash, buy upgrades/cars/zones.
3. Leave and rejoin.
4. Confirm cash, upgrades, owned cars, equipped car, zones, rebirth count restore.
5. If DataStore disabled, confirm warning appears and game still runs.

### Phase 8
1. Earn enough cash for rebirth cost.
2. Press Rebirth once (confirm prompt), then press again.
3. Confirm cash/progression reset and rebirth count increases.
4. Confirm earnings multiplier is permanently higher.

### Phase 9
1. Verify HUD readability with all controls available.
2. Confirm +Cash popups appear while driving.
3. Confirm message panel updates for purchases/unlocks/rebirth.
4. Confirm leaderstats Cash remains visible.

## Notes
- Server remains authoritative for all economy and progression changes.
- Client-only scripts are limited to camera/input/UI effects.
