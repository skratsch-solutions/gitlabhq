# gitlab-deploy-driver-argo-rollouts

Vendored deploy driver assets for [Argo Rollouts](https://argo-rollouts.readthedocs.io/).

This gem is **data only** — it ships no Ruby logic. It packages the artifacts published by the
[`gitlab-org/ci-cd/runner-tools/argo-rollout`](https://gitlab.com/gitlab-org/ci-cd/runner-tools/argo-rollout)
project so the GitLab Rails application can depend on them as a versioned gem:

- `manifest.json` — the entrypoint manifest describing the driver and referencing the schemas and deploy program.
- `scripts/deploy.star` — the bundled Starlark deploy program.
- `schemas/environment.json`, `schemas/service_environment.json`, `schemas/steps.json` — the JSON
  schemas describing the deploy configuration and supported steps.

## Usage

The gem exposes no Ruby API. Resolve the gem directory and read the files directly:

```ruby
root = Bundler.load.specs["gitlab-deploy-driver-argo-rollouts"].first.full_gem_path
# or: Gem.loaded_specs["gitlab-deploy-driver-argo-rollouts"].gem_dir

deploy_star  = File.read(File.join(root, "scripts", "deploy.star"))
steps_schema = Gitlab::Json.parse(File.read(File.join(root, "schemas", "steps.json")))
```
