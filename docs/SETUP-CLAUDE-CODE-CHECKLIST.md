# ✅ Checklist: Setup y Verificación de Claude Code

**Propósito:** Verificar que Claude Code funciona correctamente con stow ANTES de ir a vespino.

---

## Paso 1: Ejecutar Script de Setup

```bash
cd ~/dotfiles
chmod +x scripts/setup-claude-code.sh
./scripts/setup-claude-code.sh
```

**Verificar salida:**
- ✅ Archivos copiados a `~/dotfiles/claude-code/.claude/`
- ✅ No hay errores

**Ver qué se copió:**
```bash
tree ~/dotfiles/claude-code/
# o
ls -la ~/dotfiles/claude-code/.claude/
```

---

## Paso 2: Aplicar Stow (IMPORTANTE!)

```bash
cd ~/dotfiles

# Hacer backup de ~/.claude actual por si acaso
cp -r ~/.claude ~/.claude.backup
cp ~/.claude.json ~/.claude.json.backup 2>/dev/null || true

# Aplicar stow
stow -v -R claude-code
```

**Verificar que se crearon symlinks:**
```bash
ls -la ~/.claude/
# Deberías ver symlinks apuntando a ~/dotfiles/claude-code/.claude/

ls -la ~/.claude.json
# Debería ser symlink a ~/dotfiles/claude-code/.claude.json
```

**Ejemplo de salida esperada:**
```
lrwxrwxrwx  1 passh passh   45 Jan  3 12:00 .claude -> ../dotfiles/claude-code/.claude
lrwxrwxrwx  1 passh passh   52 Jan  3 12:00 .claude.json -> ../dotfiles/claude-code/.claude.json
```

---

## Paso 3: PRUEBA CRÍTICA - Modificar y Verificar

**3.1. Modificar un archivo en ~/.claude/**

```bash
# Añadir una línea de prueba
echo "# PRUEBA: $(date)" >> ~/.claude/CLAUDE.md
```

**3.2. Verificar que el cambio aparece en dotfiles**

```bash
cd ~/dotfiles
git status
```

**Salida esperada:**
```
modified:   claude-code/.claude/CLAUDE.md
```

**3.3. Ver el diff**

```bash
git diff claude-code/.claude/CLAUDE.md
```

**Deberías ver:**
```diff
+# PRUEBA: Fri Jan  3 12:00:00 CET 2026
```

**✅ SI VES EL CAMBIO:** ¡Stow funciona! Los archivos en ~/.claude/ son symlinks.

**❌ SI NO VES EL CAMBIO:** Algo falló. Los archivos NO son symlinks.

**3.4. Revertir la prueba**

```bash
git checkout -- claude-code/.claude/CLAUDE.md
```

---

## Paso 4: Revisar Archivos Sensibles

```bash
# Ver si .claude.json tiene tokens/credenciales
cat ~/dotfiles/claude-code/.claude.json

# Si tiene datos sensibles, edítalo:
emacs ~/dotfiles/claude-code/.claude.json
# O añádelo a .gitignore
```

---

## Paso 5: Hacer Commit

```bash
cd ~/dotfiles
git status

# Ver todos los archivos nuevos
git add -A

# O seleccionar específicamente:
git add modules/home-manager/passh.nix
git add nixos-aurin/etc/nixos/modules/xmonad.nix
git add docs/HOME-MANAGER-INTEGRATION.org
git add docs/CONTINUATION-VESPINO.md
git add docs/SETUP-CLAUDE-CODE-CHECKLIST.md
git add scripts/setup-claude-code.sh
git add claude-code/

# Commit
git commit -m "Fase 3 completa + Claude Code setup y verificación

- Fase 3: Build exitoso SIN --impure
- XMonad config via stow (documentado)
- Claude Code integrado en dotfiles
- Stow verificado funcionando correctamente
- Handoff notes para vespino creadas

🤖 Generated with Claude Code
Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"

# Push
git push origin master  # o main
```

---

## Paso 6: Verificación Final

**6.1. Verificar que Claude Code sigue funcionando**

```bash
# Debería mostrar configuración
cat ~/.claude/CLAUDE.md

# Debería mostrar settings
cat ~/.claude/settings.json
```

**6.2. Probar Claude Code**

```bash
# Lanzar claude-code
claude-code

# En la sesión, verificar que:
# - CLAUDE.md se carga correctamente
# - Settings.json se aplica
# - Agentes personalizados están disponibles
```

**6.3. Hacer un cambio de prueba**

Dentro de Claude Code, pedirle que modifique algo en CLAUDE.md:

```
> Añade una línea al final de CLAUDE.md que diga "Test desde vespino"
```

Luego verificar en git:

```bash
cd ~/dotfiles
git status
# Debería mostrar: modified:   claude-code/.claude/CLAUDE.md
```

**✅ SI FUNCIONA:** El sistema de stow + git está correcto

---

## Paso 7: Preparar para Vespino

**7.1. Asegurarse de que el commit está pusheado**

```bash
cd ~/dotfiles
git log -1  # Ver último commit
git status  # Debería decir "nothing to commit, working tree clean"
```

**7.2. Crear nota final**

```bash
echo "✅ Aurin setup completo - $(date)" >> ~/dotfiles/docs/MIGRATION-LOG.md
git add docs/MIGRATION-LOG.md
git commit -m "Log: Aurin setup completo"
git push
```

---

## 🎯 Checklist Resumido

- [ ] Ejecutar `scripts/setup-claude-code.sh`
- [ ] Verificar archivos copiados en `claude-code/`
- [ ] Hacer backup de `~/.claude/`
- [ ] Ejecutar `stow -v -R claude-code`
- [ ] Verificar symlinks creados (`ls -la ~/.claude/`)
- [ ] **PRUEBA:** Modificar archivo y ver cambio en git
- [ ] Revisar `.claude.json` por datos sensibles
- [ ] Commit de todos los cambios
- [ ] Push a origin
- [ ] Verificar Claude Code funciona
- [ ] Prueba final con modificación
- [ ] Log de migración completa

---

## 🚨 Si Algo Falla

### Stow dice "conflicts"

```bash
# Ver qué está en conflicto
stow -n -v claude-code

# Si ~/.claude/ ya existe y no es symlink:
rm -rf ~/.claude
rm -f ~/.claude.json

# Restaurar desde dotfiles
stow -v claude-code
```

### Cambios no aparecen en git

```bash
# Verificar que son symlinks
ls -la ~/.claude/
file ~/.claude/CLAUDE.md

# Debería decir: "symbolic link to ..."
# Si dice "regular file": Stow no funcionó
```

### Claude Code no arranca

```bash
# Verificar que está instalado
which claude-code

# Si no está:
home-manager switch
# o
sudo nixos-rebuild switch --flake ~/dotfiles#aurin-pure
```

---

**Última actualización:** 2026-01-03
**Propósito:** Verificación completa ANTES de ir a vespino
**Importancia:** CRÍTICA - Si esto no funciona aquí, no funcionará en vespino
