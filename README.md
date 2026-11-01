# Switcher

Switcher is a macOS app for running multiple local web projects through [portless](https://github.com/portless-dev/portless). It starts and stops dev servers, manages the portless HTTPS proxy, and gives each project a stable URL like `https://your-slug.localhost:1355`.

## Features

- Add projects with a directory path and run command
- Start and stop dev servers from a simple project list
- Automatic framework detection (Next.js, Nuxt, Astro, Remix, Svelte, Angular, Vite, Laravel, Mintlify, React Native, Go, Rust, Node, and more)
- Custom project icons (SF Symbols or images)
- Live log output per project
- Optional sync of project data via iCloud Documents (when enabled in a signed build)
- Clean shutdown of background processes when you quit the app

## Requirements

- macOS 14 or later
- [Xcode](https://developer.apple.com/xcode/) 16 or later (to build from source)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- [portless](https://www.npmjs.com/package/portless) installed and available on your `PATH`

## Build from source

```bash
git clone https://github.com/gre-dev/Switcher.git
cd Switcher
xcodegen generate
open Switcher.xcodeproj
```

Build and run the **Switcher** scheme in Xcode. For local development you can use ad hoc signing or your own Apple Development team in `project.yml`.

## Using Switcher

1. Install portless if you have not already (`npm install -g portless` or your preferred method).
2. Launch Switcher and add a project: choose the project folder and the command you normally use to start the dev server (for example `npm run dev`).
3. Switcher assigns an app port in the 4000–4999 range and builds the portless command for you.
4. Start the project; Switcher ensures the portless proxy is running on port **1355** (HTTPS) and opens the project’s `https://<slug>.localhost:1355` URL when appropriate.

Project list and settings are stored locally under Application Support. iCloud sync requires the appropriate entitlements and container in a signed build.

## Project layout

| Path | Purpose |
|------|---------|
| `Switcher/` | SwiftUI app source |
| `project.yml` | XcodeGen project definition |
| `Switcher/Switcher.entitlements` | App entitlements (configure for iCloud when signing) |

Generated `Switcher.xcodeproj` is not committed; run `xcodegen generate` after cloning.

## Contributing

Issues and pull requests are welcome. Please keep changes focused and match existing Swift and UI patterns in the codebase.

## License

MIT — see [LICENSE](LICENSE).
