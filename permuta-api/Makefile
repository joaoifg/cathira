.PHONY: run build tidy test migrate-up migrate-down migrate-new

run:
	go run ./cmd/api

build:
	go build -o bin/api ./cmd/api

tidy:
	go mod tidy

test:
	go test ./...

# Requer golang-migrate instalado: https://github.com/golang-migrate/migrate
# brew install golang-migrate  /  scoop install migrate
MIGRATE_DSN ?= $(DATABASE_URL)
MIG_DIR     := db/migrations

migrate-up:
	migrate -database "$(MIGRATE_DSN)" -path $(MIG_DIR) up

migrate-down:
	migrate -database "$(MIGRATE_DSN)" -path $(MIG_DIR) down 1

# uso: make migrate-new NAME=add_foo
migrate-new:
	migrate create -ext sql -dir $(MIG_DIR) -seq $(NAME)
