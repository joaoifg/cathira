package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

// CORS libera origens em modo dev (qualquer host:porta do flutter run -d chrome).
// Em produção, restringe pra origens conhecidas — TODO quando definir domínio.
func CORS(devMode bool) gin.HandlerFunc {
	return func(c *gin.Context) {
		origin := c.GetHeader("Origin")
		if devMode && origin != "" {
			c.Header("Access-Control-Allow-Origin", origin)
		}
		c.Header("Vary", "Origin")
		c.Header("Access-Control-Allow-Methods", "GET, POST, PUT, PATCH, DELETE, OPTIONS")
		c.Header("Access-Control-Allow-Headers", "Authorization, Content-Type, X-Requested-With")
		c.Header("Access-Control-Allow-Credentials", "true")
		c.Header("Access-Control-Max-Age", "86400")

		if c.Request.Method == http.MethodOptions {
			c.AbortWithStatus(http.StatusNoContent)
			return
		}
		c.Next()
	}
}
