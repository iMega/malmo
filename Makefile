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
MOCK_TEST_URL_INTER = mock_website

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
	@docker exec teleport_data \
		sh -c '(echo SET auth:9915e49a-4de1-41aa-9d7d-c9a687ec048d 8c279a62-88de-4d86-9b65-527c81ae767a;sleep 1) | redis-cli --pipe'
	@docker exec teleport_data \
		sh -c '(echo SET activate:db4e2a20-31bf-4001-c0f9-2245d260bc2e teleport@imega.club;sleep 1) | redis-cli --pipe'
	@docker run --rm --link teleport_data:teleport_data alpine:3.3 \
		sh -c "(echo -e \"SET user:9915e49a-4de1-41aa-9d7d-c9a687ec048d '{\042login\042:\0429915e49a-4de1-41aa-9d7d-c9a687ec048d\042,\042url\042:\042\042,\042email\042:\042teleport@imega.club\042,\042create\042:\042\042,\042pass\042:\042\042}'\";sleep 1) | nc teleport_data 6379"
endif
ifeq ($(ENV),PROD)
	@docker run -d --name teleport_inviter \
		--link teleport_data:teleport_data \
		--env REDIS_IP=$(REDIS_IP) \
		--env REDIS_PORT=$(REDIS_PORT) \
		--env HOST_CDN=$(HOST_CDN) \
		--env HOST_PRIMARY=$(HOST_PRIMARY) \
		-v $(CURDIR)/app:/app \
		$(PORT) \
		$(IMAGE)
endif

stop:
	@-docker stop $(CONTAINERS)

clean: stop
	@-docker rm -fv $(CONTAINERS)

destroy: clean
	@-docker rmi -f $(IMAGE)

tests: $(MOCKS)
	@docker run -d --name teleport_inviter \
		--link teleport_data:teleport_data \
		--link mock_website:mock_website \
		--env REDIS_IP=$(REDIS_IP) \
		--env REDIS_PORT=$(REDIS_PORT) \
		--env HOST_CDN=$(HOST_CDN) \
		--env HOST_PRIMARY=$(HOST_PRIMARY) \
		-v $(CURDIR)/app:/app \
		$(PORT) \
		$(IMAGE)
	@while [ "`docker inspect -f {{.State.Running}} teleport_inviter`" != "true" ]; do \
		echo "wait db"; sleep 0.3; \
	done
	@tests/index.sh $(TEST_URL) $(MOCK_TEST_URL_INTER)

$(MOCKS):
	$(MAKE) destroy build start tests TEST_URL=$(MOCK_TEST_URL) --directory=$(CURDIR)/tests/mocks/$@

.PHONY: tests
