#!/usr/bin/env python3
"""Keep source acknowledgments identical in the app and landing-page downloads."""
from pathlib import Path
import sys

root = Path(__file__).resolve().parent.parent
pairs = [(root / "ACKNOWLEDGMENTS.md", root / "Sources/OpenEarsCore/Resources/ACKNOWLEDGMENTS.md")]
if (root / "website").is_dir():
    pairs += [(root / name, root / "website/public" / name) for name in
              ("ACKNOWLEDGMENTS.md", "LICENSE", "README.md", "CONTRIBUTING.md")]
pairs.append((root / "docs/COMPATIBILITY.md", root / "website/public/COMPATIBILITY.md"))
for source, target in pairs:
    data = source.read_bytes()
    if "--check" in sys.argv:
        if not target.exists() or target.read_bytes() != data:
            raise SystemExit(f"Out-of-date credit/document copy: {target.relative_to(root)}")
    else:
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
print("Credits and document copies are in sync.")
