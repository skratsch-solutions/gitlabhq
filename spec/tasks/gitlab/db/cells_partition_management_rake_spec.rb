# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:db partition management tasks', feature_category: :database do
  include Database::PartitioningHelpers

  before(:all) do
    Rake.application.rake_require 'tasks/gitlab/db/cells_partition_management'
  end

  before do
    Rake::Task['gitlab:db:export_partition_definitions'].reenable
    Rake::Task['gitlab:db:ensure_partitions'].reenable
  end

  describe 'gitlab:db:export_partition_definitions' do
    it 'outputs valid JSON to stdout' do
      expect { Rake::Task['gitlab:db:export_partition_definitions'].invoke }
        .to output(/\[.*"database".*"tables".*\]/m).to_stdout
    end

    it 'includes integer range-partitioned tables' do
      expect { Rake::Task['gitlab:db:export_partition_definitions'].invoke }
        .to output(/merge_request_commits_metadata/).to_stdout
    end

    it 'skips excluded databases like geo' do
      original_method = Gitlab::Database::EachDatabase.method(:each_connection)

      allow(Gitlab::Database::EachDatabase).to receive(:each_connection) do |**_kwargs, &block|
        block.call(ApplicationRecord.connection, 'geo')
        original_method.call(&block)
      end

      expect { Rake::Task['gitlab:db:export_partition_definitions'].invoke }
        .not_to output(/"database"\s*:\s*"geo"/).to_stdout
    end

    it 'excludes time-range partitioned tables' do
      expect { Rake::Task['gitlab:db:export_partition_definitions'].invoke }
        .not_to output(/project_daily_statistics/).to_stdout
    end
  end

  describe 'gitlab:db:ensure_partitions' do
    let(:connection) { ApplicationRecord.connection }

    before do
      connection.execute(<<~SQL)
        CREATE TABLE _test_rake_partitioned
          (id serial NOT NULL, project_id bigint NOT NULL, PRIMARY KEY (id, project_id))
          PARTITION BY RANGE (project_id);
      SQL
    end

    after do
      connection.execute('DROP TABLE IF EXISTS _test_rake_partitioned CASCADE')
    end

    it 'creates partitions from a JSON file' do
      definitions = [
        {
          database: 'main',
          tables: [
            {
              table_name: '_test_rake_partitioned',
              partitions: [
                { partition_name: '_test_rake_partitioned_1', from: 1, to: 100 }
              ]
            }
          ]
        }
      ]

      Tempfile.create(['partitions', '.json']) do |f|
        f.write(Gitlab::Json.dump(definitions))
        f.flush

        Rake::Task['gitlab:db:ensure_partitions'].invoke(f.path)
      end

      expect_range_partition_of('_test_rake_partitioned_1', '_test_rake_partitioned', "'1'", "'100'")
    end

    it 'skips excluded databases like geo during import' do
      original_method = Gitlab::Database::EachDatabase.method(:each_connection)

      allow(Gitlab::Database::EachDatabase).to receive(:each_connection) do |**_kwargs, &block|
        block.call(ApplicationRecord.connection, 'geo')
        original_method.call(&block)
      end

      definitions = [
        { database: 'geo', tables: [{ table_name: '_test_rake_partitioned', partitions: [] }] },
        {
          database: 'main',
          tables: [
            {
              table_name: '_test_rake_partitioned',
              partitions: [
                { partition_name: '_test_rake_partitioned_1', from: 1, to: 100 }
              ]
            }
          ]
        }
      ]

      Tempfile.create(['partitions', '.json']) do |f|
        f.write(Gitlab::Json.dump(definitions))
        f.flush

        Rake::Task['gitlab:db:ensure_partitions'].invoke(f.path)
      end

      expect_range_partition_of('_test_rake_partitioned_1', '_test_rake_partitioned', "'1'", "'100'")
    end

    context 'with DRY_RUN=true' do
      it 'reports what would be created without creating partitions' do
        definitions = [
          {
            database: 'main',
            tables: [
              {
                table_name: '_test_rake_partitioned',
                partitions: [
                  { partition_name: '_test_rake_partitioned_1', from: 1, to: 100 }
                ]
              }
            ]
          }
        ]

        Tempfile.create(['partitions', '.json']) do |f|
          f.write(Gitlab::Json.dump(definitions))
          f.flush

          stub_env('DRY_RUN', 'true')

          expect { Rake::Task['gitlab:db:ensure_partitions'].invoke(f.path) }
            .to output(/DRY RUN.*would_create=1/m).to_stdout

          expect(connection.table_exists?('_test_rake_partitioned_1')).to be(false)
        end
      end
    end

    it 'raises an error when no file is provided' do
      expect { Rake::Task['gitlab:db:ensure_partitions'].invoke }.to raise_error(ArgumentError, /File path is required/)
    end

    it 'raises an error when file does not exist' do
      expect do
        Rake::Task['gitlab:db:ensure_partitions'].invoke('/nonexistent/file.json')
      end.to raise_error(ArgumentError, /File not found/)
    end

    it 'raises an error for invalid JSON input' do
      Tempfile.create(['partitions', '.json']) do |f|
        f.write('{ invalid json')
        f.flush

        expect do
          Rake::Task['gitlab:db:ensure_partitions'].invoke(f.path)
        end.to raise_error(ArgumentError, /Invalid JSON/)
      end
    end
  end
end
