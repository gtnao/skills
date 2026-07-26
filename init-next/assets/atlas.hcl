env "local" {
  src = "file://db/schema.sql"

  url = "postgres://postgres:postgres@localhost:5432/postgres?sslmode=disable"

  dev = "docker://postgres/18/dev?search_path=public"

  migration {
    dir = "file://db/migrations"
  }
}
