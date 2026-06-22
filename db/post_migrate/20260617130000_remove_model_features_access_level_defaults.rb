# frozen_string_literal: true

# Drops the DB-level default on the model registry / experiments access level
# columns so a new ProjectFeature record starts with NULL, letting the
# `set_model_features_access_level` after_initialize callback compute a
# visibility-based default (mirrors how `pages_access_level` works).
#
# Runs as a post-deployment migration so the default only changes after code
# declaring `columns_changing_default` for these columns is deployed, per
# https://docs.gitlab.com/development/database/avoiding_downtime_in_migrations/#changing-column-defaults
#
# Metadata-only change in PostgreSQL: existing rows are untouched.
class RemoveModelFeaturesAccessLevelDefaults < Gitlab::Database::Migration[2.3]
  milestone '19.2'

  def change
    change_column_default(:project_features, :model_registry_access_level, from: 20, to: nil)
    change_column_default(:project_features, :model_experiments_access_level, from: 20, to: nil)
  end
end
