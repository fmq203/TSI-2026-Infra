.PHONY: networks up down status logs up-optional down-optional

STACKS := identity siem-hids nids mail honeypot wazo targets alerting
OPTIONAL := soar-thehive-optional

networks:
	docker compose -f docker-compose.networks.yml up -d

up: networks
	@for s in $(STACKS); do \
		echo "==> levantando $$s"; \
		(cd $$s && docker compose up -d) || exit 1; \
	done

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
	@docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'

logs:
	@for s in $(STACKS); do \
		echo "==== $$s ===="; \
		(cd $$s && docker compose logs --tail=20); \
	done
