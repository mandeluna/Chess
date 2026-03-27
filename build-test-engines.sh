#!/bin/bash
# Build open-source test engines for Chamonix benchmarking.
# Run once from the Chess project root: bash build-test-engines.sh
#
# Prerequisites:
#   java                    # for Pulse (uses bundled Gradle wrapper, no install needed)
#   python3                 # for Sunfish (built-in on macOS)
#   Xcode CLT (gcc/clang)   # for Vice
#   brew install rust        # for Rustic (or: curl https://sh.rustup.rs -sSf | sh)

set -e

ENGINES_DIR="$(pwd)/test-engines"
mkdir -p "$ENGINES_DIR"

# ── Pulse (Java, ~1500–1700 ELO) ─────────────────────────────────────────────
if [ ! -f "$ENGINES_DIR/pulse.jar" ]; then
    TMP=$(mktemp -d)
    echo "==> Building Pulse in ${TMP}..."
    git clone --depth 1 https://github.com/fluxroot/pulse "$TMP/pulse"
    # Use the repo's own wrapper (downloads the correct Gradle version) and build
    # only the Java subproject — the Kotlin multiplatform subproject is incompatible
    # with newer system Gradle versions.
    (cd "$TMP/pulse" && ./gradlew -q :pulse-java:jar)
    cp "$TMP/pulse"/pulse-java/build/libs/pulse-*.jar "$ENGINES_DIR/pulse.jar"
    rm -rf "$TMP"
    echo "    Pulse → $ENGINES_DIR/pulse.jar"
else
    echo "==> Pulse already built, skipping."
fi

# ── Sunfish (Python, ~1300–1500 ELO) ─────────────────────────────────────────
if [ ! -d "$ENGINES_DIR/sunfish" ]; then
    echo "==> Cloning Sunfish..."
    git clone --depth 1 https://github.com/thomasahle/sunfish "$ENGINES_DIR/sunfish"
    echo "    Sunfish → $ENGINES_DIR/sunfish/sunfish_uci.py"
else
    echo "==> Sunfish already present, skipping."
fi

# ── Vice (C, ~1800 ELO) ───────────────────────────────────────────────────────
# Clone from: https://github.com/bluefeversoft/vice
# The source ships as a single vice.c with a Makefile.
if [ ! -f "$ENGINES_DIR/vice" ]; then
    echo "==> Building Vice..."
    TMP=$(mktemp -d)
    git clone --depth 1 https://github.com/bluefeversoft/vice "$TMP/vice"
    make -C "$TMP/vice/Vice11/src" -j$(sysctl -n hw.logicalcpu)
    cp "$TMP/vice/Vice11/src/vice" "$ENGINES_DIR/vice"
    rm -rf "$TMP"
    echo "    Vice → $ENGINES_DIR/vice"
else
    echo "==> Vice already built, skipping."
fi

# ── Rustic Alpha 3 (Rust, ~1700–1800 ELO) ────────────────────────────────────
# Prerequisites: brew install rust  (or rustup)
if [ ! -f "$ENGINES_DIR/rustic" ]; then
    echo "==> Building Rustic..."
    TMP=$(mktemp -d)
    git clone --depth 1 --branch alpha-3.0.0 https://codeberg.org/mvanthoor/rustic "$TMP/rustic"
    (cd "$TMP/rustic" && cargo build --release --quiet)
    cp "$TMP/rustic/target/release/rustic-alpha" "$ENGINES_DIR/rustic"
    rm -rf "$TMP"
    echo "    Rustic → $ENGINES_DIR/rustic"
else
    echo "==> Rustic already built, skipping."
fi

echo ""
echo "Done. Engines in $ENGINES_DIR:"
ls -lh "$ENGINES_DIR"
