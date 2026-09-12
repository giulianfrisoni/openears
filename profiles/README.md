# Device-profile template (schema v1)

Start with `nothing-ear-2.example.json`. This is an importable example for hardware already known to the included Nothing driver; it is **not hardware-verified**. Validate its structure with `profile.schema.json`. The app additionally checks collisions and validates author/source fields before saving.

## Add a device in the app

Open Device profiles → **Add device profile…**. Choose a hardware model, give it a unique ID, enter the exact Bluetooth name(s), choose the exposed controls, and credit yourself and your sources. Save adds the profile to your local catalog. It does not pair or automatically connect the device. Select it and connect from the menu bar when ready.

**Import…** accepts one profile document or a complete v1 catalog and adds its profiles to your existing catalog. Duplicate IDs or Bluetooth names reject the whole import, leaving the original catalog intact. **Export…** saves the selected profile as a shareable v1 document. A local profile file contains no Bluetooth addresses or serial numbers.

## Fields

| Field | Meaning and rule |
| --- | --- |
| `schemaVersion` | `1`; other versions are rejected. |
| `profile.id` | Stable lowercase ID, 1–64 characters: letters, numbers, hyphens; start with a letter or number. Unique across the catalog. |
| `name`, `vendor` | Nonempty human-readable labels. |
| `driver` | Installed protocol adapter ID. Currently `nothing-ble-v1`. Unknown drivers can be cataloged but cannot connect. |
| `model` | Exact identity code returned by the driver, e.g. `B173` for Ear (3). A display name alone never overrides a model mismatch. |
| `names` | Exact Bluetooth discovery aliases. Matching ignores case and outer whitespace. Aliases must be unique within and across profiles. No regex, prefix wildcard or device addresses. |
| `features` | Entries with a unique `id`, display `name`, `status` and explanatory `note`. |
| `attribution.authors` | At least one nonblank public author name/handle. Include upstream authors for reused work. |
| `attribution.source` | HTTPS link to the profile or protocol source. |
| `attribution.license` | Actual license identifier for the profile; do not invent an upstream license. |
| `attribution.notes` | Protocol revision, changes, upstream lineage and hardware evidence links where available. |

Status is `planned`, `experimental`, or `verified`. The creation form only emits experimental features. Use verified only with a reproducible firmware/macOS hardware report. Status is a contributor claim, not a digital signature; imports are not trusted certification. Planned features are never enabled. Unknown feature IDs remain descriptive and cannot invoke arbitrary commands.

## Installed driver boundary

The current adapter exposes battery, ANC, EQ presets and off/fixed spatial audio as appropriate for its model. Its model registry includes B173, B155, B171, B162, B170 and B172. Only Ear (3) has been exercised in an OpenEars hardware session. Other upstream models and additional features require adapter review before being added to this registry. Head-tracking modes are not exposed by this adapter even where the underlying hardware may support them.

Known model + supported feature + enabled profile status + confirmed connection/readback are all required for controls. A profile cannot provide packet bytes, executable scripts, pairing credentials or firmware images. Adding a new Bluetooth protocol requires app/driver work, not a JSON workaround.

Maximum import size is 1 MB. JSON Schema rejects unknown keys as an authoring aid; the Swift decoder ignores unknown keys for forward-compatible metadata, but never executes them. Legacy v1 catalogs without attribution can still be read at startup; newly added/imported profiles must include attribution.

## Multi-brand registry (catalog revision 2)

The app includes `nothing-ble-v1`, `samsung-spp-v1`, `sony-mdr-v2` and `soundcore-spp-v1`. The **Add device profile…** form selects the appropriate driver, available features, upstream source and authors from the hardware model. The JSON envelope and schema remain version 1. See `docs/COMPATIBILITY.md` for the 15 bundled profiles and exact feature scope.

For Samsung use model IDs `SM-R630`, `SM-R510` or `SM-R400`; Sony uses its printed model name (`WH-1000XM6`, `WF-1000XM6`, `WH-1000XM5`, `WF-1000XM5`, `WH-CH720N`); Soundcore uses `A3040`, `A3028` or `A3027`. The driver, model and vendor must agree with the registry. These are compiled protocol identities, not free-form packet definitions. New models need registry/adapter work if not already listed.

Use an exact Bluetooth alias, including a Samsung suffix if present. To add a renamed instance of a bundled model, choose a new profile ID and aliases that are not already assigned. A catalog upgrade preserves installed profiles and adds only nonconflicting bundled entries; collisions do not silently replace user data. Imports remain atomic and reject the entire import on a duplicate ID or alias.

All new model features must remain experimental until hardware testing is recorded. A profile's `verified` label cannot add controls that the compiled adapter does not implement. Author attribution never replaces retaining the upstream license and documenting an adaptation.
