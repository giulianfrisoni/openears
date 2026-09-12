// Original OpenEars tooling. Package authors and license text come from installed upstream metadata.
import fs from 'node:fs';
import path from 'node:path';
const root = process.cwd();
const store = path.join(root, 'node_modules/.pnpm');
const packages = new Map();
function inspect(dir) {
  const file = path.join(dir, 'package.json');
  if (!fs.existsSync(file)) return;
  const pkg = JSON.parse(fs.readFileSync(file, 'utf8'));
  if (!pkg.name || !pkg.version) return;
  const key = `${pkg.name}@${pkg.version}`;
  if (packages.has(key)) return;
  const person = p => typeof p === 'string' ? p : p?.name || '';
  const authors = [person(pkg.author), ...(pkg.contributors || []).map(person)].filter(Boolean);
  const repository = typeof pkg.repository === 'string' ? pkg.repository : pkg.repository?.url;
  const licenses = fs.readdirSync(dir).filter(n => /^(licen[cs]e|copying|notice)(\.|$)/i.test(n)).filter(n => fs.statSync(path.join(dir,n)).isFile())
    .map(n => `${n}\n\n${fs.readFileSync(path.join(dir,n),'utf8')}`);
  packages.set(key, { name:key, authors, repository:repository || pkg.homepage || '', license:pkg.license || pkg.licenses || 'Not declared', notices:licenses });
}
for (const entry of fs.readdirSync(store).sort()) {
  const dir = path.join(store,entry,'node_modules');
  if (!fs.existsSync(dir)) continue;
  for (const name of fs.readdirSync(dir).sort()) {
    if (name.startsWith('@')) {
      for (const child of fs.readdirSync(path.join(dir,name)).sort()) inspect(path.join(dir,name,child));
    } else inspect(path.join(dir,name));
  }
}
const entries = [...packages.values()].sort((a,b)=>a.name.localeCompare(b.name));
if (!entries.length) throw new Error('Install website dependencies before generating notices.');
let output = '# Website dependency acknowledgments and license notices\n\nThank you to the authors and contributors of every package below. This inventory includes build-time and transitive dependencies installed for this platform, not just browser-shipped code. Generated from installed package metadata; original notices are retained verbatim. Platform-optional dependencies not installed here are listed separately from the lockfile below.\n\n';
output += 'The OpenAI Sites starter generated the project scaffold. The shadcn/ui components copied into components/ui, lib and hooks originate from shadcn and contributors (https://github.com/shadcn-ui/ui, MIT); see SHADCN-LICENSE.txt. OpenEars page content, styling, profile tooling and wordmark are original project contributions. System fonts are supplied by the visitor’s OS; no external font or photo assets are shipped.\n\n';
for (const pkg of entries) {
  output += `## ${pkg.name}\n\nAuthors: ${pkg.authors.join('; ') || 'Not supplied in package metadata; see preserved copyright notices and upstream contributors.'}\n\nSource: ${pkg.repository || 'See the package on https://www.npmjs.com/'}\n\nDeclared license: ${typeof pkg.license === 'string' ? pkg.license : JSON.stringify(pkg.license)}\n\n`;
  output += pkg.notices.length ? pkg.notices.map(n=>`~~~~text\n${n}\n~~~~\n`).join('\n') : 'No top-level license file supplied by this package. Consult its upstream source before redistribution.\n';
}
output += '\n## Complete locked dependency graph\n\nThe package lock is included for audit of platform-specific optional packages as well as installed dependencies. Regenerate notices on every release platform; license text from packages not installed on this platform is not claimed to be included.\n\n~~~~yaml\n'+fs.readFileSync('pnpm-lock.yaml','utf8')+'\n~~~~\n';
fs.writeFileSync('THIRD_PARTY_NOTICES.md',output);
fs.mkdirSync('public',{recursive:true});fs.writeFileSync('public/THIRD_PARTY_NOTICES.md',output);
fs.copyFileSync('SHADCN-LICENSE.txt', 'public/SHADCN-LICENSE.txt');
console.log(`Credited ${entries.length} installed packages with retained license notices.`);
