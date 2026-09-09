#!/usr/bin/env bash
# =============================================================================
# install-prereqs.sh
# =============================================================================
# Installs all prerequisites for this Neovim configuration.
# Supports: Ubuntu/Debian, Fedora, Arch Linux, macOS.
# Idempotent — safe to re-run.
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Colour helpers
# ---------------------------------------------------------------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Colour

info()  { printf "${BLUE}[INFO]${NC}  %s\n" "$*"; }
ok()    { printf "${GREEN}[OK]${NC}    %s\n" "$*"; }
warn()  { printf "${YELLOW}[WARN]${NC}  %s\n" "$*"; }
err()   { printf "${RED}[ERR]${NC}   %s\n" "$*"; }

# ---------------------------------------------------------------------------
# Detect OS
# ---------------------------------------------------------------------------
 detect_os() {
  if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    if command -v apt-get &>/dev/null; then
      echo "debian"
    elif command -v dnf &>/dev/null; then
      echo "fedora"
    elif command -v pacman &>/dev/null; then
      echo "arch"
    else
      echo "unknown"
    fi
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo "macos"
  else
    echo "unknown"
  fi
}

OS=$(detect_os)

if [[ "$OS" == "unknown" ]]; then
  err "Unsupported OS. This script supports Ubuntu/Debian, Fedora, Arch Linux, and macOS."
  exit 1
fi

info "Detected OS: $OS"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

has_cmd() {
  command -v "$1" &>/dev/null
}

pkg_is_installed() {
  case "$OS" in
    debian) dpkg -s "$1" &>/dev/null ;;
    fedora) rpm -q "$1" &>/dev/null ;;
    arch)   pacman -Q "$1" &>/dev/null ;;
    macos)  brew list "$1" &>/dev/null ;;
    *)      return 1 ;;
  esac
}

update_pkg_db() {
  case "$OS" in
    debian)
      if [[ "${SKIP_APT_UPDATE:-}" != "1" ]]; then
        info "Updating apt package database..."
        sudo apt-get update -qq
      fi
      ;;
    fedora)
      info "Updating dnf package database..."
      sudo dnf check-update -y || true
      ;;
    arch)
      info "Updating pacman package database..."
      sudo pacman -Sy --noconfirm
      ;;
    macos)
      if ! has_cmd brew; then
        err "Homebrew is not installed. Please install it first:"
        err "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
      fi
      info "Updating Homebrew..."
      brew update
      ;;
  esac
}

install_pkgs() {
  local pkgs=("$@")
  case "$OS" in
    debian)
      info "Installing packages via apt: ${pkgs[*]}"
      sudo apt-get install -y -qq "${pkgs[@]}"
      ;;
    fedora)
      info "Installing packages via dnf: ${pkgs[*]}"
      sudo dnf install -y "${pkgs[@]}"
      ;;
    arch)
      info "Installing packages via pacman: ${pkgs[*]}"
      sudo pacman -S --noconfirm --needed "${pkgs[@]}"
      ;;
    macos)
      info "Installing packages via brew: ${pkgs[*]}"
      brew install "${pkgs[@]}"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# 1. Base system packages
# ---------------------------------------------------------------------------

install_base_packages() {
  info "=== Step 1: Base system packages ==="

  local to_install=()

  case "$OS" in
    debian)
      # Add neovim unstable PPA if not already present
      if ! grep -rq "neovim-ppa/unstable" /etc/apt/sources.list.d/ 2>/dev/null; then
        info "Adding Neovim unstable PPA..."
        sudo add-apt-repository ppa:neovim-ppa/unstable -y
        sudo apt-get update -qq
      fi

      local pkgs=(git make unzip gcc ripgrep fd-find tree-sitter-cli xclip neovim curl)
      for p in "${pkgs[@]}"; do
        if ! dpkg -s "$p" &>/dev/null 2>&1; then
          to_install+=("$p")
        else
          ok "$p already installed"
        fi
      done
      ;;

    fedora)
      local pkgs=(git make unzip gcc ripgrep fd-find tree-sitter-cli xclip neovim curl)
      for p in "${pkgs[@]}"; do
        if ! rpm -q "$p" &>/dev/null 2>&1; then
          to_install+=("$p")
        else
          ok "$p already installed"
        fi
      done
      ;;

    arch)
      local pkgs=(git make unzip gcc ripgrep fd tree-sitter-cli xclip neovim curl)
      for p in "${pkgs[@]}"; do
        if ! pacman -Q "$p" &>/dev/null 2>&1; then
          to_install+=("$p")
        else
          ok "$p already installed"
        fi
      done
      ;;

    macos)
      local pkgs=(git make unzip gcc ripgrep fd tree-sitter xclip neovim curl)
      for p in "${pkgs[@]}"; do
        if ! brew list "$p" &>/dev/null 2>&1; then
          to_install+=("$p")
        else
          ok "$p already installed"
        fi
      done
      ;;
  esac

  if [[ ${#to_install[@]} -gt 0 ]]; then
    install_pkgs "${to_install[@]}"
  else
    ok "All base packages already installed"
  fi
}

# ---------------------------------------------------------------------------
# 2. Node.js & npm
# ---------------------------------------------------------------------------

install_node() {
  info "=== Step 2: Node.js & npm ==="

  if has_cmd node && has_cmd npm; then
    ok "Node.js ($(node --version)) and npm ($(npm --version)) already installed"
    return
  fi

  case "$OS" in
    debian)
      info "Installing Node.js 20.x via NodeSource..."
      if [[ ! -f /etc/apt/sources.list.d/nodesource.list ]]; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
      fi
      sudo apt-get install -y -qq nodejs
      ;;

    fedora)
      info "Installing Node.js 20.x via NodeSource..."
      curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
      sudo dnf install -y nodejs
      ;;

    arch)
      info "Installing Node.js via pacman..."
      sudo pacman -S --noconfirm --needed nodejs npm
      ;;

    macos)
      info "Installing Node.js via Homebrew..."
      brew install node
      ;;
  esac

  ok "Node.js $(node --version) and npm $(npm --version) installed"
}

# ---------------------------------------------------------------------------
# 3. .NET SDK
# ---------------------------------------------------------------------------

install_dotnet_sdk() {
  info "=== Step 3: .NET SDK ==="

  if has_cmd dotnet; then
    ok ".NET SDK already installed: $(dotnet --version)"
    return
  fi

  case "$OS" in
    debian)
      info "Installing .NET SDK 8.0 via Microsoft package repository..."
      wget -q https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
      sudo dpkg -i /tmp/packages-microsoft-prod.deb
      rm -f /tmp/packages-microsoft-prod.deb
      sudo apt-get update -qq
      sudo apt-get install -y -qq dotnet-sdk-8.0
      ;;

    fedora)
      info "Installing .NET SDK 8.0 via Microsoft repository..."
      sudo dnf install -y dotnet-sdk-8.0
      ;;

    arch)
      info "Installing .NET SDK via pacman..."
      sudo pacman -S --noconfirm --needed dotnet-sdk
      ;;

    macos)
      info "Installing .NET SDK via Homebrew..."
      brew install --cask dotnet-sdk
      ;;
  esac

  ok ".NET SDK $(dotnet --version) installed"
}

# ---------------------------------------------------------------------------
# 4. .NET global tools
# ---------------------------------------------------------------------------

install_dotnet_tools() {
  info "=== Step 4: .NET global tools ==="

  # Ensure ~/.dotnet/tools is on PATH for this session
  export PATH="$HOME/.dotnet/tools:$PATH"

  local tools=("EasyDotnet" "roslyn-language-server" "dotnet-ef")
  local tool_names=("dotnet-easydotnet" "roslyn-language-server" "dotnet-ef")

  for i in "${!tools[@]}"; do
    local tool=${tools[$i]}
    local name=${tool_names[$i]}

    if has_cmd "$name"; then
      ok "$name already installed"
      continue
    fi

    info "Installing $name..."
    if [[ "$name" == "roslyn-language-server" ]]; then
      dotnet tool install -g "$tool" --prerelease || {
        warn "Failed to install $name with --prerelease, trying without..."
        dotnet tool install -g "$tool" || true
      }
    else
      dotnet tool install -g "$tool" || {
        warn "Failed to install $name (it may already be installed or require a manual update)"
      }
    fi

    if has_cmd "$name"; then
      ok "$name installed"
    else
      warn "$name may require a shell restart or PATH update. Add '\$HOME/.dotnet/tools' to your PATH."
    fi
  done
}

# ---------------------------------------------------------------------------
# 5. npm global packages
# ---------------------------------------------------------------------------

install_npm_globals() {
  info "=== Step 5: npm global packages ==="

  if ! has_cmd npm; then
    warn "npm not found, skipping npm global packages. Run this script again after Node.js is installed."
    return
  fi

  # beautiful-mermaid-cli provides `bm`, the Mermaid renderer used by
  # cavanaug/render-markdown-mermaid.nvim (see lua/custom/plugins/markdown.lua)
  local pkgs=("vscode-langservers-extracted" "beautiful-mermaid-cli")
  for pkg in "${pkgs[@]}"; do
    if npm list -g "$pkg" &>/dev/null 2>&1; then
      ok "$pkg already installed globally"
    else
      info "Installing $pkg globally..."
      npm install -g "$pkg"
      ok "$pkg installed globally"
    fi
  done
}

# ---------------------------------------------------------------------------
# 6. Ensure ~/.dotnet/tools is on PATH
# ---------------------------------------------------------------------------

ensure_dotnet_tools_path() {
  info "=== Step 6: PATH check ==="

  local shell_rc=""
  if [[ "$SHELL" == */zsh ]]; then
    shell_rc="$HOME/.zshrc"
  elif [[ "$SHELL" == */bash ]]; then
    shell_rc="$HOME/.bashrc"
  fi

  if [[ -n "$shell_rc" && -f "$shell_rc" ]]; then
    if ! grep -q '\$HOME/.dotnet/tools' "$shell_rc" 2>/dev/null; then
      info "Adding \$HOME/.dotnet/tools to PATH in $shell_rc"
      echo 'export PATH="$HOME/.dotnet/tools:$PATH"' >> "$shell_rc"
      ok "Updated $shell_rc"
    else
      ok "\$HOME/.dotnet/tools already in PATH"
    fi
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  info "Starting prerequisite installation for Neovim configuration..."
  info "This may take a few minutes."
  echo

  update_pkg_db
  install_base_packages
  install_node
  install_dotnet_sdk
  install_dotnet_tools
  install_npm_globals
  ensure_dotnet_tools_path

  echo
  ok "=== Installation complete ==="
  info "Open a new terminal (or run 'source ~/.bashrc' / 'source ~/.zshrc') to ensure"
  info "all tools are available in PATH, then start Neovim:"
  info "  nvim"
  info ""
  info "Inside Neovim, run :checkhealth kickstart  and  :checkhealth easy-dotnet"
  info "to verify everything is set up correctly."
}

main "$@"
