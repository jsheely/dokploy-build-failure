# syntax=docker/dockerfile:1

# ---- Build stage ----
FROM node:24-alpine AS build
WORKDIR /app

# Enable pnpm via corepack
RUN corepack enable

# Install dependencies (cached unless lockfile/manifest change)
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile

# Copy the rest of the source and build
COPY . .
RUN pnpm build

# ---- Runtime stage ----
FROM node:24-alpine AS runtime
WORKDIR /app

RUN corepack enable

# Only need the production manifest + built output to serve the preview
COPY --from=build /app/package.json /app/pnpm-lock.yaml /app/pnpm-workspace.yaml ./
COPY --from=build /app/node_modules ./node_modules
COPY --from=build /app/dist ./dist
COPY --from=build /app/vite.config.ts ./vite.config.ts

EXPOSE 4173

# Serve the built app; --host makes it reachable from outside the container
CMD ["pnpm", "preview", "--host", "0.0.0.0", "--port", "4173"]
