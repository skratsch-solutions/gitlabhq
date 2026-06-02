// Package oauthproxy routes OAuth requests between GitLab Rails (Doorkeeper)
// and the IAM Auth service during the AUTH-011 gradual rollout. When
// IAMServiceURL is nil, Build returns the supplied Rails proxy unchanged.
package oauthproxy

import (
	"net/http"
	"net/url"

	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

// Handler routes OAuth requests between Rails and the IAM Auth service.
type Handler struct {
	API           *api.API
	Version       string
	RailsProxy    http.Handler
	IAMServiceURL *url.URL
}

// Build returns the http.Handler for the AUTH-011 OAuth routes. With
// IAMServiceURL nil, returns RailsProxy unchanged; otherwise returns a
// handler that logs each request and forwards to RailsProxy.
func (h *Handler) Build() http.Handler {
	if h.IAMServiceURL == nil {
		return h.RailsProxy
	}

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h.logDecision(r, destinationRails, "rule_not_implemented")
		h.RailsProxy.ServeHTTP(w, r)
	})
}

type destination string

const destinationRails destination = "rails"

func (h *Handler) logDecision(r *http.Request, dest destination, reason string) {
	log.WithContextFields(r.Context(), log.Fields{
		"method":      r.Method,
		"path":        r.URL.Path,
		"destination": string(dest),
		"reason":      reason,
	}).Info("oauthproxy: routing decision")
}
