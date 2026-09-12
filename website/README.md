# OpenEars landing page

Prepared for the project's first GitHub upload. No deployment or public download links are enabled. This site is informational; the illustrated controls never access Bluetooth.

## Develop and build

Requires Node 22.13+ and pnpm 11.19.0. From this directory:

```sh
pnpm install --frozen-lockfile
pnpm dev
pnpm build
```

The site uses the OpenAI Sites scaffold, Vinext, React and Tailwind CSS, with the scaffold's shadcn components retained. Versions are pinned in pnpm-lock.yaml. `pnpm build` regenerates THIRD_PARTY_NOTICES.md from installed package metadata and original license files before building. Regenerate on the target release platform to capture its optional packages.

The three allowlisted dependency build scripts (esbuild, sharp and workerd) install their normal platform tools. No other dependency build scripts are enabled.

`next.config.ts` requests a static export. The resulting `dist/client/` directory can be hosted after repository links and hosting are configured. For GitHub Pages under `/repository-name`, set `PAGES_BASE_PATH=/repository-name` when building. Do not deploy server intermediates or node_modules.

## Credits

The page's author section and public ACKNOWLEDGMENTS.md explain upstream contributions. THIRD_PARTY_NOTICES.md inventories installed package authors, declared licenses and original notices. SHADCN-LICENSE.txt covers the copied shadcn/ui component foundation. Downloadable project documents are synchronized by `python3 ../scripts/sync-credits.py`.

OpenEars wordmark and page styling are original contributions. Fonts use the visitor's system fonts. No proprietary earbud photographs, Apple logos or Ear (web) artwork are copied. The interface illustration is labeled and uses readings from the project's recorded test session.
