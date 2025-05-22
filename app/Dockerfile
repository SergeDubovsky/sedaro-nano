FROM rust:1.84 AS builder

# Set a working directory for the Rust build
WORKDIR /usr/src/queries_builder

# Copy the queries project files (contents of ./queries from host) into the current WORKDIR
COPY ./queries .

# Now Cargo.toml is at /usr/src/queries_builder/Cargo.toml
RUN cargo clean
RUN cargo build --release

# Running python
FROM python:3.12

# Create and set working directory
RUN mkdir /app
WORKDIR /app

COPY ./app/requirements.txt ./requirements.txt
RUN pip3 install -r requirements.txt

COPY ./app .

RUN mkdir /queries

# Update the source path for the compiled Rust binary
COPY --from=builder /usr/src/queries_builder/target/release/sedaro-nano-queries /queries/target/release/sedaro-nano-queries

CMD [ "python3", "-m" , "flask", "run", "--debug", "--host=0.0.0.0", "--port=8000" ]