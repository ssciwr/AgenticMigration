#!/usr/bin/env bash
set -euo pipefail

# This installer copies the repository's Pi workflow content into a target
# Pi directory. It supports both project-local installs under `.pi/` and a
# user-global install under `~/.pi/agent`.

# Where this install script is located. We use this path to resolve the
# relative `agents`, `prompts`, and `skills` directories consistently.
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_GLOBAL="$HOME/.pi/agent"

# Expand user-friendly paths that use `~` to the actual home directory.
# The function returns the expanded path or an empty string if none is given.
expand_path() {
  local path="$1"

  if [[ "$path" == "" ]]; then
    echo ""
    return
  fi

  if [[ "$path" == ~* ]]; then
    echo "$HOME${path:1}"
  else
    echo "$path"
  fi
}

# Copy a directory tree from the repository into the destination.
# This preserves file attributes and exits with an error if the source is
# missing.
copy_tree() {
  local src="$1"
  local dest="$2"

  if [[ ! -d "$src" ]]; then
    echo "ERROR: Source directory '$src' does not exist." >&2
    exit 1
  fi

  mkdir -p "$dest"
  cp -a "$src" "$dest"
}

# Ask the user a yes/no question and return success for yes.
prompt_yes_no() {
  local prompt="$1"
  local response

  while true; do
    read -r -p "$prompt [y/N]: " response
    case "${response,,}" in
      y|yes) return 0 ;;
      n|no|"") return 1 ;;
      *) echo "Please answer y or n." ;;
    esac
  done
}

# Prompt the user for the primary installation target.
# Accepts:
#   - "global" to install under $HOME/.pi/agent
#   - blank to install locally to the repository's .pi directory
#   - any other path as the explicit install target
read -r -p "Where do you want to install skills, prompts and agents? (global: ~/.pi/agent, blank for local .pi/): " target

if [[ "$target" == "global" ]]; then
  target="$DEFAULT_GLOBAL"
elif [[ "$target" == "" ]]; then
  target=".pi"
fi

# Expand ~ and then resolve any relative path relative to this script.
target="$(expand_path "$target")"
if [[ "$target" != /* ]]; then
  target="$SOURCE_DIR/$target"
fi

# Print the resolved destination and prepare the directory.
echo "Installing to: $target"
mkdir -p "$target"

# Copy the workflow content into the target location.
copy_tree "$SOURCE_DIR/agents" "$target/agents"
copy_tree "$SOURCE_DIR/prompts" "$target/prompts"
copy_tree "$SOURCE_DIR/skills" "$target/skills"

# Confirm the primary installation result.
echo "Installation complete. Installed agents, prompts, and skills into:"
echo "  $target/agents"
echo "  $target/prompts"
echo "  $target/skills"

# Offer to duplicate the same package into additional directories.
# This can be useful if the user wants the content in multiple Pi-compatible
# plugin directories (for example separate directories used by other tools).
if prompt_yes_no "Install the same content to additional Pi-compatible directories for Claude/Codex/Copilot?"; then
  while true; do
    read -r -p "Enter an additional install path (blank to finish): " extra_path

    if [[ "$extra_path" == "" ]]; then
      break
    fi

    extra_path="$(expand_path "$extra_path")"
    if [[ "$extra_path" != /* ]]; then
      extra_path="$SOURCE_DIR/$extra_path"
    fi

    echo "Installing to additional target: $extra_path"
    mkdir -p "$extra_path"
    copy_tree "$SOURCE_DIR/agents" "$extra_path/agents"
    copy_tree "$SOURCE_DIR/prompts" "$extra_path/prompts"
    copy_tree "$SOURCE_DIR/skills" "$extra_path/skills"
    echo "  Installed to: $extra_path"
  done
fi

echo "Done."
