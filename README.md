# Sci_NpcManager

Ambient population control for FiveM: pedestrians, traffic, parked cars, police,
trains, boats and wildlife. Lower it, raise it, turn it off, or clear what has
already spawned, from an in-game panel or the console.

Runs on ESX, QBCore, Qbox or no framework at all. Requires `ox_lib`.

## Install

```cfg
ensure ox_lib
ensure Sci_NpcManager
add_ace group.admin sci_npc.admin allow
```

Add your identifier to `Config.Owners` in `config/config_server.lua`.

## Commands

| Command | |
|---|---|
| `/scinpc` | Open the panel |
| `/scinpc on` / `off` | Master switch |
| `/scinpc peds <0-3>` | Also `scenarios`, `vehicles`, `parked`, `all` |
| `/scinpc cops off` | Also `garbage`, `boats`, `trains`, `wildlife` |
| `/scinpc purge on` | Keep deleting ambient peds; `purgecars` for traffic |
| `/scinpc preset <id>` | `empty`, `nopeds`, `low`, `normal`, `busy` |
| `/scinpc clear` | Sweep once on every client |
| `/scinpc reset` | Back to `Config.Defaults` |
| `/scinpc status` | Print current settings |

Players without permission get no response. All commands work from the console.

## Density and sweep

Density only affects what spawns next. Sweep deletes what is already out.
To empty the city right away you need both, which is what the `empty` preset does.

A sweep never removes players, script-created peds, player vehicles, models in
`Config.ProtectedModels`, anything inside `Config.ProtectedZones`, or entities
flagged with the `sciNpcProtected` state bag.

## Permissions

The console and `Config.Owners` always pass. Everyone else goes through
`Config.Permissions.providers` in order:

| Provider | Passes when |
|---|---|
| `sci_admin` | Sci_Adminmenu allows the mapped node. While it runs, its answer is final |
| `ace` | The player has `sci_npc.admin` |
| `group` | The player's framework group is listed |
| `custom` | Your function returns `true` |

## Exports

Server:

```lua
exports.Sci_NpcManager:GetSettings()
exports.Sci_NpcManager:GetFactor()
exports.Sci_NpcManager:SetSettings({ peds = 0.0, purge = true })
exports.Sci_NpcManager:SetPreset('empty')
exports.Sci_NpcManager:SetEnabled(false)
exports.Sci_NpcManager:PurgeNow()
```

Client:

```lua
exports.Sci_NpcManager:GetSettings()
exports.Sci_NpcManager:SetOverride({ peds = 0.0, purge = true })
exports.Sci_NpcManager:ClearOverride()
exports.Sci_NpcManager:ProtectPed(ped)
exports.Sci_NpcManager:UnprotectPed(ped)
exports.Sci_NpcManager:Sweep()
exports.Sci_NpcManager:LastSweep()
```

Protect a ped from another resource without depending on this one:

```lua
Entity(ped).state:set('sciNpcProtected', true, true)
```
