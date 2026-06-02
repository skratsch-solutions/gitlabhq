package oauthproxy

import (
	"net/http"
	"net/http/httptest"
	"net/url"
	"testing"

	"github.com/stretchr/testify/require"
)

// recordingHandler counts invocations so tests can verify the request reached Rails.
type recordingHandler struct{ called int }

func (h *recordingHandler) ServeHTTP(_ http.ResponseWriter, _ *http.Request) {
	h.called++
}

func TestBuild_ReturnsRailsProxyUnchangedWhenIAMURLIsNil(t *testing.T) {
	rails := &recordingHandler{}
	built := (&Handler{RailsProxy: rails}).Build()

	// Zero-overhead invariant: Build returns the exact RailsProxy with no wrapper.
	require.Same(t, rails, built)
}

func TestBuild_FallsThroughToRailsWhenIAMURLIsSet(t *testing.T) {
	rails := &recordingHandler{}
	iamURL, _ := url.Parse("http://iam.test:8084")
	built := (&Handler{RailsProxy: rails, IAMServiceURL: iamURL}).Build()

	built.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodPost, "/oauth/token", nil))

	require.Equal(t, 1, rails.called, "wrapping handler must forward to Rails")
}
