# OpenEars project instructions

- Aim for AirPods-like everyday convenience on macOS while preserving each headset's special features. Never claim unavailable Apple-only capabilities or untested hardware support.
- Attribute every external dependency, copied/adapted snippet, asset and protocol reference to its original authors and project. Preserve license and copyright notices and record upstream revisions and modifications. Maintain ACKNOWLEDGMENTS.md, app credits and website notices together.
- Keep catalog changes separate from executable drivers. New profiles must include author/source/license information. No scripts, arbitrary command bytes or firmware images in profiles.
- Preserve existing user profiles on import; reject ambiguous identities and failed validation without changing the installed catalog.
- Run `python3 scripts/sync-credits.py` after changing acknowledgments or downloadable project documents. Run `sh scripts/test.sh` and `sh scripts/build-app.sh` for native changes. For website changes, run `pnpm build` from website; it regenerates dependency notices.
- Use docs/HARDWARE-TEST.md as the boundary of hardware-verified behavior. Do not label driver capabilities as tested simply because they are implemented upstream.
- Do not publish the repository, website or a release as part of mere preparation work.
