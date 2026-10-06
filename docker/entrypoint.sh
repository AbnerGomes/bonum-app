#!/bin/bash
# Roda o comando pedido e, no fim, devolve a posse dos arquivos gerados
# (build/, .dart_tool/, pubspec.lock...) ao seu usuário da máquina — senão
# eles ficariam como root e o VS Code não conseguiria editá-los.

# Ctrl+C encerra o comando, mas não este script (para o chown ainda rodar).
trap 'true' INT

"$@"
status=$?

chown -R "${HOST_UID:-1000}:${HOST_GID:-1000}" /app 2>/dev/null
exit $status
