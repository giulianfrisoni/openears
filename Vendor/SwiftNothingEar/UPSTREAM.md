# Vendored dependency

Source: https://github.com/bestK1ngArthur/swift-nothing-ear
Revision: 25d2ba4a69fe72a55f5cbf9e86205e6e47ff8cad
License: GPL-3.0; see LICENSE.md. Original authors retain their copyrights.
Upstream credits Ear (web): https://github.com/radiance-project/ear-web.

Vendored on 2026-09-11 so builds are reproducible and do not need a network connection.
OpenEars changes:

- Accept a device-name predicate and filter existing connections and explicit connections.
- Expose a read-only refresh for battery, ANC, EQ and spatial audio.
- Use the characteristic's supported write type.
- Decode the command identifier without an unaligned memory load.

The upstream Ear (3) implementation is experimental. Do not interpret inclusion as verified support.
