# Contributing to OpenEars

Our goal is an AirPods-like everyday experience on macOS while preserving the distinctive controls and capabilities of each headset. Nothing Ear (3) is the first device. Feature availability must reflect hardware evidence.

## Before contributing

Read README.md, ACKNOWLEDGMENTS.md and docs/ROADMAP.md. Open an issue describing the device, firmware and behavior you want to improve. For bugs, include macOS version and reproduction steps, with serial numbers and Bluetooth addresses removed.

## Code and profiles

Keep Bluetooth framing and complex operations in drivers, device capabilities in the catalog and presentation in SwiftUI. Do not ship executable code or unrestricted packets in downloaded profiles. Avoid copying a vendor's whole mobile interface: keep everyday controls compact, with model-specific features available in a secondary view.

Run `sh scripts/test.sh` and `sh scripts/build-app.sh`. Website changes also require its documented production build. Hardware changes need a report like docs/HARDWARE-TEST.md. Distinguish a successful command write, a device readback and a confirmed audible or physical effect.

## Attribution is required

For every copied snippet, adapted implementation, dependency, asset or research source:

1. Name the original authors and project, and link the original source.
2. Record its version or revision and license; preserve copyright and license texts.
3. Explain what OpenEars uses and any changes, including indirect upstream lineage.
4. Update ACKNOWLEDGMENTS.md, the app's generated resource, and website notices. Run `python3 scripts/sync-credits.py` and the website's notices command.

Use the license actually supplied upstream. Do not infer permission from a public repository or replace a license with a thank-you. If a license or author is unclear, resolve it before including that code. AI-assisted contributions follow the same review, attribution and testing requirements.

Contributions to OpenEars are under GPL-3.0; third-party material retains its original notices and compatible terms. Keep unrelated refactors out of feature changes.
