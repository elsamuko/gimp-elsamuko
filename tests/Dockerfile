# GIMP 2.10 with the GIMP 2 versions of the scripts from gimp-plugin-registry,
# used by run_scripts_gimp2.sh to render reference images.
FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends gimp gimp-plugin-registry python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /work
