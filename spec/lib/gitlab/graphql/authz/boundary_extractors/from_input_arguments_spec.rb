# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Authz::BoundaryExtractors::FromInputArguments, feature_category: :permissions do
  include Authz::GranularTokenAuthorizationHelper

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }

  subject(:extractor) { described_class.new(directives, arguments) }

  describe '#extract' do
    subject(:extracted) { extractor.extract }

    context 'when the boundary argument is a GlobalID for a project' do
      let(:directives) { [create_directive(boundary_argument: 'project_id', boundary_type: 'project')] }
      let(:arguments) { { project_id: project.to_global_id } }

      it 'locates and returns the project' do
        expect(extracted).to contain_exactly(project)
      end
    end

    context 'when the boundary argument is a full path string' do
      let(:directives) { [create_directive(boundary_argument: 'project_path', boundary_type: 'project')] }
      let(:arguments) { { project_path: project.full_path } }

      it 'locates and returns the project' do
        expect(extracted).to contain_exactly(project)
      end
    end

    context 'when the boundary argument resolves to a group' do
      let(:directives) { [create_directive(boundary_argument: 'group_path', boundary_type: 'group')] }
      let(:arguments) { { group_path: group.full_path } }

      it 'locates and returns the group' do
        expect(extracted).to contain_exactly(group)
      end
    end

    context 'when the located record is neither a project nor a group' do
      let(:directives) do
        [create_directive(boundary_argument: 'id', boundary: 'project', boundary_type: 'project')]
      end

      let(:arguments) { { id: issue.to_global_id } }

      it 'calls the boundary method on the located record' do
        expect(extracted).to contain_exactly(project)
      end
    end

    context 'when the directive has no boundary method and the record is not a project or group' do
      let(:directives) { [create_directive(boundary_argument: 'id', boundary_type: 'project')] }
      let(:arguments) { { id: issue.to_global_id } }

      it 'returns no boundary instead of raising' do
        expect { extracted }.not_to raise_error
        expect(extracted).to be_empty
      end
    end

    context 'when the directive has no boundary_argument' do
      let(:directives) { [create_directive(boundary: 'project', boundary_type: 'project')] }
      let(:arguments) { { project_id: project.to_global_id } }

      it 'returns no boundary' do
        expect(extracted).to be_empty
      end
    end

    context 'when the argument value is nil' do
      let(:directives) { [create_directive(boundary_argument: 'project_id', boundary_type: 'project')] }
      let(:arguments) { { project_id: nil } }

      it 'returns no boundary' do
        expect(extracted).to be_empty
      end
    end

    context 'when the full path does not match a project or group' do
      let(:directives) { [create_directive(boundary_argument: 'project_path', boundary_type: 'project')] }
      let(:arguments) { { project_path: 'nonexistent/path' } }

      it 'returns no boundary' do
        expect(extracted).to be_empty
      end
    end

    context 'when the GlobalID points to a non-existent record' do
      let(:directives) { [create_directive(boundary_argument: 'project_id', boundary_type: 'project')] }
      let(:arguments) { { project_id: GlobalID.parse("gid://gitlab/Project/#{non_existing_record_id}") } }

      it 'returns no boundary' do
        expect(extracted).to be_empty
      end
    end

    context 'with a standalone boundary' do
      let(:directives) { [create_directive(boundary_type: 'instance')] }
      let(:arguments) { {} }

      it 'returns the boundary_type symbol' do
        expect(extracted).to contain_exactly(:instance)
      end
    end

    context 'when the resolved boundary does not match the declared boundary_type' do
      let(:directives) { [create_directive(boundary_argument: 'project_path', boundary_type: 'group')] }
      let(:arguments) { { project_path: project.full_path } }

      it 'skips the directive' do
        expect(extracted).to be_empty
      end
    end

    context 'with both a concrete and a standalone boundary directive' do
      let(:directives) do
        [
          create_directive(boundary_argument: 'project_path', boundary_type: 'project'),
          create_directive(boundary_type: 'instance')
        ]
      end

      let(:arguments) { { project_path: project.full_path } }

      it 'prefers the concrete boundary over the standalone one' do
        expect(extracted).to contain_exactly(project)
      end
    end

    context 'with duplicate standalone boundary directives' do
      let(:directives) do
        [
          create_directive(boundary_type: 'instance'),
          create_directive(boundary_type: 'instance')
        ]
      end

      let(:arguments) { {} }

      it 'de-duplicates the boundary_type symbols' do
        expect(extracted).to contain_exactly(:instance)
      end
    end

    context 'when there are no directives' do
      let(:directives) { [] }
      let(:arguments) { { project_path: project.full_path } }

      it 'returns an empty array' do
        expect(extracted).to eq([])
      end
    end
  end
end
