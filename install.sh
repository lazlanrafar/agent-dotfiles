#!/usr/bin/env bash
# install.sh: link plugins into ~/.gemini/config/plugins/
set -euo pipefail

DEST_DIR="${HOME}/.gemini/config/plugins"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "${DEST_DIR}"

echo "==> Linking plugins from ${REPO_DIR}/plugins to ${DEST_DIR}..."
for plugin_path in "${REPO_DIR}"/plugins/*; do
  [ -d "${plugin_path}" ] || continue
  plugin_name="$(basename "${plugin_path}")"
  target="${DEST_DIR}/${plugin_name}"

  if [ -L "${target}" ]; then
    echo "  [OK] ${plugin_name} already symlinked"
  elif [ -d "${target}" ]; then
    echo "  [SKIP] ${plugin_name} exists as regular directory in ~/.gemini/config/plugins"
  else
    ln -s "${plugin_path}" "${target}"
    echo "  [LINKED] ${plugin_name} -> ${target}"
  fi
done

# Setup MCP template if not exists
MCP_DEST="${HOME}/.gemini/config/mcp_config.json"
if [ ! -f "${MCP_DEST}" ]; then
  echo "==> Creating initial mcp_config.json from template..."
  cp "${REPO_DIR}/mcp/mcp_config.template.json" "${MCP_DEST}"
  echo "  Remember to update credentials in ${MCP_DEST}"
fi

echo "==> Installation complete."
