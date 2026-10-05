.PHONY: networks prereqs up down status logs up-optional down-optional

# Solo los stacks que existen hoy. Sumar wazo/alerting acá cuando se construyan.
# nids antes que siem-hids: el manager de Wazuh monta el volumen de logs de Suricata.
STACKS := identity nids siem-hids mail honeypot targets
OPTIONAL := soar-thehive-optional

# docker-compose.networks.yml es solo referencia: `docker compose up` no crea redes
# sin services. El script sí, y es idempotente.
networks:
	./create-networks.sh

# Requisitos previos de mail (certs) y siem-hids (sysctl de OpenSearch), y .env
# copiados desde los .example si todavía no existen.
prereqs:
	@test -f mail/ssl/mail.lab.local-cert.pem || (cd mail && ./generate-self-signed-cert.sh)
	sysctl -w vm.max_map_count=262144
	@for s in $(STACKS); do \
		if [ -f $$s/.env.example ] && [ ! -f $$s/.env ]; then cp $$s/.env.example $$s/.env; echo "creado $$s/.env"; fi; \
	done

up: networks prereqs
	@for s in $(STACKS); do \
		echo "==> levantando $$s"; \
		(cd $$s && docker compose up -d --build) || exit 1; \
	done
	@echo "==> configurando Wazuh (Suricata, reglas locales, active response, mail)"
	./siem-hids/configure-manager.sh
	./mail/ensure-accounts.sh

down:
	@for s in $(STACKS); do \
		echo "==> bajando $$s"; \
		(cd $$s && docker compose down); \
	done

up-optional:
	@echo "==> levantando stack opcional (TheHive+Cortex) — verificar RAM libre antes"
	(cd $(OPTIONAL) && docker compose up -d)

down-optional:
	(cd $(OPTIONAL) && docker compose down)

status:
	@docker ps --format 'table {{.Names}}\t{{.Status}}'

logs:
	@for s in $(STACKS); do \
		echo "==== $$s ===="; \
		(cd $$s && docker compose logs --tail=20); \
	done
