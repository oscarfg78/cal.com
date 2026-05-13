FROM node:20 AS builder
WORKDIR /app

RUN npm install -g turbo

# We copy everything since the monorepo has many undeclared cross-package dependencies
COPY . .

# Setup environment for build
ARG NEXT_PUBLIC_LICENSE_CONSENT
ARG NEXT_PUBLIC_WEBSITE_TERMS_URL
ARG NEXT_PUBLIC_WEBSITE_PRIVACY_POLICY_URL
ARG CALCOM_TELEMETRY_DISABLED
ARG DATABASE_URL
ARG NEXTAUTH_SECRET=secret
ARG CALENDSO_ENCRYPTION_KEY=secret
ARG MAX_OLD_SPACE_SIZE=6144

ENV NEXT_PUBLIC_LICENSE_CONSENT=$NEXT_PUBLIC_LICENSE_CONSENT \
    NEXT_PUBLIC_WEBSITE_TERMS_URL=$NEXT_PUBLIC_WEBSITE_TERMS_URL \
    NEXT_PUBLIC_WEBSITE_PRIVACY_POLICY_URL=$NEXT_PUBLIC_WEBSITE_PRIVACY_POLICY_URL \
    CALCOM_TELEMETRY_DISABLED=$CALCOM_TELEMETRY_DISABLED \
    DATABASE_URL=$DATABASE_URL \
    NEXTAUTH_SECRET=$NEXTAUTH_SECRET \
    CALENDSO_ENCRYPTION_KEY=$CALENDSO_ENCRYPTION_KEY \
    MAX_OLD_SPACE_SIZE=$MAX_OLD_SPACE_SIZE \
    NODE_OPTIONS=--max-old-space-size=$MAX_OLD_SPACE_SIZE \
    NEXT_PUBLIC_EMBED_FINGER_PRINT=railway \
    NEXT_PUBLIC_EMBED_VERSION=1.5.3 \
    HUSKY=0

# Pre-install fixes:
# 1. Increase timeout for slow connections
# 2. Remove postinstall to avoid Husky/Prisma issues during initial install
RUN yarn config set httpTimeout 1200000 && \
    npm pkg delete scripts.postinstall

RUN yarn install

# Generate Prisma client (manually since we deleted postinstall)
RUN yarn workspace @calcom/prisma run post-install

# Build sequence
RUN yarn workspace @calcom/trpc run build
RUN yarn workspace @calcom/embed-core run build
RUN yarn workspace @calcom/web run copy-app-store-static
RUN yarn workspace @calcom/web run build

# Post-build cleanup to reduce image size
RUN rm -rf node_modules/.cache .yarn/cache apps/web/.next/cache

FROM node:20 AS runner
WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends netcat-openbsd wget && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/apps/web/package.json ./apps/web/package.json
COPY --from=builder /app/apps/web/next.config.js ./apps/web/next.config.js
COPY --from=builder /app/apps/web/public ./apps/web/public
COPY --from=builder /app/apps/web/.next ./apps/web/.next
COPY --from=builder /app/apps/web/next-i18next.config.js ./apps/web/next-i18next.config.js

# Copy shared packages needed at runtime (especially prisma client)
COPY --from=builder /app/packages ./packages
COPY --from=builder /app/node_modules ./node_modules

# Copy scripts and other root files
COPY --from=builder /app/scripts ./scripts

EXPOSE 3000
CMD ["yarn", "workspace", "@calcom/web", "start"]
