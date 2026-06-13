# dokploy-build-failure

A deliberately broken React + TypeScript + Vite project used to test how a
deployment platform (e.g. [Dokploy](https://dokploy.com/)) handles a **failing
Docker build**.

## What it's for

This repo exists to **build and fail on purpose**. It is a fixture for
exercising failure paths in CI/CD and deployment tooling — verifying that a
failed build is reported correctly, surfaces useful logs, and does not deploy a
broken image.

## How it fails

The app is a standard Vite SPA. The build script runs:

```
tsc -b && vite build
```

The failure is introduced in `src/App.tsx`, which imports a static asset that
does not exist:

```ts
import heroImg from './assets/hero-banner.png' // file is actually hero.png
```

Because Vite declares an ambient `*.png` wildcard module, this **passes
`tsc -b`** (TypeScript accepts any import path matching the wildcard) but
**fails at `vite build`**, where the Rolldown bundler cannot resolve the module:

```
Module not found.
src/App.tsx → import heroImg from "./assets/hero-banner.png"
```

So the failure happens specifically during the `vite build` stage, not during
type-checking.

## Docker

A multi-stage `Dockerfile` builds and serves the app:

```bash
docker build -t dokploy-build-failure .
```

The build aborts at the `RUN pnpm build` line, exactly where the deployment
build is expected to fail.

## Fixing it (if you want a passing build)

Restore the import to the asset that actually exists:

```diff
-import heroImg from './assets/hero-banner.png'
+import heroImg from './assets/hero.png'
```
