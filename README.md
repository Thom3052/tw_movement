## tw_movement

Crouch + first-person combat helper for FiveM. Made by Thom Walnoot. Need help or have questions? Join my (Dutch) Discord; create a ticket and I can assist in English as well.

### What it does
- Toggle crouch (keybind `tw_crouch`, default Left Ctrl; rebind in Settings → Key Bindings → FiveM).
- Force first-person while aiming/shooting; auto-return to third-person afterward.
- Keep crouch movement/strafe/weapon handling while crouched (no pop-up to standing).
- Block monkey-punch/light/heavy melee spam.
- Optional: hide crosshair while aiming; skip forcing FP when unarmed (configurable).

### Installation
1) Place this folder in your server resources: `resources/[local]/tw_movement` (or any folder you prefer).  
2) Add to your `server.cfg`:
```
ensure tw_movement
```
3) Restart/launch the server. In-game, set your preferred keybind for `tw_crouch`.

### Configuration (in `client.lua`)
- `forceThirdViewMode` (default `1`): third-person view to restore after aiming. Use `1` (close), `2` (medium), or `3` (far).  
- `hideReticle` (default `true`): hides crosshair while aiming.  
- `skipFirstPersonWhenUnarmed` (default `true`): do not force FP when unarmed (melee).  
- `autoHolsterWhenNotAiming` (default `false`): set `true` to holster when not aiming (kills idle weapon pose, but hides weapon).  
- `blockRoll` (default `true`): keeps action mode off while crouched and blocks jump/roll/melee in crouch.  
- Keybind: change in-game via Settings → Key Bindings → FiveM → `tw_crouch`.

### How it works (runtime behavior)
- Holding aim/shoot forces first-person each frame. Releasing aim restores the chosen third-person view (and keeps enforcing TP briefly after release to avoid stickiness).  
- While crouched, crouch clipsets are re-applied so GTA does not revert to a standing pose after aiming/holstering.  
- Monkey-punch controls (140/141/142) are disabled; jump blocked while crouched.  
- Optional crosshair hide runs while aiming; unarmed can be excluded from FP forcing.

### Controls
- `tw_crouch`: toggle crouch (default Left Ctrl; user-rebindable).  
- Aim/shoot: forces FP (except when unarmed if configured). Let go to return to TP.

### Support
- Questions/bugs? Reach out in my Discord (Dutch server; open a ticket for English help).
https://discord.gg/v7X5fEz7XS
- Please include: server build, other camera/animation resources running, and whether you use keyboard or controller.


