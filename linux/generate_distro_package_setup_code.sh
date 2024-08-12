#!/usr/bin/env bash
# Generate code for Linux (distro-specific) package setup

function append_source_file_lines_with_prefix_into_dest_file() {
  local src_file="$1"
  local dest_file="$2"
  local line_prefix="$3"

  if [ ! -f "$src_file" ]; then return; fi

  while IFS= read -r line; do
    if [[ "$line" =~ ^#.* ]]; then # Leave comments unchanged
      echo "$line" >>"$dest_file"
    else
      echo "$line_prefix $line" >>"$dest_file"
    fi
  done <"$src_file"
}

distro="$1"

if [ -z "$distro" ]; then
  echo "First parameter (Linux distro) is required. Supported values: debian, arch."
  return 1 >/dev/null 2>&1
  exit 1
fi

distro=$(echo "$distro" | tr '[:upper:]' '[:lower:]')

if [ "$distro" = "debian" ]; then
  pm_update_system='sudo apt-get update -y --fix-missing -qq && sudo apt-get upgrade -y -qq'
  pm_install_package='sudo apt-get install -y -qq'

elif [ "$distro" = "arch" ]; then
  pm_update_system='sudo pacman -Syu --noconfirm'
  pm_install_package='sudo pacman -S --noconfirm --needed'

else
  echo "Unknown Linux distro: $distro"
  return 1 >/dev/null 2>&1
  exit 1
fi

setup_dir="$(cd "$(dirname "$0")" && pwd)"
setup_file="$setup_dir/configure_packages_$distro.sh"

rm -f "$setup_file"
touch "$setup_file"
chmod 755 "$setup_file"

echo \
  '#!/usr/bin/env bash
# Configuring packages for a Linux system
' >>"$setup_file"

echo -e "$pm_update_system" >>"$setup_file"

# Package manager

src_file="$setup_dir/packages_pm_common_1.txt"
if [ -f "$src_file" ]; then
  echo -e '\n# Packages (distro-agnostic):\n' >>"$setup_file"
  append_source_file_lines_with_prefix_into_dest_file "$src_file" "$setup_file" "$pm_install_package"
fi

src_file="$setup_dir/packages_pm_${distro}_1.txt"
if [ -f "$src_file" ]; then
  echo -e "\n# Packages ($distro-specific):\n" >>"$setup_file"
  append_source_file_lines_with_prefix_into_dest_file "$src_file" "$setup_file" "$pm_install_package"
fi

# Snap

src_file="$setup_dir/packages_pm_snap_1.txt"
if [ "$distro" = "debian" ] && [ -f "$src_file" ]; then
  echo -e '\n# Packages (Snap):\n' >>"$setup_file"
  append_source_file_lines_with_prefix_into_dest_file "$src_file" "$setup_file" "sudo snap install"
fi

# AUR

src_file="$setup_dir/packages_pm_aur_1.txt"
if [ "$distro" = "arch" ] && [ -f "$src_file" ]; then
  echo -e '\n# Packages (AUR):\n' >>"$setup_file"
  append_source_file_lines_with_prefix_into_dest_file "$src_file" "$setup_file" "yay -S --noconfirm"
fi

# Go-lang

src_file="$setup_dir/packages_go_${distro}_1.txt"
if [ -f "$src_file" ]; then
  echo -e "\n# Go ($distro-specific):\n" >>"$setup_file"
  echo 'if command -V go >/dev/null 2>&1; then' >>"$setup_file"
  append_source_file_lines_with_prefix_into_dest_file "$src_file" "$setup_file" "go install"
  echo 'fi' >>"$setup_file"
fi

# Manual install

src_file="$setup_dir/packages_shell_common_1.sh"
if [ -f "$src_file" ]; then
  echo -e "\n# Non-packaged software (distro-agnostic):\n" >>"$setup_file"
  cat "$src_file" >>"$setup_file"
fi

src_file="$setup_dir/packages_shell_${distro}_1.sh"
if [ -f "$src_file" ]; then
  echo -e "\n# Non-packaged software ($distro-specific):\n" >>"$setup_file"
  cat "$src_file" >>"$setup_file"
fi
