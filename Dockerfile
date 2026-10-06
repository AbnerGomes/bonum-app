# Ambiente do Bonum: Flutter + Android SDK + JDK.
# Serve para rodar a versão web (testes no navegador) e gerar APK/AAB.
#
# Para fixar uma versão do Flutter: docker compose build --build-arg FLUTTER_VERSION=3.44.0
ARG FLUTTER_VERSION=stable
# (o Render usa a versão fixada em tool/render_build.sh — mantenha as duas iguais)
FROM ghcr.io/cirruslabs/flutter:${FLUTTER_VERSION}

# A rede de build não tem IPv6: forçar IPv4 no Java (sdkmanager/Gradle).
ENV SDKMANAGER_OPTS="-Djava.net.preferIPv4Stack=true" \
    GRADLE_OPTS="-Djava.net.preferIPv4Stack=true"

# Componentes do Android que o build pede. Ficam na imagem para não serem
# baixados de novo a cada build (o container é descartável). Com novas tentativas,
# porque a rede às vezes oscila.
RUN yes | sdkmanager --licenses > /dev/null \
    && for i in 1 2 3 4 5; do \
         sdkmanager "ndk;28.2.13676358" "cmake;3.22.1" "platforms;android-35" "build-tools;35.0.0" && break; \
         echo "Falhou (tentativa $i), tentando de novo..."; sleep 10; \
       done \
    && test -d "$ANDROID_HOME/ndk/28.2.13676358" && test -d "$ANDROID_HOME/cmake/3.22.1"

COPY docker/entrypoint.sh /usr/local/bin/bonum-entrypoint
RUN chmod +x /usr/local/bin/bonum-entrypoint \
    && flutter config --no-analytics \
    && flutter precache --web --android

WORKDIR /app
ENTRYPOINT ["bonum-entrypoint"]
CMD ["bash"]
