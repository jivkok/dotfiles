# shellcheck shell=bash
# Starship: shell-agnostic prompt
if _has starship; then
  current_version=$(starship --version | head -n 1 | awk '{print $2}')
  latest_version=$(curl -s https://api.github.com/repos/starship/starship/releases/latest | jq ".tag_name" | tr -d 'v"')
  if [ "$current_version" != "$latest_version" ]; then
    log_trace "Starship's current version ($current_version) is different than latest ($latest_version). Installing it."
    install_starship=1
  else
    install_starship=0
  fi
else
  log_trace "Starship is not installed. Installing it."
  install_starship=1
fi

if [ "$install_starship" = "1" ]; then
  curl -sS https://starship.rs/install.sh | sudo sh -s -- --yes
fi
