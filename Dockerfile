FROM node:18-alpine AS builder

WORKDIR /app

# Installeer dependencies
COPY package.json package-lock.json ./
RUN npm ci

# Kopieer de broncode
COPY . .

# Build de applicatie
RUN npm run build

# Productie image
FROM node:18-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

# Kopieer relevante bestanden van builder stage
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static

# Belangrijk: Maak een symbolische link voor statische bestanden
RUN ln -s /app/public /app/public
RUN mkdir -p /app/static
RUN ln -s /app/.next/static /app/static

EXPOSE 3000

CMD ["node", "server.js"]
