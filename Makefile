IMAGE = imega/malmo
CONTAINERS = teleport_inviter teleport_data
PORT = -p 8081:80
REDIS_PORT = 6379
ENV = PROD
HOST_CDN =
HOST_PRIMARY =

TEST_URL = localhost:8081

MOCKS = website
MOCK_TEST_URL = localhost:8091

build:
	@docker build -t $(IMAGE) .

prestart:
	@docker run -d --name teleport_data leanlabs/redis

start: prestart
	@while [ "`docker inspect -f {{.State.Running}} teleport_data`" != "true" ]; do \
		echo "wait db"; sleep 0.3; \
	done
	$(eval REDIS_IP = $(shell docker inspect --format '{{ .NetworkSettings.IPAddress }}' teleport_data))
ifeq ($(ENV),DEV)
	docker exec teleport_data \
		sh -c "echo SET auth:9915e49a-4de1-41aa-9d7d-c9a687ec048d 8c279a62-88de-4d86-9b65-527c81ae767a | redis-cli --pipe"
	docker exec teleport_data \
		sh -c "echo SET activate:db4e2a20-31bf-4001-c0f9-2245d260bc2e teleport@imega.club | redis-cli --pipe"
endif
	@docker run -d --name teleport_inviter \
		--link teleport_data:teleport_data \
		--env REDIS_IP=$(REDIS_IP) \
		--env REDIS_PORT=$(REDIS_PORT) \
		--env HOST_CDN=$(HOST_CDN) \
		--env HOST_PRIMARY=$(HOST_PRIMARY) \
		-v $(CURDIR)/app:/app \
		$(PORT) \
		$(IMAGE)

stop:
	@-docker stop $(CONTAINERS)

clean: stop
	@-docker rm -fv $(CONTAINERS)

destroy: clean
	@-docker rmi -f $(IMAGE)

tests: $(MOCKS)
	@tests/index.sh $(TEST_URL) $(MOCK_TEST_URL)

$(MOCKS):
	$(MAKE) destroy build start tests TEST_URL=$(MOCK_TEST_URL) --directory=$(CURDIR)/tests/mocks/$@

.PHONY: tests
