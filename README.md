# claude-config

Skills y configuracion personal de Claude Code, sincronizada entre maquinas.

## Que contiene

- `skills/tdd-workflow/SKILL.md` — flujo TDD adaptado a Vitest + Next.js (Server Actions, Supabase, Web Crypto).
- `skills/tests-status/SKILL.md` — auditoria del estado de cobertura de tests por proyecto. No modifica codigo.
- `install.sh` — bootstrap idempotente que enlaza `skills/*` a `~/.claude/skills/`.

## Instalacion en una maquina nueva

### Opcion A — GitHub privado

```bash
git clone git@github.com:<usuario>/claude-config.git ~/.claude-config
cd ~/.claude-config
./install.sh
```

### Opcion B — Self-host en LowEnd-OFFICE (Tailscale)

Una vez (en el server, como bare repo):
```bash
ssh <TAILSCALE_HOST>
sudo mkdir -p /srv/git/claude-config.git
sudo git init --bare /srv/git/claude-config.git
sudo chown -R $USER:$USER /srv/git/claude-config.git
```

En cada maquina (con Tailscale arriba):
```bash
git clone <usuario>@<TAILSCALE_HOST>:/srv/git/claude-config.git ~/.claude-config
cd ~/.claude-config
./install.sh
```

## Uso del script

```bash
./install.sh            # symlinks normales, falla si la skill ya existe en destino
./install.sh --force    # sobrescribe lo que haya en ~/.claude/skills/<name>
./install.sh --copy     # copia plana en vez de symlink (Windows sin developer mode)
```

Por defecto crea symlinks: editar `skills/tdd-workflow/SKILL.md` aqui se refleja
inmediatamente en `~/.claude/skills/tdd-workflow/SKILL.md`. `git pull` sincroniza
todas las maquinas. Si el sistema no permite symlinks (Windows sin permisos
elevados), el script cae automaticamente a copia plana.

## Flujo de edicion

1. Editas una skill en este repo (no en `~/.claude/skills/`).
2. `git add . && git commit -m "..."`.
3. `git push`.
4. En cada otra maquina: `cd ~/.claude-config && git pull`.
5. Si la skill es nueva: `./install.sh`. Si solo editaste contenido y es symlink: nada que hacer.

## Anadir una skill nueva

```bash
mkdir -p skills/<nombre>
$EDITOR skills/<nombre>/SKILL.md
./install.sh
git add skills/<nombre>
git commit -m "skill: <nombre>"
git push
```

El frontmatter minimo de un `SKILL.md`:
```
---
name: <nombre>
description: <cuando usarla, palabras clave de auto-trigger>
origin: personalizada
---
```

## Que NO va aqui

- Credenciales, tokens, llaves API.
- `settings.local.json` con paths absolutos a maquinas concretas.
- Skills instaladas via plugin marketplace (esas se actualizan solas).
- Hooks de proyecto especificos (esos van en `<proyecto>/.claude/`).
