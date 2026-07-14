# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name        = "gitlab-deploy-driver-argo-rollouts"
  spec.version     = "0.0.0" # stub release; payload vendored from upstream argo-rollout v0.1.0
  spec.authors     = ["GitLab Engineers"]
  spec.email       = ["engineering@gitlab.com"]

  spec.summary     = "Vendored Argo Rollouts deploy driver assets (deploy.star + JSON schemas)"
  spec.description = "Packages the bundled deploy.star program and JSON schemas from " \
    "gitlab-org/ci-cd/runner-tools/argo-rollout v0.1.0 for use by GitLab."
  spec.homepage    = "https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-deploy-driver-argo-rollouts"
  spec.license     = "MIT"
  spec.required_ruby_version = ">= 3.0"
  spec.metadata["rubygems_mfa_required"] = "true"

  # This gem ships data files, not Ruby. The default `Dir['lib/**/*.rb']` glob
  # would drop the payload, so the .star and .json assets are listed explicitly.
  spec.files         = Dir["manifest.json", "schemas/**/*.json", "scripts/**/*.star", "README.md"]
  # No Ruby to load; the require path is the gem root, where the data files live.
  spec.require_paths = ["."]
end
