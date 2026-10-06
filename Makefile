# Atalhos para o container Flutter do Bonum. Uso: make <alvo>
WEB_PORT ?= 8095
export WEB_PORT

RUN = HOST_UID=$$(id -u) HOST_GID=$$(id -g) docker compose run --rm

.PHONY: image image-update shell web apk-debug apk aab clean keystore

image:      ## Constrói a imagem (1ª vez, ou depois de mudar o Dockerfile)
	docker compose build

image-update: ## Atualiza para o Flutter estável mais recente (pode exigir ajustes no projeto)
	docker compose build --pull

shell:      ## Terminal dentro do container
	$(RUN) flutter bash

web:        ## Roda no navegador: http://localhost:$(WEB_PORT)  (r = reload, R = restart, q = sair)
	$(RUN) --service-ports flutter bash -c "flutter pub get && flutter run -d web-server --web-hostname 0.0.0.0 --web-port $(WEB_PORT)"

apk-debug:  ## APK de teste -> build/app/outputs/flutter-apk/app-debug.apk
	$(RUN) flutter docker/retry.sh bash -c "flutter pub get && flutter build apk --debug"

apk:        ## APK release -> build/app/outputs/flutter-apk/app-release.apk
	$(RUN) flutter docker/retry.sh bash -c "flutter pub get && flutter build apk --release"

aab:        ## App Bundle para a Play Store -> build/app/outputs/bundle/release/app-release.aab
	$(RUN) flutter docker/retry.sh bash -c "flutter pub get && flutter build appbundle --release"

clean:      ## Apaga os artefatos de build
	$(RUN) flutter flutter clean

keystore:   ## Cria a chave de upload da Play Store (uma vez só; guarde bem!)
	$(RUN) flutter keytool -genkey -v -keystore android/upload-keystore.jks \
		-keyalg RSA -keysize 2048 -validity 10000 -alias upload
