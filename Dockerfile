FROM node:18-alpine

WORKDIR /app

# Kopieer package.json en package-lock.json
COPY package.json package-lock.json ./

# Installeer dependencies
RUN npm install --production=false

# Kopieer de rest van de applicatie
COPY . .

# Build de applicatie
RUN npm run build

# Maak omgevingsvariabelen aan
ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME=0.0.0.0

# Expose de poort
EXPOSE 3000

# Start de server
CMD ["npm", "start"]
