#!/usr/bin/env bash

set -e

info() {
  echo -e "\033[1;34m$1\033[0m"
}

warn() {
  echo "::warning :: $1"
}

error() {
  echo "::error :: $1"
  exit 1
}

root_file="${1}"
working_directory="${2}"
engine="${3}"
args="${4}"
extra_packages="${5}"
extra_system_packages="${6}"
pre_compile="${7}"
post_compile="${8}"
shell_escape="${9}"

if [[ -z "$root_file" ]]; then
  error "Input 'root_file' is missing."
fi

if [[ -z "$engine" && -z "$args" ]]; then
  info "Input 'engine' and 'args' are both empty. Reset them to default values."
  engine="xetex"
  args="-pdf -file-line-error -halt-on-error -interaction=nonstopmode"
fi

IFS=' ' read -r -a args <<< "$args"

if [[ -n "$shell_escape" ]]; then
  args+=("-shell-escape")
fi

if [[ -n "$extra_system_packages" ]]; then
  for pkg in $extra_system_packages; do
    info "Install $pkg by apk"
    apk --no-cache add "$pkg"
  done
fi

if [[ -n "$extra_packages" ]]; then
  warn "Input 'extra_packages' is deprecated. We now build LaTeX document with full TeXLive installed."
fi

if [[ -n "$working_directory" ]]; then
  if [[ ! -d "$working_directory" ]]; then
    mkdir -p "$working_directory"
  fi
  cd "$working_directory"
fi

if [[ -n "$pre_compile" ]]; then
  info "Run pre compile commands"
  eval "$pre_compile"
fi

while IFS= read -r f; do
  if [[ -z "$f" ]]; then
    continue
  fi

  info "Compile $f"

  if [[ ! -f "$f" ]]; then
    error "File '$f' cannot be found from the directory '$PWD'."
  fi

  "$engine" "${args[@]}" "$f"
done <<< "$root_file"

if [[ -n "$post_compile" ]]; then
  info "Run post compile commands"
  eval "$post_compile"
fi
