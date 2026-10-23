#!/usr/bin/env python3
"""Run the batch versions of all scripts on a sample image.

Every script runs with its default parameters. Parameters with a list of
values (like the "Colors" option of elsamuko-lomo) are looped, one output
image per value.

Usage: run_scripts.py [-i INPUT] [-o OUTDIR] [-g GIMP] [-s SCRIPTS_DIR] [-p PRELUDE] [-x OPTION] [script ...]
"""

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
GIMP_SCRIPTS_DIR = SCRIPT_DIR.parent / "scripts"
DEFAULT_INPUT = SCRIPT_DIR.parent / "docs" / "samples" / "landscape-orig.jpg"
DEFAULT_OUTDIR = SCRIPT_DIR / "out"

LOMO_COLORS = ["Neutral", "Old Red", "XPro Green", "Blue", "XPro Autumn",
               "Movie", "Vintage", "Xpro LAB", "Light Blue", "Pink Shadow",
               "Redscale", "Retro B/W", "Paynes B/W", "Sepia"]
NG_TINTS = ["Neutral", "Red", "Blue"]

# Batch arguments after the file pattern. An option list is looped,
# its value is the index of the option name.
SCRIPTS = {
    "elsamuko-lomo": [
        1.5, 10, 10,                      # vignetting, saturation, contrast
        0.8, 5, 1, 3, 128,                # sharp, wide angle, gauss, motion, grain
        LOMO_COLORS,
        "FALSE", "FALSE", "TRUE", "FALSE",  # invert A/B, double/black vignetting
        0, 0, 115,                        # center x/y, radius
    ],
    "elsamuko-national-geographic": [
        60, 0.5, 50, 50, 0.4, "TRUE",
        NG_TINTS,
    ],
    "elsamuko-photochrom": [
        "'(255 128 0)", "'(255 68 112)",  # screen, multiply color
        60, 60, 0, 100,                   # contrast, b/w merge, gradient offsets
        "FALSE", "FALSE",                 # dodge, retro
    ],
    "elsamuko-technicolor-2-color": [
        0.95, "TRUE",                     # jpeg quality (0..1), overwrite
        1.0, 0.5,                         # red part, green part
        0, 255, 255, 255, 0, 0, 255, 255, 0,  # cyan, red, yellow fill
        "TRUE",                           # sharpen
    ],
    "elsamuko-technicolor-3-color": [
        1.2, 1.2, 1.2,                    # red part, green part, blue part
        "'(0 255 255)", "'(255 0 255)", "'(255 255 0)",  # cyan, magenta, yellow
        60,                               # sharpen opacity
        "FALSE", "TRUE", "TRUE",          # stretch, retro, extra intensity
    ],
}


def variants(args, exclude):
    """Yield (suffix, args) for every value of the looped option.

    Excluded option names are removed before indexing, for older script
    versions without these options.
    """
    for i, arg in enumerate(args):
        if isinstance(arg, list):
            names = [name for name in arg if name not in exclude]
            for value, name in enumerate(names):
                yield name, args[:i] + [value] + args[i + 1:]
            return
    yield "", args


def slug(text):
    return re.sub(r"[^a-z0-9]+", "-", text.lower()).strip("-")


def script_file(scripts_dir, script):
    """The GIMP 2 scripts in gimp-plugin-registry have separate batch files."""
    batch = scripts_dir / (script + "-batch.scm")
    return batch if batch.exists() else scripts_dir / (script + ".scm")


def run(gimp, scripts_dir, prelude, script, args, outfile):
    call = " ".join([script + "-batch", f'"{outfile}"'] + [str(a) for a in args])
    cmd = [gimp, "-i", "-n", "-d", "-f",
           "--batch-interpreter=plug-in-script-fu-eval",
           "-b", f'{prelude} (load "{script_file(scripts_dir, script)}") ({call})',
           "-b", "(gimp-quit 0)"]
    # print(f"Running {' '.join(cmd)}")
    result = subprocess.run(cmd, capture_output=True, text=True)
    output = result.stdout + result.stderr
    failed = result.returncode != 0 or "batch command executed successfully" not in output
    return failed, call, output


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("scripts", nargs="*", help="scripts to run (default: all)")
    parser.add_argument("-i", "--input", type=Path, default=DEFAULT_INPUT)
    parser.add_argument("-o", "--outdir", type=Path, default=DEFAULT_OUTDIR)
    parser.add_argument("-g", "--gimp", default="gimp-console", help="GIMP binary")
    parser.add_argument("-s", "--scripts-dir", type=Path, default=GIMP_SCRIPTS_DIR,
                        help="directory with the .scm files")
    parser.add_argument("-p", "--prelude", default="",
                        help="Scheme code to evaluate before loading the script")
    parser.add_argument("-x", "--exclude-option", action="append", default=[],
                        help="option name missing in the scripts, can be repeated")
    opts = parser.parse_args()

    unknown = set(opts.scripts) - set(SCRIPTS)
    if unknown:
        parser.error("unknown scripts: " + ", ".join(sorted(unknown)))

    opts.outdir.mkdir(parents=True, exist_ok=True)
    shutil.copy(opts.input, opts.outdir / "before.jpg")

    failures = 0
    for script in opts.scripts or SCRIPTS:
        if f"(define ({script}-batch " not in script_file(opts.scripts_dir, script).read_text():
            print("SKIP " + script + " (no batch version)", flush=True)
            continue
        for suffix, args in variants(SCRIPTS[script], opts.exclude_option):
            name = script + ("-" + slug(suffix) if suffix else "")
            outfile = (opts.outdir / (name + ".jpg")).resolve()
            shutil.copy(opts.input, outfile)
            failed, call, output = run(opts.gimp, opts.scripts_dir, opts.prelude, script, args, outfile)
            print(("FAIL " if failed else "OK   ") + name, flush=True)
            if failed:
                failures += 1
                print("     " + call)
                print(output)

    print(f"{failures} failed" if failures else "all OK")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())
