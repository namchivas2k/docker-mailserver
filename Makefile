COMPOSE_PRODUCTION = bin/production.sh
COMPOSE_TEST       = bin/test.sh

.PHONY: prod
prod: up

.PHONY: build
build:
	$(COMPOSE_TEST) build

.PHONY: pull
pull:
	$(COMPOSE_PRODUCTION) pull

.PHONY: test
test: up fixtures
	$(COMPOSE_TEST) run --rm test

.PHONY: clean
clean:
	$(COMPOSE_TEST) down -v --remove-orphans

.env:
	@cp .env.dist .env && cd ./web/web-admin && cp .env.example .env && cd ../..

.PHONY: logs
logs:
	$(COMPOSE_PRODUCTION) logs db
	$(COMPOSE_PRODUCTION) logs ssl
	$(COMPOSE_PRODUCTION) logs mta
	$(COMPOSE_PRODUCTION) logs mda
	$(COMPOSE_PRODUCTION) logs filter
	$(COMPOSE_PRODUCTION) logs virus
	$(COMPOSE_PRODUCTION) logs web
	$(COMPOSE_PRODUCTION) logs fetchmail

.PHONY: up
up: .env
	$(COMPOSE_PRODUCTION) up -d

.PHONY: fixtures
fixtures:
	$(COMPOSE_PRODUCTION) run --rm web /usr/local/bin/fixtures.sh /opt/manager/bin/console domain:add example.com
	$(COMPOSE_PRODUCTION) run --rm web /usr/local/bin/fixtures.sh /opt/manager/bin/console domain:add example.org
	$(COMPOSE_PRODUCTION) run --rm web /usr/local/bin/fixtures.sh /opt/manager/bin/console user:add --admin --password=changeme --enable admin example.com
	$(COMPOSE_PRODUCTION) run --rm web /usr/local/bin/fixtures.sh /opt/manager/bin/console user:add --password=test1234 --enable --sendonly sendonly example.com
	$(COMPOSE_PRODUCTION) run --rm web /usr/local/bin/fixtures.sh /opt/manager/bin/console user:add --password=test1234 --enable --quota=1 quota example.com
	$(COMPOSE_PRODUCTION) run --rm web /usr/local/bin/fixtures.sh /opt/manager/bin/console user:add --password=test1234 disabled example.com
	$(COMPOSE_PRODUCTION) run --rm web /usr/local/bin/fixtures.sh /opt/manager/bin/console user:add --password=test1234 --sendonly disabledsendonly example.com
	$(COMPOSE_PRODUCTION) run --rm web /usr/local/bin/fixtures.sh /opt/manager/bin/console user:add --password=test1234 --enable fetchmailsource example.org
	$(COMPOSE_PRODUCTION) run --rm web /usr/local/bin/fixtures.sh /opt/manager/bin/console user:add --password=test1234 --enable fetchmailreceiver example.org
	$(COMPOSE_PRODUCTION) run --rm web /usr/local/bin/fixtures.sh /opt/manager/bin/console alias:add foo@example.com admin@example.com
	$(COMPOSE_PRODUCTION) run --rm web /usr/local/bin/fixtures.sh /opt/manager/bin/console alias:add foo@example.org admin@example.com
	$(COMPOSE_PRODUCTION) run --rm web /usr/local/bin/fixtures.sh /opt/manager/bin/console alias:add --catchall @example.com admin@example.com
	$(COMPOSE_PRODUCTION) run --rm web /usr/local/bin/fixtures.sh /opt/manager/bin/console dkim:setup example.com --enable --selector dkim
	$(COMPOSE_PRODUCTION) run --rm web /usr/local/bin/fixtures.sh /opt/manager/bin/console fetchmail:account:add --force fetchmailreceiver@example.org mda.local imap 143 fetchmailsource@example.org test1234

.PHONY: unofficial-sigs
unofficial-sigs:
	cd virus/contrib/unofficial-sigs; docker build -t virus_unof_sig_updater .

.PHONY: setup
setup:
	$(COMPOSE_PRODUCTION) run --rm web /usr/local/bin/setup.sh



.PHONY: clear
clear:
	@containers=$$(docker ps -aq); \
	[ -n "$$containers" ] && docker stop $$containers || true; \
	[ -n "$$containers" ] && docker rm $$containers || true; \
	images=$$(docker images -aq); \
	[ -n "$$images" ] && docker rmi $$images || true; \
	volumes=$$(docker volume ls -qf dangling=true); \
	[ -n "$$volumes" ] && docker volume rm $$volumes || true


.PHONY: namchivas
namchivas:
	@make .env && \
	cd ./web && docker buildx build -t jeboehm/mailserver-web:latest . && cd .. && \
	make up && \
	make setup
