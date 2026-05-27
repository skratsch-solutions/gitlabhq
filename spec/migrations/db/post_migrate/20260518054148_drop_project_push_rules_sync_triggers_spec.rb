# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropProjectPushRulesSyncTriggers, feature_category: :source_code_management do
  let(:insert_update_trigger_name) { 'trigger_sync_project_push_rules_insert_update' }
  let(:insert_update_function_name) { 'sync_project_push_rules_on_insert_update' }
  let(:delete_trigger_name) { 'trigger_sync_project_push_rules_delete' }
  let(:delete_function_name) { 'sync_project_push_rules_on_delete' }

  def trigger_exists?(table_name, trigger_name)
    connection = ActiveRecord::Base.connection

    result = connection.select_value(<<~SQL.squish)
      SELECT true FROM pg_catalog.pg_trigger trgr
      INNER JOIN pg_catalog.pg_class rel ON trgr.tgrelid = rel.oid
      WHERE rel.relname = #{connection.quote(table_name)} AND trgr.tgname = #{connection.quote(trigger_name)}
    SQL

    !!result
  end

  def function_exists?(function_name)
    connection = ActiveRecord::Base.connection

    result = connection.select_value(<<~SQL.squish)
      SELECT true FROM pg_proc WHERE proname = #{connection.quote(function_name)}
    SQL

    !!result
  end

  describe '#up', :aggregate_failures do
    it 'drops both triggers and both functions' do
      migrate!

      expect(trigger_exists?('push_rules', insert_update_trigger_name)).to be(false)
      expect(trigger_exists?('push_rules', delete_trigger_name)).to be(false)
      expect(function_exists?(insert_update_function_name)).to be(false)
      expect(function_exists?(delete_function_name)).to be(false)
    end
  end

  describe '#down', :aggregate_failures do
    it 'recreates both triggers and both functions' do
      migrate!
      schema_migrate_down!

      expect(trigger_exists?('push_rules', insert_update_trigger_name)).to be(true)
      expect(trigger_exists?('push_rules', delete_trigger_name)).to be(true)
      expect(function_exists?(insert_update_function_name)).to be(true)
      expect(function_exists?(delete_function_name)).to be(true)
    end
  end
end
