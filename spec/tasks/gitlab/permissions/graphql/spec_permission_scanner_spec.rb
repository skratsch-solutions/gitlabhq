# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Tasks::Gitlab::Permissions::Graphql::SpecPermissionScanner, feature_category: :permissions do
  let(:scanner) { described_class.new }

  describe '#test_count' do
    before do
      allow(scanner).to receive_messages(spec_files: ['test.rb'], build_shared_example_inclusions: Hash.new(0))
    end

    it 'counts invocations of the GraphQL shared example' do
      content = "it_behaves_like 'authorizing granular token permissions for GraphQL', :read_project do"
      allow(File).to receive(:read).with('test.rb').and_return(content)

      expect(scanner.test_count(:read_project)).to eq(1)
    end

    it 'does not count invocations of the REST shared example' do
      content = "it_behaves_like 'authorizing granular token permissions', :read_project do"
      allow(File).to receive(:read).with('test.rb').and_return(content)

      expect(scanner.test_count(:read_project)).to eq(0)
    end
  end

  describe 'shared example multiplier' do
    before do
      allow(scanner).to receive(:spec_files).and_return(['shared_example.rb', 'spec_a.rb', 'spec_b.rb'])
    end

    it 'multiplies permissions by global inclusion count' do
      shared_content = <<~RUBY
        shared_examples 'work item queries' do
          it_behaves_like 'authorizing granular token permissions for GraphQL', :read_work_item do
          end
        end
      RUBY

      allow(File).to receive(:read).with('shared_example.rb').and_return(shared_content)
      allow(File).to receive(:read).with('spec_a.rb').and_return("it_behaves_like 'work item queries'\n")
      allow(File).to receive(:read).with('spec_b.rb').and_return("it_behaves_like 'work item queries'\n")

      expect(scanner.test_count(:read_work_item)).to eq(2)
    end
  end

  describe '#insufficient_test_coverage' do
    let(:details) { { kind: 'type', name: 'Project', source: 'app/graphql/types/project_type.rb' } }
    let(:todo_lines) { ["# comment\n", "type:Epic group read_epic\n"] }

    before do
      allow(scanner).to receive_messages(spec_files: ['test.rb'], build_shared_example_inclusions: Hash.new(0))
      allow(File).to receive(:read).with('test.rb').and_return('')
      allow(described_class::TODO_FILE).to receive_messages(exist?: true, readlines: todo_lines)
    end

    it 'returns violations for permissions with insufficient tests' do
      scanner.add_endpoint(endpoint_id: 'type:Project project', permission: :read_project, details: details)

      expect(scanner.insufficient_test_coverage).to contain_exactly(
        hash_including(permission: 'read_project', endpoint_count: 1, grandfathered_count: 0, test_count: 0,
          endpoints: [details])
      )
    end

    it 'skips declarations grandfathered in the TODO file' do
      scanner.add_endpoint(endpoint_id: 'type:Epic group', permission: :read_epic, details: details)

      expect(scanner.insufficient_test_coverage).to be_empty
    end

    it 'still flags a new declaration of a grandfathered permission' do
      scanner.add_endpoint(endpoint_id: 'type:Epic group', permission: :read_epic, details: details)
      scanner.add_endpoint(endpoint_id: 'type:BoardEpic group', permission: :read_epic, details: details)

      expect(scanner.insufficient_test_coverage).to contain_exactly(
        hash_including(permission: 'read_epic', endpoint_count: 2, grandfathered_count: 1, test_count: 0)
      )
    end

    context 'when a TODO entry no longer matches a registered declaration' do
      let(:todo_lines) { ["type:RemovedEpicType group read_epic\n"] }

      it 'does not count it as grandfathered' do
        scanner.add_endpoint(endpoint_id: 'type:Epic group', permission: :read_epic, details: details)

        expect(scanner.insufficient_test_coverage).to contain_exactly(
          hash_including(permission: 'read_epic', endpoint_count: 1, grandfathered_count: 0, test_count: 0)
        )
      end
    end

    context 'when the TODO file does not exist' do
      before do
        allow(described_class::TODO_FILE).to receive(:exist?).and_return(false)
      end

      it 'flags grandfathered declarations too' do
        scanner.add_endpoint(endpoint_id: 'type:Epic group', permission: :read_epic, details: details)

        expect(scanner.insufficient_test_coverage).to contain_exactly(
          hash_including(permission: 'read_epic', endpoint_count: 1, grandfathered_count: 0, test_count: 0)
        )
      end
    end
  end
end
