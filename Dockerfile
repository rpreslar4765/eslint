# syntax=docker/dockerfile:1

# Build stage
FROM node:20-slim AS builder

WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Build if needed (uncomment if you have a build step)
# RUN npm run build

# Remove dev dependencies
RUN npm prune --production

# Runtime stage
FROM node:20-slim AS runtime

WORKDIR /app

# Copy built application from builder
COPY --from=builder /app .

# Create a non-root user
RUN useradd -m -u 1001 eslint && chown -R eslint:eslint /app
USER eslint

# Expose port if needed
EXPOSE 3000

# Start the application
CMD ["node", "index.js"]
