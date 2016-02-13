IMAGE = imega/malmo
CONTAINERS = imega_malmo imega_bremen_db
PORT = -p 80:80
REDIS_PORT = 6379
ENV = PROD
HOST_CDN =
HOST =

build:
	@docker build -t $(IMAGE) .

prestart:
	@docker run -d --name imega_bremen_db leanlabs/redis

start: prestart
	@while [ "`docker inspect -f {{.State.Running}} imega_bremen_db`" != "true" ]; do \
		@echo "wait db"; sleep 0.3; \
	done
	$(eval REDIS_IP = $(shell docker inspect --format '{{ .NetworkSettings.IPAddress }}' imega_bremen_db))
ifeq ($(ENV),DEV)
	docker exec imega_bremen_db \
		sh -c "echo SET auth:9915e49a-4de1-41aa-9d7d-c9a687ec048d 8c279a62-88de-4d86-9b65-527c81ae767a | redis-cli --pipe"
endif
	@docker run -d --name imega_malmo \
		--env REDIS_IP=$(REDIS_IP) \
		--env REDIS_PORT=$(REDIS_PORT) \
		--env HOST_CDN=$(HOST_CDN) \
		--env HOST=$(HOST) \
		$(PORT) \
		$(IMAGE)

stop:
	@-docker stop $(CONTAINERS)

clean: stop
	@-docker rm -fv $(CONTAINERS)

destroy: clean
	@docker rmi -f $(IMAGE)

test:
	@tests/index.sh $(TEST_URL)
