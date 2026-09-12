# Familiar on your Mac. Faithful to your earbuds.

OpenEars aims to make compatible earbuds feel as convenient on macOS as AirPods, while keeping the capabilities that distinguish their hardware. This is an experience goal, not a promise to impersonate an Apple device or unlock Apple-only services.

## Everyday experience

- A quiet menu bar presence, readable left/right/case battery and connection status.
- Dependable reconnect after wake and normal Bluetooth reconnection, without taking over pairing.
- Quick noise control, optional connection/battery notifications and keyboard shortcuts.
- Launch at login and accessible native controls, with sensible defaults and no account.
- Respect system audio routing and the user's chosen microphone.

The current preview implements the menu bar, live control connection, battery and a subset of sound controls. Reconnect after sleep, shortcuts, notifications and launch at login are planned.

## Preserve device-specific functionality

Use two layers: common daily controls in the popover, and a per-device settings view for EQ, gestures, multipoint, latency, fit tests, case controls and other special functions. A shared interface must not force every model into the lowest common feature set. Each feature records implementation status and hardware verification independently.

When a command is unsupported or its state unknown, say so. Do not replace a real hardware feature with a cosmetic switch. Do not reset custom settings when changing devices, profiles or app versions.

## Boundaries

Apple-account pairing sync, Apple's Find My network, Apple-specific automatic switching and hardware-dependent head tracking are not delivered by this app. Use public macOS capabilities and each headset's actual protocol. Where an equivalent local workflow is possible, describe what it does accurately instead of claiming parity.

For Ear (3), retain the roadmap for Super Mic/TALK, advanced EQ, gestures, multipoint and the remaining Nothing X features. Mark features as verified only after repeatable tests on the relevant firmware.
