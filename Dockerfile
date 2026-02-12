# syntax=docker/dockerfile:1

# Development stage
FROM node:22-alpine AS development
WORKDIR /app

# Create a non-privileged user.
RUN adduser -D -u 10001 appuser

# Download dependencies using cache and bind mounts.
RUN --mount=type=cache,target=/root/.npm \
    --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    npm install --no-save

COPY . .
RUN chown -R appuser:appuser /app

# Switch to non-privileged user.
USER appuser
EXPOSE 5173
CMD ["npm", "run", "dev", "--", "--host"]

# Build stage
FROM development AS builder
RUN npm run build

# Production stage
FROM nginx:alpine AS production
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
