# Web Deploy

The web app is deployed manually to Cloudflare Workers. This is intentional: [vinext](https://vinext.io) is an experimental Vite-based Next.js runtime, so we want a human to verify each build before it reaches production.

## Stack

- **Runtime:** Cloudflare Workers (via [`@cloudflare/vite-plugin`](https://www.npmjs.com/package/@cloudflare/vite-plugin) and `wrangler`)
- **Framework:** Next.js 16 (App Router) compiled by `vinext`
- **Worker entry:** [`worker/index.ts`](./worker/index.ts) wires Cloudflare Images binding into vinext's image optimizer, then delegates everything else to `vinext/server/app-router-entry`. Auto-regenerates on `vinext deploy` if deleted.
- **Worker config:** [`wrangler.jsonc`](./wrangler.jsonc) configures `ASSETS` binding serves `dist/client`, `IMAGES` binding handles `/_vinext/image`.

## Prerequisites

1. **Node v24.14.0 or LTS**
2. **pnpm** latest.
3. **Cloudflare auth.** One-time login is enough; no token needs to be stored:
   ```bash
   pnpm exec wrangler login
   ```
   Alternatively, export `CLOUDFLARE_API_TOKEN` (token must have `Workers Scripts:Edit` and `Account Settings:Read`).
4. **Verify the build locally** before every deploy:
   ```bash
   pnpm install
   pnpm build      # tsgo --noEmit && vinext build
   pnpm start      # serves the built output at http://localhost:3000
   ```
   Walk through the critical user paths (auth, main flows) before continuing. If `pnpm build` fails on `tsgo`, fix the type errors, **DO NOT deploy a build that skips type checking**.

## Deploy

```bash
pnpm deploy       # vinext deploy -> wrangler deploy under the hood
```

Expected output ends with the deployed URL and a version ID. Visit the URL and re-run the same smoke test you did locally.

## Troubleshooting

| Symptom | Fix |
| --- | --- |
| `CLOUDFLARE_API_TOKEN` missing | Run `pnpm exec wrangler login` (preferred) or export a scoped token. |
| `tsgo` type errors during `pnpm build` | Fix at the source. The build must be green; do not bypass `tsgo --noEmit`. |
| `/_vinext/image` returns 500 in prod | Confirm the `IMAGES` binding still exists in `wrangler.jsonc` and that the account has Cloudflare Images enabled. |
| Static assets 404 | Confirm `dist/client` was produced by `vinext build` and that the `ASSETS.directory` in `wrangler.jsonc` still points to it. |
| Worker entry behaving oddly | Delete `worker/index.ts` and re-run `pnpm deploy`; vinext will regenerate it. |

## Rollback

List recent deployments and roll back to a known-good version:

```bash
pnpm exec wrangler deployments list
pnpm exec wrangler rollback <version-id>
```

Rollback is instant and does not rebuild. After rolling back, open an issue describing what broke so the next deploy doesn't reintroduce it.
