// Netlify Edge Function — password gate for docs site
// Set DOCS_PASSWORD env var in Netlify dashboard (Site settings → Environment)
// Default fallback is used only in dev; always set the env var in production.

const GATE   = '/gate.html';
const SKIP_EXTS = ['.js','.css','.png','.jpg','.jpeg','.svg','.ico','.woff','.woff2','.json','.xml','.txt','.webp','.map'];
const SKIP_PFX  = ['/assets/', '/img/', '/_pagefind/', '/static/'];

export default async function auth(request, context) {
  const url  = new URL(request.url);
  const path = url.pathname;

  // Always allow the gate page and all static assets
  if (path === GATE ||
      SKIP_EXTS.some(e => path.endsWith(e)) ||
      SKIP_PFX.some(p => path.startsWith(p))) {
    return context.next();
  }

  const password = Deno.env.get('DOCS_PASSWORD') || 'serverkit25';
  const expected = await sha256(password);

  // Parse cookies
  const cookies = Object.fromEntries(
    (request.headers.get('Cookie') || '')
      .split(';')
      .map(c => c.trim().split('='))
      .filter(([k]) => k)
      .map(([k, ...v]) => [k.trim(), v.join('=').trim()])
  );

  // Valid cookie → pass through
  if (cookies['hub_docs_auth'] === expected) {
    return context.next();
  }

  // Bad cookie present → redirect to gate with err flag (clears cookie)
  const to = new URL(GATE, request.url);
  to.searchParams.set('from', path);
  if (cookies['hub_docs_auth']) to.searchParams.set('err', '1');
  return Response.redirect(to.toString(), 302);
}

async function sha256(msg) {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(msg));
  return Array.from(new Uint8Array(buf)).map(b => b.toString(16).padStart(2,'0')).join('');
}
