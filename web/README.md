# Hookra Web

This folder contains the web application for Hookra, built with vinext (a next-compatible framework for cloudflare workers). It serves as both an admin panel for managing the Hookra service and a user interface for interacting with the system.

## Getting Started

First, install the Typescript Native Preview extension for VS Code, which provides support for `tsgo`, then activate the extension with the command `TypeScript (Native Preview): Enable (Experimental)`

> [!NOTE]
> The `tsgo` command is used to check for type errors before building the application. It's substantially faster than `tsc --noEmit` but still in active development as Typescript 7.0.

Then, run the development server:

```bash
pnpm dev
```

Open [http://localhost:3000](http://localhost:3000) with your browser.

## Build and Run

Build the app:

```bash
pnpm build
```

Start the production server locally:

```bash
pnpm start
```

## Deploy to Cloudflare Workers

Deploy with vinext:

```bash
pnpm deploy
```
