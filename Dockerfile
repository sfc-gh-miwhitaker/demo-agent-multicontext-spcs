# Stage 1: Build the React frontend
FROM --platform=linux/amd64 node:20-alpine AS frontend-build
WORKDIR /app/frontend
COPY frontend/package*.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# Stage 2: Production runtime (Express serves API + static frontend)
FROM --platform=linux/amd64 node:20-alpine
WORKDIR /app
COPY backend/package*.json ./
RUN npm ci --omit=dev
COPY backend/ ./
COPY --from=frontend-build /app/frontend/dist ./public
EXPOSE 8080
ENV PORT=8080
CMD ["node", "server.js"]
