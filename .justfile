BUILD_DIR := "build" # location for build artifacts

ansi_fg_green := '[32m'
ansi_fg_black := '[30m'
ansi_fg_bright_black := '[90m'
ansi_dim := '[2m'
ansi_hidden := '[8m'
ansi_reset := '[0m'

help_text := '
Usage: `just [TARGET..]`
'

# help
help:
  @just --list --list-heading=$'\nUsage: `{{ansi_dim}}just [TARGET..]{{ansi_reset}}`\n\nTARGETs:\n\n' --list-prefix=''
  @echo '{{ansi_hidden}}.{{ansi_reset}}'

#===

# build
build: _init-dirs
  odin build src/bin/args --out:{{BUILD_DIR}}/bin/args.exe --vet --warnings-as-errors
  @echo '{{ansi_fg_black}}Build successful!{{ansi_reset}}'

_init-dirs:
  @# @mkdir -p "{{BUILD_DIR}}"
  @mkdir -p "{{BUILD_DIR}}/bin"
