#!/usr/bin/env bash
# Runs run_scripts.py with GIMP 2.10 and the GIMP 2 versions of the scripts
# from gimp-plugin-registry in a Debian bookworm container.
# Outputs go to tests/out-gimp2, arguments are passed on to run_scripts.py.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
IMAGE="gimp-elsamuko-gimp2"

docker build -q -t "$IMAGE" "$SCRIPT_DIR" > /dev/null

# plug-in-scatter-hsv was renamed in GIMP 2.10, the old lomo still uses it.
# The old lomo has no "Pink Shadow" color, so it's excluded below.
PRELUDE="(define (plug-in-scatter-hsv . args) (apply plug-in-hsv-noise args))"

docker run --rm \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -v "$REPO_DIR:/work" \
    "$IMAGE" \
    python3 /work/tests/run_scripts.py \
        --gimp gimp-console-2.10 \
        --scripts-dir /usr/share/gimp/2.0/scripts \
        --outdir /work/tests/out-gimp2 \
        --prelude "$PRELUDE" \
        --exclude-option "Pink Shadow" \
        "$@"
