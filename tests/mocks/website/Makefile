IMAGE = imega/mock_website
CONTAINERS = mock_website
PORT = -p 8091:80
TEST_URL = localhost:8091

build:
	@docker build -t $(IMAGE) .

start:
	@docker run -d --name mock_website $(PORT) $(IMAGE)

stop:
	@-docker stop $(CONTAINERS)

clean: stop
	@-docker rm -fv $(CONTAINERS)

destroy: clean
	@-docker rmi -f $(IMAGE)

tests:
	@tests/index.sh $(TEST_URL)

.PHONY: tests
