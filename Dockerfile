FROM node:18-alpine AS base

# Installeer dependencies alleen
FROM base AS deps
WORKDIR /app
# Installeer Python en build tools voor native modules
RUN apk add --no-cache python3 make g++ pkgconfig pixman-dev cairo-dev pango-dev jpeg-dev giflib-dev
# Maak een symlink van python3 naar python
RUN ln -sf /usr/bin/python3 /usr/bin/python
# Stel het Python pad in voor npm
ENV PYTHON=/usr/bin/python3
COPY package.json package-lock.json ./
# Gebruik npm install in plaats van npm ci voor betere compatibiliteit
RUN npm install --production=false

# Bouw de applicatie
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
# Installeer nodemailer expliciet
RUN npm install nodemailer
RUN npm run build

# Productie image, kopieer alle bestanden en start de app
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production

# Maak een niet-root gebruiker aan
RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

# Kopieer de nodige bestanden
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000

ENV PORT 3000

# Start de server
CMD ["node", "server.js"] 