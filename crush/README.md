# Crush - AI Coding Agent

**Status**: Configurado para Ollama local (Aurin)

---

## Configuración

La config está en `.config/crush/crush.json` y se enlaza a `~/.config/crush/`.

### Provider: Ollama (Aurin)

- **URL**: `http://campo.zapto.org:11434/v1/`
- **Hardware**: RTX 5080 con 16GB VRAM

---

## Modelos con Soporte de Tools (Agénticos)

**IMPORTANTE**: Solo estos modelos soportan function calling para agentes:

| Modelo | VRAM | Tools | Estado |
|--------|------|-------|--------|
| `qwen3:14b` | ~9GB | ✅ | Recomendado, ligero |
| `gpt-oss:20b` | ~13GB | ✅ | Buen balance |
| `devstral-small-2:latest` | ~15GB | ✅ | Límite 16GB |

### Modelos SIN soporte de tools (no sirven para agentes):

- `qwen2.5-coder:*` - Sin tool calling
- `deepseek-r1:*` - Solo reasoning, sin tools
- `gemma3:*` - Sin tools
- `mistral:latest` - Versión antigua
- `llama3.1:latest` - Sin tools

---

## Modelos recomendados para instalar

Si necesitas más opciones con tools:

```bash
ollama pull qwen3-coder:30b    # Mejor para código
ollama pull mistral-small3.2   # Buen tool calling
ollama pull llama4             # Meta's latest
```

---

## Uso

```bash
# Ejecutar crush
crush

# O desde compilación local
~/src/crush/crush-latest

# Shortcuts
Ctrl+O  # Seleccionar modelo
Ctrl+K  # Comandos
Ctrl+?  # Ayuda
```

---

## Instalación config

```bash
# Enlazar config al home
ln -sf ~/dotfiles/crush/.config/crush ~/.config/crush
```

---

## Referencias

- **Crush**: https://github.com/charmbracelet/crush
- **Ollama Tools Models**: https://ollama.com/search?c=tools
- **Agent Skills**: https://agentskills.io

---

## Changelog

- **2026-01-23**: Config inicial con modelos tools-only para 16GB VRAM
