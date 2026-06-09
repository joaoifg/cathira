package server

import (
	"context"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/joaohenriqueoci/permuta-api/internal/config"
	"github.com/joaohenriqueoci/permuta-api/internal/handler"
	"github.com/joaohenriqueoci/permuta-api/internal/middleware"
	"github.com/joaohenriqueoci/permuta-api/internal/repository"
	"github.com/joaohenriqueoci/permuta-api/internal/service"
)

type App struct {
	Router *gin.Engine
	DB     *pgxpool.Pool
	cfg    config.Config
}

func New(ctx context.Context, cfg config.Config) (*App, error) {
	if cfg.Env == "prod" {
		gin.SetMode(gin.ReleaseMode)
	}

	pool, err := pgxpool.New(ctx, cfg.DatabaseURL)
	if err != nil {
		return nil, err
	}
	pingCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
	defer cancel()
	if err := pool.Ping(pingCtx); err != nil {
		pool.Close()
		return nil, err
	}

	loteRepo := repository.NewLoteRepo(pool)
	itemRepo := repository.NewItemRepo(pool)
	negoRepo := repository.NewNegociacaoRepo(pool)

	loteSvc := service.NewLoteService(loteRepo, itemRepo)
	matchSvc := service.NewMatchService(negoRepo)
	negoSvc := service.NewNegociacaoService(negoRepo)

	r := gin.New()
	r.Use(gin.Recovery(), middleware.RequestLogger(), middleware.CORS(cfg.DevMode))

	r.GET("/healthz", func(c *gin.Context) {
		if err := pool.Ping(c.Request.Context()); err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"ok": false, "db": "down"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"ok": true, "dev_mode": cfg.DevMode})
	})

	if cfg.DevMode {
		devH := handler.NewDevHandler(cfg, pool)
		r.POST("/dev/login", devH.Login)
	}

	authMW := middleware.SupabaseJWT(cfg.SupabaseJWTSecret)

	authH := handler.NewAuthHandler(pool)
	loteH := handler.NewLoteHandler(loteSvc)
	itemH := handler.NewItemHandler(loteSvc)
	swipeH := handler.NewSwipeHandler(matchSvc)
	negoH := handler.NewNegociacaoHandler(negoSvc, pool)

	api := r.Group("/", authMW)
	{
		api.POST("/auth/me", authH.Me)
		api.GET("/setores", handler.NewSetorHandler(pool).List)

		api.POST("/lotes", loteH.Create)
		api.GET("/lotes/meus", loteH.Meus)
		api.GET("/lotes/:id", loteH.Get)
		api.POST("/lotes/:id/itens", itemH.AddToLote)

		api.POST("/itens", itemH.Create)
		api.GET("/itens/meus", itemH.Meus)
		api.PATCH("/itens/:id", itemH.Move)

		api.GET("/descoberta", loteH.Feed)

		api.POST("/swipes", swipeH.Create)

		api.GET("/negociacoes", negoH.List)
		api.GET("/negociacoes/:id", negoH.Detalhe)
		api.POST("/negociacoes/:id/mesa", negoH.AtualizarMesa)
		api.POST("/negociacoes/:id/aceitar", negoH.Aceitar)

		msgH := handler.NewMensagemHandler(pool)
		api.GET("/negociacoes/:id/mensagens", msgH.List)
		api.POST("/negociacoes/:id/mensagens", msgH.Send)

		avH := handler.NewAvaliacaoHandler(pool)
		api.POST("/avaliacoes", avH.Create)

		perfilH := handler.NewPerfilHandler(pool)
		api.GET("/perfis/:id", perfilH.Get)

		if cfg.DevMode {
			seedH := handler.NewSeedHandler(pool, cfg)
			api.POST("/dev/seed", seedH.Run)
			api.POST("/dev/seed-mundo", seedH.Mundo)
			api.POST("/dev/seed-massa", seedH.Massa)
			upH := handler.NewUploadHandler(cfg)
			api.POST("/dev/upload", upH.Upload)
		}
	}

	return &App{Router: r, DB: pool, cfg: cfg}, nil
}

func (a *App) Close() {
	if a.DB != nil {
		a.DB.Close()
	}
}
