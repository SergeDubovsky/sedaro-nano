# Build stage for Rust binary
FROM rust:1.84.0-slim AS rust-builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /usr/src/queries
COPY ./queries .

# Build optimized release binary
RUN cargo build --release && \
    strip target/release/sedaro-nano-queries

# Final stage with minimal Python image
FROM python:3.12-slim

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN useradd --create-home --shell /bin/bash app

# Set working directory
WORKDIR /app

# Copy and install Python dependencies
COPY ./app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY ./app .

# Create queries directory and copy stripped binary
RUN mkdir -p /queries/target/release
COPY --from=rust-builder /usr/src/queries/target/release/sedaro-nano-queries /queries/target/release/

# Change ownership to app user
RUN chown -R app:app /app /queries

# Switch to non-root user
USER app

# Expose port
EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "app:app"]