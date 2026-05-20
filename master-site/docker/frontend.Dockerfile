FROM node:20-alpine

WORKDIR /app

# Copy package files first for caching
COPY frontend/package.json frontend/package-lock.json* frontend/yarn.lock* ./
RUN npm install --legacy-peer-deps 2>/dev/null || true

# Copy app
COPY frontend/ .
RUN npm run build 2>/dev/null || true

EXPOSE 3000

CMD ["node", ".output/server/index.mjs"]
