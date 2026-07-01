# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Authz::BoundaryExtractors::FromObject, feature_category: :permissions do
  include Authz::GranularTokenAuthorizationHelper

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }

  subject(:extractor) { described_class.new(directives, object) }

  describe '#extract' do
    subject(:extracted) { extractor.extract }

    context 'when the boundary is :itself' do
      let(:object) { project }
      let(:directives) { [create_directive(boundary: 'itself', boundary_type: 'project')] }

      it 'returns the object itself' do
        expect(extracted).to contain_exactly(project)
      end
    end

    context 'when the boundary is a method on the object' do
      let(:object) { issue }
      let(:directives) { [create_directive(boundary: 'project', boundary_type: 'project')] }

      it 'returns the result of calling the method' do
        expect(extracted).to contain_exactly(project)
      end
    end

    context 'when the resolved boundary does not match the declared boundary_type' do
      let(:object) { issue }
      let(:directives) { [create_directive(boundary: 'project', boundary_type: 'group')] }

      it 'skips the boundary' do
        expect(extracted).to be_empty
      end
    end

    context 'when the object does not respond to the boundary method' do
      let(:object) { project }
      let(:directives) { [create_directive(boundary: 'nonexistent_method', boundary_type: 'project')] }

      it 'returns no boundary' do
        expect(extracted).to be_empty
      end
    end

    context 'when the boundary method returns nil' do
      let_it_be(:personal_project) { create(:project) }

      let(:object) { personal_project }
      let(:directives) { [create_directive(boundary: 'group', boundary_type: 'group')] }

      it 'returns no boundary' do
        expect(extracted).to be_empty
      end
    end

    context 'when the directive has no boundary method' do
      let(:object) { issue }
      let(:directives) { [create_directive(boundary_type: 'project')] }

      it 'returns no boundary instead of raising' do
        expect { extracted }.not_to raise_error
        expect(extracted).to be_empty
      end
    end

    context 'with a standalone boundary' do
      let(:object) { issue }
      let(:directives) { [create_directive(boundary_type: 'user')] }

      it 'returns the boundary_type symbol' do
        expect(extracted).to contain_exactly(:user)
      end
    end

    context 'with both a concrete and a standalone boundary directive' do
      let(:object) { project }
      let(:directives) do
        [
          create_directive(boundary: 'itself', boundary_type: 'project'),
          create_directive(boundary_type: 'instance')
        ]
      end

      it 'prefers the concrete boundary over the standalone one' do
        expect(extracted).to contain_exactly(project)
      end
    end

    context 'when the concrete boundary does not match and a standalone boundary is present' do
      let(:object) { project }
      let(:directives) do
        [
          create_directive(boundary: 'itself', boundary_type: 'group'),
          create_directive(boundary_type: 'instance')
        ]
      end

      it 'falls back to the standalone boundary' do
        expect(extracted).to contain_exactly(:instance)
      end
    end

    context 'with duplicate concrete boundary directives' do
      let(:object) { project }
      let(:directives) do
        [
          create_directive(boundary: 'itself', boundary_type: 'project'),
          create_directive(boundary: 'itself', boundary_type: 'project')
        ]
      end

      it 'de-duplicates the resolved resources' do
        expect(extracted).to contain_exactly(project)
      end
    end

    context 'when there are no directives' do
      let(:object) { project }
      let(:directives) { [] }

      it 'returns an empty array' do
        expect(extracted).to eq([])
      end
    end
  end
end
