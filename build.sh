#!/usr/bin/env bash
# Compila las dos versiones del sitio y las junta en _site/.
#   _site/      -> ingles
#   _site/es/   -> espanol
set -euo pipefail

echo "==> Renderizando ingles"
quarto render

echo "==> Renderizando espanol"
quarto render --profile es

echo "==> Uniendo el espanol dentro de _site/es"
mkdir -p _site/es
cp -R _site-es/es/. _site/es/

# Las librerias de Quarto (bootstrap, fuentes, search) se comparten.
# Se copian por si el render en espanol genero alguna que el ingles no.
if [ -d _site-es/site_libs ]; then
  mkdir -p _site/site_libs
  cp -R _site-es/site_libs/. _site/site_libs/
fi

echo "==> Listo. Sirve _site/ para revisar:"
echo "    python3 -m http.server 8080 --directory _site"
