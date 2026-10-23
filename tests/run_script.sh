#!/usr/bin/env bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIMP_SCRIPTS_DIR="$SCRIPT_DIR/../scripts"

GIMP_SCRIPT="$GIMP_SCRIPTS_DIR/elsamuko-lomo.scm"
SCRIPT_CALL="elsamuko-lomo-batch \"$SCRIPT_DIR/after.jpg\" 1.5 0.1 0.1 0.8 5 1 3 128 1 FALSE FALSE FALSE FALSE 0 0 115"

# GIMP_SCRIPT="$GIMP_SCRIPTS_DIR/elsamuko-national-geographic.scm"
# SCRIPT_CALL="elsamuko-national-geographic-batch \"$SCRIPT_DIR/after.jpg\" 60 0.5 50 50 0.4 TRUE 1"

cp "$SCRIPT_DIR/../docs/samples/landscape-orig.jpg" "$SCRIPT_DIR/before.jpg"
cp "$SCRIPT_DIR/../docs/samples/landscape-orig.jpg" "$SCRIPT_DIR/after.jpg"

gimp-console -i -d -f -n \
    --verbose \
    --batch-interpreter=plug-in-script-fu-eval \
    -b "(load \"$GIMP_SCRIPT\") ($SCRIPT_CALL)" \
    --quit
