.PHONY: build up run shell ssh doctor update down logs volumes k8s-apply k8s-delete k8s-update k8s-port-forward

build:
	docker compose build

up:
	docker compose up -d

run:
	docker compose run --rm workspace codex

shell: up
	docker compose exec workspace bash

ssh:
	ssh -p $${SSH_PORT:-2222} root@$${SSH_HOST:-localhost}

doctor:
	docker compose run --rm workspace codex doctor

update:
	docker compose exec workspace codex update

down:
	docker compose down

logs:
	docker compose logs -f workspace

volumes:
	docker volume ls --filter name=codex-docker

k8s-apply:
	kubectl apply -k k8s

k8s-delete:
	kubectl delete -k k8s

k8s-update:
	kubectl -n codex-docker exec deploy/codex-docker -- codex update

k8s-port-forward:
	kubectl -n codex-docker port-forward svc/codex-docker-ssh $${SSH_PORT:-2222}:22
