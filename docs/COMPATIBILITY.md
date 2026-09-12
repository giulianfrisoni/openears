# Device compatibility

OpenEars bundles **15 profiles across four brands**. This is a driver-backed preview, not a claim of full manufacturer-app parity. Only Nothing Ear (3) has been tested on physical hardware in OpenEars. Every newly added model is **experimental and hardware-unverified**.

Selection favors documented open-source protocol coverage: Sony flagships and a mainstream over-ear model, established Galaxy Buds, and widely supported Soundcore headphones. This is not a sales ranking or a claim that every selection is the newest flagship. Older Galaxy Buds and Soundcore models were selected where the available protocol evidence is stronger.

| Brand | Model | Implemented controls | OpenEars hardware validation |
| --- | --- | --- | --- |
| Nothing | Ear (3) | Battery, noise control, EQ presets, fixed spatial audio | Partial; see HARDWARE-TEST.md |
| Nothing | Ear (2024; Bluetooth name `Nothing Ear`) | Battery, noise control, EQ presets | Pending |
| Nothing | Ear (a) | Battery, noise control, EQ presets | Pending |
| Nothing | Headphone (1) | Battery, noise control, EQ presets, fixed spatial audio | Pending |
| Samsung | Galaxy Buds3 Pro | Left/right/case battery, noise control including adaptive, EQ presets | Pending |
| Samsung | Galaxy Buds2 Pro | Left/right/case battery, noise control, EQ presets | Pending |
| Samsung | Galaxy Buds FE | Left/right/case battery, noise control, EQ presets | Pending |
| Sony | WH-1000XM6 | Battery, noise cancelling / ambient / off | Pending |
| Sony | WF-1000XM6 | Left/right/case battery, noise cancelling / ambient / off | Pending |
| Sony | WH-1000XM5 | Battery, noise cancelling / ambient / off | Pending |
| Sony | WF-1000XM5 | Left/right/case battery, noise cancelling / ambient / off | Pending |
| Sony | WH-CH720N | Battery, noise cancelling / ambient / off | Pending |
| Soundcore | Space Q45 (A3040) | Battery in 20% steps, noise cancelling / transparency / normal | Pending |
| Soundcore | Life Q30 (A3028) | Battery in 20% steps, noise cancelling / transparency / normal | Pending |
| Soundcore | Life Q35 (A3027) | Battery in 20% steps, noise cancelling / transparency / normal | Pending |

`Off` in OpenEars corresponds to Soundcore's normal listening mode. A dash means unavailable battery data. Device settings are not optimistically marked successful: OpenEars waits for device readback. The Sony adapter reads the headset's function list to select the supported noise format (0x17 or 0x19). Sony and Soundcore retain the other returned noise parameters when changing mode. Imported profiles cannot define raw packets or executable code.

## Connect and test

1. Reopen the newly built OpenEars app. Choose the device in **Device profiles**.
2. Pair and connect it for audio in macOS Bluetooth Settings. Keep its standard Bluetooth name. Close competing control apps if the control service is busy.
3. Select **Connect to earbuds**. Settings appear only when the device reports them. A Bluetooth socket opening alone does not count as a successful control connection.
4. Verify battery against the manufacturer app, then change one noise mode and check both device readback and the audible effect. Test EQ where offered. Restore the original settings.
5. Record the model, firmware, macOS version, working controls and failed readbacks using the device-support issue template. Do not include device addresses, serial numbers or personal Bluetooth names in public reports.

The new adapters require exactly one matching paired and connected headset and its advertised control service; they never guess an RFCOMM channel. Unlike the Nothing adapter, they do not yet check a returned hardware model ID. If a Samsung name has a suffix or a headset has been renamed, use **Add device profile…**, select the correct hardware model, give it a distinct profile ID and enter its exact Bluetooth name. Saved profiles win over colliding bundled profiles; nonconflicting bundled additions are loaded automatically on startup.

## Sources and limits

- Nothing: [swift-nothing-ear](https://github.com/bestK1ngArthur/swift-nothing-ear), GPL-3.0; existing vendored driver.
- Samsung: [GalaxyBudsClient](https://github.com/timschneeb/GalaxyBudsClient), GPL-3.0; Swift adaptation of its SPP framing, status and setting commands. Buds2 Pro has a recorded upstream status regression fixture; the other models share the documented fields. Firmware-specific extensions are intentionally not parsed.
- Sony: [SonyHeadphonesClient](https://github.com/mos9527/SonyHeadphonesClient), MIT; v2 framing, capability, battery and noise-control subset, plus [Sony Audio](https://github.com/shellingtonshreyas/xm6-macos-controller), GPL-3.0, as a transport/protocol research reference. Upstream model reports are evidence for selecting candidates, not OpenEars hardware tests.
- Soundcore: [OpenSCQ30](https://github.com/Oppzippy/OpenSCQ30), GPL-3.0; the three selected models have documented state layouts. Only its common RFCOMM service is used; firmware exposing a different service will fail closed with an explanation.

All exact revisions, original licenses, authors and adaptation details are retained in `Vendor/ProtocolReferences/` and `ACKNOWLEDGMENTS.md`. Original application assets and firmware are not included. No unlicensed Bose code was copied: the inspected N1et/bose-qc-gui checkout lacked a license file. Bose, Sennheiser and further brands remain future integrations; a public repository alone does not grant permission to reuse its code.

Out of scope in this release: manufacturer firmware updates, cloud finding, account-based switching, advanced/custom EQ on new brands, gesture remapping, head tracking, codecs controlled by macOS, and automatic reconnect after sleep. No Apple proprietary protocols or manufacturer artwork are bundled.
