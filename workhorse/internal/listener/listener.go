// Package listener contains utilities for creating network listeners with optional TLS support.
package listener

import (
	"crypto/tls"
	"net"

	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

// New creates a network listener with optional TLS support
func New(name string, cfg config.ListenerConfig) (net.Listener, error) {
	if cfg.TLS == nil {
		log.WithFields(log.Fields{"address": cfg.Addr, "network": cfg.Network}).Infof("Running %v server", name)

		return net.Listen(cfg.Network, cfg.Addr)
	}

	cert, err := tls.LoadX509KeyPair(cfg.TLS.Certificate, cfg.TLS.Key)
	if err != nil {
		return nil, err
	}

	log.WithFields(log.Fields{"address": cfg.Addr, "network": cfg.Network}).Infof("Running %v server with tls", name)

	// Default to TLS 1.2 when no minimum version is configured. An unset
	// min_version maps to 0, which would otherwise allow TLS 1.0/1.1.
	minVersion := config.TLSVersions[cfg.TLS.MinVersion]
	if minVersion == 0 {
		minVersion = tls.VersionTLS12
	}

	// #nosec G402 -- MinVersion defaults to TLS 1.2 above; a lower version is
	// only used when an operator explicitly configures one.
	tlsConfig := &tls.Config{
		MinVersion:   minVersion,
		MaxVersion:   config.TLSVersions[cfg.TLS.MaxVersion],
		Certificates: []tls.Certificate{cert},
	}

	return tls.Listen(cfg.Network, cfg.Addr, tlsConfig)
}
