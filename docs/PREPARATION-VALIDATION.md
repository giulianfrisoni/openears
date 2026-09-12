# GitHub preparation validation

The native build, ad-hoc signature check, 12 Swift tests, profile JSON Schema example validation, landing-page production export, and lint checks for the page/layout passed locally.

New tests cover additive profile import, preservation of the existing catalog, ID/name collisions, missing credit, invalid IDs, oversized documents, export/import round-trip, capability gating, bundled author credits, and the documented example.

The native profile form is compiled but has not been visually exercised in this session: the menu-bar accessibility surface was unavailable to automation. Profile persistence/import/export logic is tested at the catalog layer; save-panel and file-permission error flows still need manual testing. CI workflow files are prepared but have not run on GitHub because the repository has not been uploaded.

The landing page was compiled, requested successfully from the local preview and exported to `website/dist/client/`. No browser interaction or screenshot testing was performed. Installed website dependencies have 549 notice entries on this Mac; platform-specific packages may differ on CI.

The new profiles do not expand the prior hardware verification claims. Only the original Ear (3) session in HARDWARE-TEST.md establishes actual device behavior. Full Nothing X feature parity remains a roadmap goal.

## Multi-brand expansion validation (2026-09-12)

- 20 Swift tests pass, including the recorded GalaxyBudsClient Buds2 Pro packet at every fragmentation boundary; checksum rejection and stream recovery; Sony framing/escaping and capability-driven noise format; Soundcore command vectors; preservation of returned noise parameters; bounded malformed-packet handling; bundled-catalog upgrades; and model/feature gates.
- Release build and strict ad-hoc code-signature verification pass. The app bundles all four additional protocol-reference license folders alongside the existing Nothing license.
- Landing-page production export succeeds. The local page returns HTTP 200. The in-app browser was used because the agent-browser CLI is not installed: the four-brand support section was checked visually, its anchor navigation worked, and captured browser error logs were empty. This is a page smoke check, not a full responsive/accessibility audit.
- Acknowledgments and downloadable documentation copies are synchronized. The page retains 549 installed dependency notice entries.
- The user confirmed no additional test headphones are available. All fourteen new models remain hardware-unverified. RFCOMM connection, readback timing, firmware variations, disconnect/reconnect and audible behavior still require physical testing. Native profile forms/save panels were compiled but not visually re-tested.

The earlier validation record above refers to the previous preparation pass; this section supersedes its test count and website smoke-test scope. This section records the checks completed before the first GitHub source upload. No binary release or hosting deployment was performed.
