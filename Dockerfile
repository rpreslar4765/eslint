# ESLint Container - Multi-stage build for optimized production image

# Build stage
FROM node:18-slim AS builder

# Add metadata labels
LABEL maintainer="ESLint Team"
LABEL description="ESLint - An AST-based pattern checker for JavaScript"
LABEL version="10.0.0-alpha.0"

# Set work directory
WORKDIR /app

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Copy package files first for better layer caching
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy rest of the application files
COPY . .

# Runtime stage
FROM node:18-slim AS runtime

# Add metadata labels
LABEL maintainer="ESLint Team"
LABEL description="ESLint - An AST-based pattern checker for JavaScript"
LABEL version="10.0.0-alpha.0"

# Set work directory
WORKDIR /app

# Install runtime dependencies only
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for security
RUN groupadd -r eslint && useradd -r -g eslint eslint

# Copy package files
COPY package*.json ./

# Install production dependencies only
RUN npm install --omit=dev && npm cache clean --force

# Copy application files from builder
COPY --from=builder /app/bin ./bin
COPY --from=builder /app/lib ./lib
COPY --from=builder /app/conf ./conf
COPY --from=builder /app/messages ./messages

# Change ownership to non-root user
RUN chown -R eslint:eslint /app

# Switch to non-root user
USER eslint

# Health check - validate ESLint CLI works
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node bin/eslint.js --version || exit 1

# Expose metadata
LABEL org.opencontainers.image.title="ESLint"
LABEL org.opencontainers.image.description="An AST-based pattern checker for JavaScript"
LABEL org.opencontainers.image.url="https://eslint.org"
LABEL org.opencontainers.image.source="https://github.com/eslint/eslint"
LABEL org.opencontainers.image.vendor="ESLint Team"
LABEL org.opencontainers.image.licenses="MIT"

# Default command - run ESLint help
CMD ["node", "bin/eslint.js", "--help"]
