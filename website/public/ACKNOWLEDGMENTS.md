# With thanks to the people who made this possible

OpenEars builds on other people's work. Credit is part of the product: these acknowledgments travel with the source, the macOS app and the landing page. Thank you to the authors, maintainers, researchers and contributors who make open interoperability possible.

## Included in the macOS app

**swift-nothing-ear — bestK1ngArthur and contributors**

Thank you for the Swift Bluetooth implementation that makes our first Nothing Ear (3) integration possible. OpenEars includes a modified copy of this library, pinned to revision `25d2ba4a69fe72a55f5cbf9e86205e6e47ff8cad`. Its source and GPL-3.0 license remain in `Vendor/SwiftNothingEar`. Our modifications are recorded in `Vendor/SwiftNothingEar/UPSTREAM.md`.

[Project and authors](https://github.com/bestK1ngArthur/swift-nothing-ear) · [Contributor history](https://github.com/bestK1ngArthur/swift-nothing-ear/graphs/contributors)

## Upstream research and community work

**Ear (web) — RapidZapper, Bendix and contributors**

Thank you for the Nothing Bluetooth work credited by swift-nothing-ear. Ear (web) credits RapidZapper for the idea and backend, Bendix for the frontend, and DerrenGoneDigital for its logo. That upstream history deserves to stay visible. OpenEars does not reuse Ear (web)'s interface or logo; this is an acknowledgment of the upstream protocol work and its community.

[Ear (web)](https://github.com/radiance-project/ear-web) · [Bendix](https://www.mrbrickstar.de/) · [DerrenGoneDigital](https://twitter.com/DerrenGoneDigital)

**nothing-bar — bestK1ngArthur and contributors**

Thank you for demonstrating a native macOS menu bar companion and documenting the Nothing driver ecosystem. This project was consulted during research; its app source is not copied into OpenEars.

[nothing-bar](https://github.com/bestK1ngArthur/nothing-bar)

## Platform and development tools

**Apple and the Swift community** — thank you for Swift, Swift Package Manager and Swift Testing, and the macOS SwiftUI, AppKit and CoreBluetooth frameworks. The app uses Apple's system-provided SF Symbols and fonts; these assets are not redistributed as website artwork. Swift's open-source projects and Apple's platform SDKs have their own terms.

[Swift contributors](https://github.com/swiftlang/swift) · [Swift Testing](https://github.com/swiftlang/swift-testing) · [Apple developer documentation](https://developer.apple.com/documentation/)

**Free Software Foundation** — thank you for the GNU General Public License text included in LICENSE.

[GNU GPL](https://www.gnu.org/licenses/gpl-3.0.html)

**OpenAI** — development assistance through Codex and, where present, the Sites starter. Tool assistance is acknowledged separately from human authorship and third-party source attribution.

**Website and automation dependencies** — direct and transitive website package authors, license declarations and retained license notices are recorded in `website/THIRD_PARTY_NOTICES.md`. GitHub Actions used in this repository are credited to GitHub and their contributors. Generated dependency notices supplement these personal thanks; they never replace an upstream license.

## Keeping credit complete

Every contribution that copies, adapts, vendors or depends on external code must identify its project, authors, source URL, version or revision, license and changes. Preserve original copyright and license notices. Credit snippets, design assets and protocol research too, including indirect upstream work. Add dependencies to the generated inventory and keep these acknowledgments available in the app and on the website.

OpenEars-specific work is credited to its contributors through Git history. Author identities are not guessed. Where package metadata omits an author, retain the original copyright notices and a link to the project's contributor history.

OpenEars is independent of Apple, Nothing and the credited projects. Thanks do not imply endorsement. AirPods and Nothing product names belong to their respective owners.

## Multi-brand protocol adapters

Thank you to the authors whose shared work makes these experimental integrations possible. OpenEars adapts a small protocol subset into Swift; it does not bundle the upstream applications or claim their full feature coverage. Original licenses and exact revisions are retained under `Vendor/ProtocolReferences/`. Modifications are identified in each `UPSTREAM.md` and in the Swift source. OpenEars's GPL-3.0 distribution includes the complete adapted source.

- **Tim Schneeberger (timschneeb / ThePBone) and GalaxyBudsClient contributors** — [GalaxyBudsClient](https://github.com/timschneeb/GalaxyBudsClient), GPL-3.0. Adapted `Message/SppMessage.cs`, `Message/SppMessageEnums.cs`, `Utils/Crc16.cs`, `Message/Decoder/StatusUpdateDecoder.cs`, `ExtendedStatusUpdateDecoder.cs`, `NoiseControlUpdateDecoder.cs`, `Message/Encoder/SetEqualizerEncoder.cs`, `Model/Constants.cs` and the selected `Model/Specifications/*DeviceSpec.cs` under `GalaxyBudsClient/`. The regression test includes the original `GalaxyBudsClient.Tests/TestData/ExtendedStatusUpdate/Buds2Pro_rev13.bin` status fixture as bytes. Thanks also to **nift4** for upstream macOS work and the [upstream contributors](https://github.com/timschneeb/GalaxyBudsClient/graphs/contributors). Their UI, translations and device artwork are not part of this adaptation.
- **mos9527, Amr Satrio and SonyHeadphonesClient contributors** — [SonyHeadphonesClient](https://github.com/mos9527/SonyHeadphonesClient), MIT. Adapted framing and the battery, support-function and noise-control definitions in `libmdr/include/mdr/Protocol.hpp`, `ProtocolV2.hpp`, `ProtocolV2T1.hpp`, and behavior in `libmdr/src/HeadphonesV2.cpp` / `HeadphonesV2T1.cpp`. Model selection uses its `docs/device-support/` reports. Thanks to **Plutoberth**, author of the [original SonyHeadphonesClient](https://github.com/Plutoberth/SonyHeadphonesClient), which the upstream identifies as its predecessor. No original Plutoberth application code is directly copied here.
- **shellingtonshreyas and Sony Audio contributors** — [xm6-macos-controller](https://github.com/shellingtonshreyas/xm6-macos-controller), GPL-3.0. Its `SonyProtocol.swift` and `SonyRFCOMMTransport.swift` informed the framing, initialization and acknowledgment research. We used the SonyHeadphonesClient definitions for the common noise-control adapter. Its license and pinned revision are retained with the other protocol references.
- **Oppzippy and OpenSCQ30 contributors** — [OpenSCQ30](https://github.com/Oppzippy/OpenSCQ30), GPL-3.0. Adapted `lib/src/devices/soundcore/common/packet.rs`, packet checksum, state/battery/noise command definitions, and the `a3027`, `a3028`, and `a3040` state/sound-mode layouts. The tests include the upstream manually crafted battery request and noise-notification vectors. Thanks to all [OpenSCQ30 contributors](https://github.com/Oppzippy/OpenSCQ30/graphs/contributors) for the protocol work.

The native RFCOMM transport is OpenEars code using Apple's public IOBluetooth framework. These are user-space control protocols, not kernel drivers. Bluetooth audio remains managed by macOS. No firmware images, extracted manufacturer application assets, vendor logos, private certificates or cloud credentials are distributed. Product names identify compatibility and do not imply endorsement.
