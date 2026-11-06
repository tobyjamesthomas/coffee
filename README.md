# Coffee ☕️

A tiny macOS menu bar app that keeps your Mac awake. Click the coffee cup to turn **Stay Awake** on, and click it again to turn it off.

- **Outline cup:** your Mac sleeps normally.
- **Filled cup:** the display stays on and the Mac won't go to sleep when idle.

## Usage

| Action | Result |
| --- | --- |
| Left-click the cup | Turn Stay Awake on or off |
| Right-click (or Control-click) the cup | Open a menu with **Stay Awake** and **Quit Coffee** |

Coffee only appears in the menu bar. It has no Dock icon and no windows.

## Building

You need the Xcode Command Line Tools (`xcode-select --install`).

```sh
./build.sh
open Coffee.app
```

This compiles `main.swift` into `Coffee.app` in the project folder. The app runs on Apple Silicon Macs with macOS 11 or later.

To also build for Intel Macs, run `ARCHS="arm64 x86_64" ./build.sh`. This needs a toolchain that still includes Intel Swift libraries; the macOS 27 Command Line Tools no longer do. To keep it around, move `Coffee.app` to `/Applications`. To start it automatically, add it under **System Settings → General → Login Items**.

## How it works

Coffee works like `caffeinate -d -i`, but it doesn't run the `caffeinate` command. It asks macOS directly to keep the Mac awake, using [IOKit power management assertions](https://developer.apple.com/documentation/iokit/iopmlib_h). When Stay Awake is on, it holds two of these requests:

- `PreventUserIdleDisplaySleep`: keeps the display on.
- `PreventUserIdleSystemSleep`: stops the Mac from sleeping when idle.

Turning Stay Awake off releases both. If Coffee quits or crashes, macOS releases them automatically, so your Mac can never be left stuck awake.

To see what Coffee is holding at any time, run:

```sh
pmset -g assertions | grep Coffee
```

## Project layout

```
main.swift               The whole app: menu bar icon, click handling, power assertions
build.sh                 Compiles main.swift and packages it as Coffee.app
scripts/make-icon.swift  Draws the app icon; build.sh runs it on every build
```

## License

[MIT](LICENSE)
