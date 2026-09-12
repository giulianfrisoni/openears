# Ear (3) hardware session — 2026-09-11

Platform: Apple Silicon Mac, macOS 26.6.2. Ear (3) already paired in macOS. User granted/handled connection setup and reported Connected; native accessibility inspection independently confirmed the live control panel.

| Check | Observation |
| --- | --- |
| Identity handshake | Ear (3) model B173 accepted by the driver adapter |
| Left/right battery | Both reported 95% |
| Case battery | Unavailable, rendered as a dash; not verified |
| Noise control | Off → Transparency → Off, each confirmed through device state |
| EQ preset | Balanced → More Bass → Balanced, each confirmed through device state |
| Spatial audio | Off → Fixed → Off, each confirmed through device state |
| Disconnect/reconnect | Controls disconnected, reconnected and recovered current readings |
| UI layout | Native popover visually inspected; no clipping in the tested state |

Original settings restored: ANC off, Balanced EQ, spatial audio off. Audible effects were not independently assessed by the wearer. Low/medium/high/adaptive ANC, Voice/More Treble presets, charging and case states, sleep/wake and alternate firmware remain untested. Support stays experimental until broader acceptance criteria pass.

Automated validation: four catalog tests passed using Apple's Swift Testing framework. Release build and ad-hoc signature verification passed. The Command Line Tools installation requires an explicit TestingMacros path; `scripts/test.sh` detects that layout.

No device serial numbers or Bluetooth addresses are included in this report.

## Multi-brand expansion, 2026-09-12

Fourteen additional profiles and native RFCOMM adapters were added. None of the new models has been physically tested in OpenEars. Protocol regression tests and successful compilation do not establish hardware compatibility. The previous Ear (3) test results above remain the only physical-device evidence. See COMPATIBILITY.md for the candidate list and per-brand control scope.
