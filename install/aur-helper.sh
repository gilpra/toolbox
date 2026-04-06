#!/usr/bin/env bash

set -euo pipefail

AUR_HELPER=("yay" "paru")

for i in "${!AUR_HELPER[@]}"; do
  echo "$((i + 1)). ${AUR_HELPER[$i]}"
done

read -p "Choose your AUR Helper (number): " SELECTED_AUR
echo
