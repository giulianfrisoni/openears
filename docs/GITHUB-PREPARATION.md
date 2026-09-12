# GitHub upload preparation

Public source repository: https://github.com/giulianfrisoni/openears

A signed binary release and website hosting remain separate work.

Release checklist:

1. Source repository created under giulianfrisoni/openears. Preserve author commits, original upstream notices and pinned source references with future changes.
2. Check the Actions results: native app tests/build and website production build. Hardware tests are recorded separately; CI cannot verify a physical headset.
3. The landing page links to the real repository. Add a binary download button only after a release exists.
4. Choose website hosting. The landing page exports static files; see website/README.md. For GitHub Pages project sites, build with the repository base path and test asset paths before publishing. No deployment workflow is enabled yet.
5. For binary releases, distribute the corresponding source, LICENSE, ACKNOWLEDGMENTS.md and vendored notices together. The local app is ad-hoc signed; Developer ID signing and notarization are still needed for ordinary public distribution.

Suggested description: Native macOS earbud controls, starting with Nothing Ear (3). AirPods-like convenience, brand-specific features, open device profiles.

Suggested topics: macos, swift, swiftui, bluetooth, earbuds, headphones, nothing, open-source.

The GPL source license does not relicense Apple's SDKs or third-party materials. Website package inventory includes declared licenses and preserved notices. Recheck licenses and author credits whenever dependencies or copied components change. For the Ear (web) lineage, the repository license badge and README have historically differed; OpenEars does not directly vendor its code, and any future direct reuse must verify the specific files' license.
