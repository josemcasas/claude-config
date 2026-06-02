#!/usr/bin/env bash
# ============================================================
# Bootstrap de claude-config: enlaza las skills de este repo
# a ~/.claude/skills/ via symlink.
#
# Editar la skill en este repo se refleja en todas las maquinas
# que tengan el repo clonado (un `git pull` y listo).
#
# Uso:
#   ./install.sh            # symlinks normales, falla si ya existe
#   ./install.sh --force    # sobrescribe symlinks o carpetas existentes
#   ./install.sh --copy     # copia en vez de symlink (para sistemas sin
#                           # permiso de symlink, p.ej. Windows sin developer mode)
# ============================================================

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.claude/skills"
MODE="symlink"
FORCE=0

for arg in "$@"; do
  case "$arg" in
    --force) FORCE=1 ;;
    --copy)  MODE="copy" ;;
    -h|--help)
      sed -n '2,/^$/p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Argumento desconocido: $arg" >&2
      exit 2
      ;;
  esac
done

if [[ ! -d "${REPO_DIR}/skills" ]]; then
  echo "No se encuentra ${REPO_DIR}/skills" >&2
  exit 1
fi

mkdir -p "${TARGET_DIR}"

cd "${REPO_DIR}/skills"
shopt -s nullglob
count=0
skipped=0

for src in */; do
  name="${src%/}"
  dest="${TARGET_DIR}/${name}"

  if [[ -e "${dest}" || -L "${dest}" ]]; then
    if [[ "${FORCE}" -eq 1 ]]; then
      rm -rf "${dest}"
    else
      echo "[skip] ${name} ya existe en ${TARGET_DIR}. Usa --force para sobrescribir."
      skipped=$((skipped+1))
      continue
    fi
  fi

  if [[ "${MODE}" == "copy" ]]; then
    cp -r "${REPO_DIR}/skills/${name}" "${dest}"
    echo "[copy] ${name}"
  else
    # ln -s puede fallar en Windows sin developer mode. Caemos a copy con aviso.
    if ln -s "${REPO_DIR}/skills/${name}" "${dest}" 2>/dev/null; then
      echo "[link] ${name} -> ${REPO_DIR}/skills/${name}"
    else
      cp -r "${REPO_DIR}/skills/${name}" "${dest}"
      echo "[copy] ${name} (symlink fallo; copia plana en su lugar)"
    fi
  fi
  count=$((count+1))
done

echo
echo "Instaladas: ${count}  ·  Saltadas: ${skipped}"
echo "Destino: ${TARGET_DIR}"
