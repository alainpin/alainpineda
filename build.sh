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

# Las figuras en espanol (*-es-light.svg / *-es-dark.svg) solo las resuelve el
# render en espanol, asi que Quarto las deja en _site-es/images/ y hay que
# traerlas. Hasta el 2026-09-02 llegaban por accidente: los globs del render en
# ingles no estaban anclados a la raiz, el perfil ingles renderizaba tambien
# todo el arbol es/ y de paso copiaba sus imagenes. Al anclar los globs eso
# dejo de pasar y quedo a la vista que esta copia nunca habia existido. Sin
# ella, cada pagina en espanol con .chart-figure queda con las imagenes rotas,
# y como el deploy borra lo que no venga en _site/, se romperian en produccion.
if [ -d _site-es/images ]; then
  mkdir -p _site/images
  cp -R _site-es/images/. _site/images/
fi

echo "==> Listo. Sirve _site/ para revisar:"
echo "    python3 -m http.server 8080 --directory _site"
