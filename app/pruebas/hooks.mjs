// Resuelve "@/..." y los imports sin extensión para poder ejecutar los .ts con Node.
import { pathToFileURL, fileURLToPath } from 'node:url';
import { existsSync, statSync } from 'node:fs';
import path from 'node:path';

const SRC = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..', 'src');

function conExtension(base) {
  if (existsSync(base) && statSync(base).isFile()) return base;
  for (const e of ['.ts', '.tsx', '/index.ts']) if (existsSync(base + e)) return base + e;
  return null;
}

export async function resolve(specifier, context, nextResolve) {
  let base = null;
  if (specifier.startsWith('@/')) base = path.join(SRC, specifier.slice(2));
  else if ((specifier.startsWith('./') || specifier.startsWith('../')) && context.parentURL?.startsWith('file:')) {
    base = path.resolve(path.dirname(fileURLToPath(context.parentURL)), specifier);
  }
  if (base) {
    const real = conExtension(base);
    if (real) return nextResolve(pathToFileURL(real).href, context);
  }
  return nextResolve(specifier, context);
}
