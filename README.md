# LanguageTool Omarchy plugin

Run and control the local LanguageTool grammar-check server straight from the
Omarchy bar. English and French are supported out of the box.

## What it does

LanguageTool 6.6 is installed system-wide from the Arch `extra` repository
(`pacman -S languagetool`, which pulls in a Java runtime). This plugin is a thin
shell over that install:

- A bar widget shows a spell-check glyph — dimmed while the server is stopped,
  at full strength while it is running.
- Clicking it opens a panel with the server status (state, port, supported
  languages, process id) and a **Turn on / Turn off** button.
- The server runs as a detached background process on `localhost:8081`, so apps
  like LibreOffice and the LanguageTool browser extension can connect to
  `http://localhost:8081` without a terminal.
- Nothing is started at boot or automatically by the plugin. The toggle is
  manual.

## Files

| File | Purpose |
| --- | --- |
| `manifest.json` | Omarchy schemaVersion 1 manifest; service + bar-widget kinds. |
| `Service.qml` | Long-lived singleton; polls `languagetoolctl status` every 5 seconds and runs start/stop. |
| `BarWidget.qml` | Compact bar indicator, click handling, and `Panel.qml` loader. |
| `Panel.qml` | Theme-aware status panel with a start/stop button and keyboard navigation. |
| `languagetoolctl` | Helper: reports status, starts and stops the LanguageTool server. |

## Installation

```sh
omarchy plugin add https://github.com/cittadhammo/omarchy-languagetool.git --enable
```

This clones the plugin into Omarchy's discovery path and places the widget in
the configured bar layout. Move it wherever you like:

```sh
omarchy plugin enable cittadhammo.languagetool --section center --after omarchy.clock
```

The system package stays a separate step:

```sh
sudo pacman -S languagetool
```

The plugin never starts the server on its own; use the panel toggle (or the
helper below) every session.

## The helper

`languagetoolctl` prints one JSON document on stdout and exits non-zero only on
real failure:

```sh
~/.config/omarchy/plugins/cittadhammo.languagetool/languagetoolctl status
~/.config/omarchy/plugins/cittadhammo.languagetool/languagetoolctl start
~/.config/omarchy/plugins/cittadhammo.languagetool/languagetoolctl stop
```

- `status` reports whether a server is answering on port 8081, how many
  languages are registered, and whether English and French are present. It
  detects servers started elsewhere too, so the widget stays accurate even when
  the process was launched outside the plugin.
- `start` launches `/usr/bin/languagetool --http --allow-origin "*"` detached
  and waits until the port accepts connections. Its PID is recorded in
  `~/.local/state/languagetool-server/server.pid` and its output in
  `server.log`.
- `stop` terminates the matching Java process (by Pid, falling back to scanning
  `/proc` for `org.languagetool.server.HTTPServer`) and waits for the port to
  close.

## Development

This directory is the git repository. Save a QML file in
`~/.config/omarchy/plugins/` and the shell notices ("Local plugin changed,
reloading:"), but the reload keeps previously compiled QML, so edits to
`Service.qml`/`Panel.qml`/`BarWidget.qml` do **not** take effect until the shell
is restarted:

```sh
omarchy restart shell
```

Force a rescan of the plugin list with:

```sh
omarchy-shell shell rescanPlugins
```

Validate before publishing:

```sh
omarchy plugin validate .
```

To inspect QML load errors and record the current instance:

```sh
quickshell list --all
quickshell log --id <instance-id> --tail 150
```

## Publishing

This directory is the git repository. To publish an update, commit and push —
`omarchy plugin add` installs straight from the git URL, and
`omarchy plugin update cittadhammo.languagetool` pulls newer commits.

## Removing

```sh
omarchy plugin remove cittadhammo.languagetool --yes
```

The plugin leaves no state behind beyond the server's own log and pid file
under `~/.local/state/languagetool-server/`, which you can delete along with any
still-running server (`languagetoolctl stop` first).