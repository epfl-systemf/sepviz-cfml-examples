#!/usr/bin/env bash
set -euo pipefail

echo "[gen:plain] building example proofs with direnv..."
direnv exec ../example-proofs make -C ../example-proofs

echo "[gen:plain] copying build output to public/"
cp -r ../example-proofs/_build/* ./public/

echo "[gen:plain] done."
