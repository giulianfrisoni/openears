# Direction

See PRODUCT-DIRECTION.md for the AirPods-like experience goal, profiles/README.md for the importable device schema, and ACKNOWLEDGMENTS.md for attribution requirements. The app now includes profile creation, additive import, export and author credits. These are configuration features, not proof of broader hardware support.

## Native first

Keep the primary interface in a SwiftUI menu bar popover. Let macOS own pairing, audio streaming and system audio routing. Add launch at login, reconnect after wake, keyboard shortcuts and accessibility verification once the control connection is dependable. Avoid changing audio input automatically, since activating headset microphones can change audio quality.

## Ear (3) acceptance

For each feature record firmware, macOS version, request/response evidence, hardware behavior and disconnect/reconnect behavior. “Verified” means tested on hardware, not merely present in a driver. Never publish raw serial numbers or Bluetooth addresses in test reports.

1. Establish BLE controls on a paired Ear (3), read identity and firmware, verify battery for left/right/case, test case closed and one earbud absent.
2. Set and read back every ANC level, all four EQ presets and fixed/off spatial audio. Confirm audible behavior with the wearer and restore their original settings.
3. Verify in-ear detection, low-lag mode and bass level encoding; expose individually confirmed state and respect spatial/EQ/bass interactions.
4. Implement gesture readback and remapping, advanced eight-band EQ, dual connection, per-ear find with reliable stop, fit test and Personal Sound where accessible.
5. Investigate Super Mic/TALK button audio routing and host-specific behavior. Nothing OS Essential Space functionality is a separate integration, not automatically available on macOS.
6. Treat firmware updating as its own project: signed official images, compatibility checks, battery requirements, interruption recovery and hardware validation before enabling it.

Official references:

- https://nothing.tech/products/ear-3
- https://support.nothing.tech/hc/en-us/categories/37810319830289
- https://support.nothing.tech/hc/en-us/articles/38937928387985-How-do-I-operate-the-control-functions-on-Ear-3

## Profile distribution

Start with readable JSON in version control: reviewable diffs, immutable revisions and manual imports. A database can later publish the same catalog format. Add signed manifests, pinned verification keys, compatibility ranges, rollback protection, size limits and last-known-good retention before automatic downloads. Do not fetch executable drivers from the profile database.

Move model capabilities out of upstream Swift enums into validated protocol-family descriptors over time. Keep framing, checksums, authentication and complex operations in drivers. Adding all brands is a long-term interoperability effort; each vendor may use BLE, classic Bluetooth RFCOMM, USB HID or a proprietary authenticated protocol.

## Known prototype limits

- One active device; factory-name discovery; no automatic reconnect after disconnection.
- Advanced features are listed as planned, not presented as working switches.
- No firmware updater, cloud catalog backend, automatic profile updates or notarized distribution.
- Upstream discovery and packet handling still need validation across firmware revisions, packet fragmentation and malformed responses.
- macOS codec and mobile-only ecosystem features cannot be added by a profile alone.
