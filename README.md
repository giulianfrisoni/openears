# OpenEars

A native macOS menu bar companion that aims for AirPods-like everyday convenience while preserving each headset’s own features. 15 bundled profiles across Nothing, Samsung, Sony and Soundcore. Open source, local Bluetooth, no accounts or analytics.

[GitHub repository](https://github.com/giulianfrisoni/openears) · [The people behind the work](ACKNOWLEDGMENTS.md) · [Device-profile template](profiles/README.md) · [Product direction](docs/PRODUCT-DIRECTION.md) · [Contributing](CONTRIBUTING.md)

## About OpenEars

OpenEars is a free, hobbyist, and semi-vibe-coded macOS application. Its goal is to help non-Apple headsets feel at home on the Mac, with native-style controls and deeper integration usually associated with Apple accessories.

- **Native-grade integration:** Bring supported non-Apple earbuds and headphones as close as macOS permits to the everyday experience of AirPods or Beats, without pretending to provide Apple-only services.
- **Community-driven open-source drivers:** Build on credited, license-compatible open-source drivers and protocol research for battery reporting and device controls. Microphone routing and broader system integration are project goals; they are not implemented yet.
- **Extensible architecture:** Add compatible models through validated device profiles, and add new protocols through reviewed drivers. Community requests, hardware testing, and driver contributions guide expansion.

**Early prototype. All support remains experimental. Only Nothing Ear (3) has been tested on physical hardware in OpenEars.**

See the [compatibility matrix](docs/COMPATIBILITY.md) for all 15 models, implemented controls, protocol sources and limits.

Tested on a physical Ear (3): live earbud battery, transparency switching, More Bass EQ, fixed spatial audio, and reconnect. All changed settings were read back from the device and restored. See `docs/HARDWARE-TEST.md` for the exact scope.

## Run

Requires macOS 14+ and Swift 6.1+ (Xcode or Apple Command Line Tools).

```sh
sh scripts/build-app.sh
open build/OpenEars.app
```

Click the earbuds icon in the menu bar. Choose your model under **Device profiles**, pair and connect it in macOS Bluetooth Settings, click **Connect to earbuds**, and grant Bluetooth permission if prompted. Leave the factory Bluetooth name unchanged for this prototype.

The app reads the controls listed for your model. Nothing offers battery, firmware, noise control, EQ presets and (on selected models) spatial audio; Samsung offers battery, noise control and EQ presets; Sony and Soundcore currently offer battery and noise control. Controls remain unavailable until the corresponding device state arrives. Changes are shown as selected only after device readback. No firmware writing is implemented.

The local build is ad-hoc signed. Developer ID signing, notarization, automatic app updates and public distribution are future work.

## Device profiles

The versioned JSON catalog lives in `Sources/OpenEarsCore/Resources/catalog.json`. Use **Add device profile…** to create a credited profile for an available driver/model, **Import…** to add a profile document or catalog without replacing existing profiles, and **Export…** to share the selected profile. Conflicting IDs or Bluetooth aliases reject the whole import. The validated catalog is stored atomically in `~/Library/Application Support/OpenEars/catalog.json`. On app startup, newly bundled profiles are added when their IDs and names do not conflict with your saved profiles. Your saved profiles take precedence. Remove that file to restore the bundled catalog. A malformed installed catalog falls back to the bundled copy.

Profiles declare identity, driver, model and feature availability. A new model can ship in a catalog without changing the app **when the existing driver already understands its protocol, model code and feature formats**. A new protocol needs a driver release. The present Nothing driver has an upstream model enum; genuinely new Nothing models may require a driver change too. Unknown drivers are shown as unavailable. Profile imports cannot execute code or supply arbitrary Bluetooth packets.

This prototype supports one active headset at a time. Nothing additionally checks the returned model code. The new RFCOMM adapters require exactly one paired, audio-connected device matching a profile name and its advertised control service; they do not yet verify a returned model identifier. Renamed devices need an exact-name custom profile. Multiple matching devices are rejected. Stronger identity matching remains future work.

## Structure

- `OpenEarsCore`: catalog schema, validation and matching, independent of SwiftUI/Bluetooth.
- `OpenEars`: SwiftUI menu bar interface and an abstract headset driver contract.
- `NothingDriver`: adapts the Nothing driver to common state and controls.
- `ClassicHeadsetDriver` and `ControlPackets`: native RFCOMM plus bounded Samsung, Sony and Soundcore protocol adapters.
- `Vendor/ProtocolReferences`: pinned source provenance and preserved upstream licenses.
- `Vendor/SwiftNothingEar`: pinned GPL-3.0 upstream dependency with documented changes.
- `docs/ROADMAP.md`: feature parity, catalog distribution and platform work.

## Tests

```sh
sh scripts/test.sh
```

Automated tests cover packet fragmentation, checksums, recorded status data, safe setting payloads and catalog upgrades. Catalog tests cover identity collisions, unsupported schemas and planned-feature gating. Bluetooth operation requires hardware testing. Battery values are never simulated.

## License and credits

GPL-3.0; see LICENSE. OpenEars contributors retain copyright in their contributions. With thanks to **bestK1ngArthur and contributors**, **RapidZapper**, **Bendix**, and the **Ear (web) community**. Complete author credits, source references and licensing notes are in [ACKNOWLEDGMENTS.md](ACKNOWLEDGMENTS.md), available inside the app and on the landing page. Includes [swift-nothing-ear](https://github.com/bestK1ngArthur/swift-nothing-ear); see `Vendor/SwiftNothingEar/UPSTREAM.md` and its license. That project credits [Ear (web)](https://github.com/radiance-project/ear-web). OpenEars is an independent project, unaffiliated with headset manufacturers.

This project builds on excellent open-source repositories, drivers, and protocol research. I deeply appreciate the time and effort their authors and contributors have given to the community. If you find reused work that is missing a reference or has an incomplete attribution, please [open an issue](https://github.com/giulianfrisoni/openears/issues) or contact the maintainer so it can be corrected promptly.

No harm or copyright infringement is intended. If you are the author or rights holder of reused material and believe its use or attribution is incorrect, please contact the maintainer. The material will be reviewed promptly and, when appropriate, corrected or removed while respecting the applicable open-source license and other contributors' rights.

## How to contribute

- **Use and fork:** Clone, study, modify, and run the code under the terms of GPL-3.0 and the preserved third-party licenses.
- **Add devices:** Open a [device-support issue](https://github.com/giulianfrisoni/openears/issues/new?template=device-support.md) or pull request with a licensed driver, protocol source, model details, and hardware-test evidence.
- **Build together:** Bug fixes, accessibility work, driver improvements, documentation, and hardware validation are welcome. Every reused source must keep its authorship and license visible.

## Landing page and GitHub preparation

The landing page is in `website/`, with author credits and downloadable notices. See [website instructions](website/README.md) and [GitHub preparation](docs/GITHUB-PREPARATION.md). Repository CI, a contribution guide and device issue / PR templates are included. The source is published at [giulianfrisoni/openears](https://github.com/giulianfrisoni/openears). A signed binary release and hosted landing page are not available yet.
