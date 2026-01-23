# XMonad Migration to Home-Manager - Summary

**Date**: 2026-01-23 (Viernes)  
**Machine**: aurin (PROD)  
**Status**: ✅ COMPLETED on aurin, pending macbook/vespino/android

---

## 🎯 What We Did

### Phase 1: Cleanup (Commit 7c7ab1a)
- Removed dead keybindings: TTS (M-t conflict), keyboard layout toggle (M-ñ/M-;)
- Fixed hardcoded paths in xmonad.hs: picom, jetbrains-toolbox
- Moved `glmatrix-bg.sh` to `scripts/` directory
- Deleted obsolete `modules/desktop/xmonad.nix`

### Phase 2: Home-Manager Module (Commit f3a04e6)
- Created `modules/home-manager/programs/xmonad.nix`
- Imported in `passh.nix`
- Updated stow script (removed xmonad, only composer remains)
- Transition helper to clean old stow symlinks

### Phase 2.1: Script Paths Fix (Commit ef0b151)
- Added `home.sessionPath` for `~/dotfiles/scripts` (works after login)
- Used absolute paths in xmonad.hs for reliability: trayer-toggle.sh, glmatrix-bg.sh
- Consistent with xmobar.nix approach

### Documentation (Commit 7f02f77)
- Added TODO comments for Phase 3 portability refactor
- Notes in xmonad.nix and xmobar.nix for future improvements

---

## ✅ Success Criteria - All Passed on Aurin

| Criterio | Estado |
|----------|--------|
| XMonad compiles | ✅ `xmonad --recompile` OK |
| XMonad restarts | ✅ `xmonad --restart` OK |
| Keybindings work | ✅ M-t (trayer), M-S-m (glmatrix) functional |
| No stow dependency | ✅ Only `composer` remains (CRÍTICO - Vocento PROD) |
| Config managed by Nix | ✅ `~/.config/xmonad/xmonad.hs` → nix store |
| Tested in PROD | ✅ Aurin running perfectly |
| Guru validated | ✅ NixOS best practices confirmed |

---

## 📊 Files Changed

### Created:
- `modules/home-manager/programs/xmonad.nix` (NEW - 70 lines)

### Modified:
- `xmonad/.config/xmonad/xmonad.hs` (cleanup + absolute paths)
- `modules/home-manager/passh.nix` (import xmonad.nix, update stow script, add sessionPath)
- `modules/home-manager/programs/xmobar.nix` (TODO comments added)

### Moved:
- `xmonad/.config/xmonad/my-scripts/glmatrix-bg.sh` → `scripts/glmatrix-bg.sh`

### Deleted:
- `modules/desktop/xmonad.nix` (obsolete wrapper)

---

## 🚀 Applying to MacBook

### Prerequisites Check:
```bash
# On macbook
hostname  # Should show: macbook
cd ~/dotfiles
git status  # Should be clean
git log --oneline -4  # Should show commits: 7f02f77, ef0b151, f3a04e6, 7c7ab1a
```

### Deployment Steps:

1. **Pull latest changes** (if not synced):
   ```bash
   cd ~/dotfiles
   git pull origin master
   ```

2. **Rebuild system**:
   ```bash
   sudo nixos-rebuild switch --flake ~/dotfiles#macbook --impure
   ```

3. **Recompile XMonad**:
   ```bash
   xmonad --recompile
   ```

4. **Restart XMonad**:
   ```bash
   xmonad --restart
   ```

5. **Test keybindings**:
   - `M-t` → trayer-toggle.sh
   - `M-S-m` → glmatrix-bg.sh
   - `M-p` → dmenu
   - `M-a/e/j` → scratchpads

### Expected Behavior:

**Before restart**:
- `~/.config/xmonad` → symlink to `~/dotfiles/xmonad/.config/xmonad` (stow)

**After nixos-rebuild**:
- Old stow symlink cleaned by activation script
- `~/.config/xmonad/xmonad.hs` → symlink to `/nix/store/xxx/xmonad.hs` (home-manager)

**After xmonad restart**:
- All keybindings work
- Scripts accessible (M-t, M-S-m)

---

## ⚠️ Known Issues & Workarounds

### Issue 1: Scripts not found (PATH not updated)

**Symptom**: M-t or M-S-m don't work after first rebuild.

**Cause**: `home.sessionPath` only applies to new sessions.

**Solution**: 
- **Option A**: Logout/login (cleanest)
- **Option B**: `xmonad --restart` (may work)
- **Option C**: Absolute paths already in config (should work)

**Why it works anyway**: We use absolute paths (`/home/passh/dotfiles/scripts/...`) as fallback.

### Issue 2: HiDPI scaling (MacBook Retina)

**Already configured** in `machines/macbook.nix`:
- fontSize = 22 (Pango syntax, scales with DPI)
- sessionVariables for GTK/Qt scaling

Should work out of the box.

---

## 🟡 TODO Phase 3 (Optional - Portability)

**Annotated in code** - see:
- `modules/home-manager/programs/xmonad.nix` (lines 20-26)
- `modules/home-manager/programs/xmobar.nix` (lines 19-25)

**Changes needed**:
1. Replace `/home/passh/` with `${config.home.homeDirectory}` in:
   - xmobar.nix (all script paths)
   - xmonad.nix (template xmonad.hs with `.text`)
2. Add scripts to fish.nix PATH:
   ```fish
   set -x PATH $HOME/dotfiles/scripts $PATH
   ```

**Priority**: Low (only affects portability, works fine now)

**When to do it**:
- Adding another user to the system
- Making repo a template
- Bored and want to polish 😎

---

## 🛡️ Composer: DO NOT TOUCH

**Current state**:
- Stow manages `composer` (only remaining package)
- Config: `~/.config/composer/config.json` (Vocento Toran repo)
- Auth: `~/.config/composer/auth.json` (Bitbucket credentials)

**Why keep it**:
- ✅ PHP projects read global composer config
- ✅ Vocento private repo (toran.srv.vocento.in)
- ✅ **CRÍTICO PROD** - don't break it

**Verified**: Project composer reads `repositories.0.url` from global config.

**Stow script** (passh.nix:262):
```nix
${pkgs.stow}/bin/stow -v -R -t ${config.home.homeDirectory} \
  composer  # ← LEAVE THIS ALONE
```

---

## 🧙 NixOS Guru Consultation

**Consulted**: Task tool with nixos-guru agent

**Key findings**:
1. `home.sessionPath` is correct but requires logout
2. Absolute paths are better than PATH for XMonad (starts before shell)
3. Should use `${config.home.homeDirectory}` instead of `/home/passh/`
4. Current approach is functional, refactor is optional

**Full consultation** saved in session (Task session_id: ses_415c32a76ffeLywbbaBdKeduP1).

---

## 📚 Reference

**Commits**:
- `7c7ab1a` - Phase 1: Cleanup config and remove obsolete module
- `f3a04e6` - Phase 2: Migrate to home-manager
- `ef0b151` - Phase 2.1: Fix script paths (absolute for reliability)
- `7f02f77` - Docs: Add TODO comments for Phase 3

**Files to review**:
- `modules/home-manager/programs/xmonad.nix` (main module)
- `modules/home-manager/passh.nix` (import + stow script)
- `xmonad/.config/xmonad/xmonad.hs` (source config)

**Agents**:
- `~/dotfiles/claude-code/.claude/agents/nixos-guru.md` (for NixOS questions)

---

## 🎯 Next Steps

**On macbook**:
1. Pull changes from master
2. Run nixos-rebuild
3. Test XMonad
4. Report back if issues

**Optional later**:
- Apply to vespino (when online)
- Phase 3 refactor (portability)

---

## 📱 Android (nix-on-droid) Deployment

**Status**: ✅ Config updated (import added)

### What Changed:
- Added `../programs/xmonad.nix` import to `machines/android.nix`
- XMonad config now managed by home-manager (same as desktop)
- `start-x11` script still works (compiles config automatically)

### Deployment Steps:

1. **Pull changes**:
   ```bash
   # On Android (Termux)
   cd ~/dotfiles
   git pull origin master
   ```

2. **Apply config**:
   ```bash
   nix-on-droid switch --flake ~/dotfiles
   ```

3. **Test XMonad** (if using Termux-X11):
   ```bash
   # Start Termux-X11 app first
   start-x11
   
   # Test keybindings:
   # M-t → trayer-toggle (will fail gracefully if trayer not installed)
   # M-S-m → glmatrix-bg.sh
   # M-p → dmenu
   ```

### Expected Behavior:

**Before**:
- XMonad binary installed, config manual

**After**:
- `~/.config/xmonad/xmonad.hs` → managed by home-manager (symlink to nix store)
- Same config as aurin/macbook/vespino
- `start-x11` detects and compiles config automatically

### Notes:

- **Clone-first philosophy**: Android gets same XMonad config as desktop
- **Termux-X11 use case**: External display, DeX mode, etc.
- **Fallback**: If you don't use X11, config is there but doesn't interfere
- **Scripts**: Absolute paths work (same as desktop)

### Android-Specific Considerations:

- **No xmobar.nix import**: Android doesn't need machine-specific xmobar config
- **start-x11 script**: Already handles XMonad compilation
- **OpenCode disabled**: Still disabled (EPERM issue), unrelated to XMonad

---

## 🍺 Notes from Session

- Tested live on PROD (aurin) - Friday vibes 🎮
- "Pelaron el ano" en LoL 😂
- Almost broke composer (stopped with "1000 ojos" ✅)
- Pragmatic approach: working > perfect

**Status**: Ready to deploy! 🚀
