package config

import (
	"errors"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	Env                     string
	Port                    string
	DevMode                 bool
	DatabaseURL             string
	SupabaseURL             string
	SupabaseJWTSecret       string
	SupabasePublishableKey  string
	SupabaseSecretKey       string
}

func Load() (Config, error) {
	_ = godotenv.Load()

	cfg := Config{
		Env:                    getenv("ENV", "dev"),
		Port:                   getenv("PORT", "8080"),
		DevMode:                getenv("DEV_MODE", "false") == "true",
		DatabaseURL:            os.Getenv("DATABASE_URL"),
		SupabaseURL:            os.Getenv("SUPABASE_URL"),
		SupabaseJWTSecret:      os.Getenv("SUPABASE_JWT_SECRET"),
		SupabasePublishableKey: os.Getenv("SUPABASE_PUBLISHABLE_KEY"),
		SupabaseSecretKey:      os.Getenv("SUPABASE_SECRET_KEY"),
	}

	if cfg.DatabaseURL == "" {
		return cfg, errors.New("DATABASE_URL é obrigatório")
	}
	if cfg.SupabaseJWTSecret == "" {
		return cfg, errors.New("SUPABASE_JWT_SECRET é obrigatório (valida tokens do Supabase Auth)")
	}
	return cfg, nil
}

func getenv(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}
