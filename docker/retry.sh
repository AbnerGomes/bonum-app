#!/bin/bash
# Executa o comando e, se falhar, tenta de novo (até 4 vezes, com pausa crescente).
# A rede onde o build roda tem soluços de DNS de alguns segundos; como o Gradle
# guarda o que já baixou, cada nova tentativa continua de onde a anterior parou.
max=4
for i in $(seq 1 $max); do
  "$@" && exit 0
  status=$?
  [ "$i" -eq "$max" ] && break
  wait=$((i * 20))
  echo ""
  echo ">>> Falhou (tentativa $i de $max). Se foi rede, tentando de novo em ${wait}s... (Ctrl+C para cancelar)"
  sleep "$wait"
done
exit $status
