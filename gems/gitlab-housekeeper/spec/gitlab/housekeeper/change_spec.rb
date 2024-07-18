# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::Housekeeper::Change do
  let(:change) { described_class.new }

  before do
    change.title = 'The title'
    change.description = 'The description'
    change.keep_class = Object
  end

  describe '#initialize' do
    it 'sets default values for optional fields' do
      change = described_class.new

      expect(change.labels).to eq([])
      expect(change.assignees).to eq([])
      expect(change.reviewers).to eq([])
      expect(change.push_options.ci_skip).to eq(false)
    end
  end

  describe '#assignees=' do
    it 'always sets an array' do
      change = described_class.new
      change.assignees = 'foo'

      expect(change.assignees).to eq(['foo'])
    end
  end

  describe '#reviewers=' do
    it 'always sets an array' do
      change = described_class.new
      change.reviewers = 'foo'

      expect(change.reviewers).to eq(['foo'])
    end
  end

  describe '#mr_description' do
    it 'includes standard content' do
      expect(change.mr_description).to eq(
        <<~MARKDOWN
        The description

        This change was generated by
        [gitlab-housekeeper](https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-housekeeper)
        using the Object keep.

        To provide feedback on your experience with `gitlab-housekeeper` please create an issue with the
        label ~"GitLab Housekeeper" and consider pinging the author of this keep.
        MARKDOWN
      )
    end
  end

  describe '#update_required?' do
    let(:change) { create_change }

    it 'returns false if the category is in non_housekeeper_changes' do
      change.non_housekeeper_changes = [:code]
      expect(change.update_required?(:code)).to eq(false)
    end

    it 'returns true if the category is not in non_housekeeper_changes' do
      change.non_housekeeper_changes = [:title]
      expect(change.update_required?(:code)).to eq(true)
    end
  end

  describe '#commit_message' do
    it 'includes standard content' do
      expect(change.commit_message).to eq(
        <<~MARKDOWN
        The title

        The description

        This change was generated by
        [gitlab-housekeeper](https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-housekeeper)
        using the Object keep.

        To provide feedback on your experience with `gitlab-housekeeper` please create an issue with the
        label ~"GitLab Housekeeper" and consider pinging the author of this keep.


        Changelog: other
        MARKDOWN
      )
    end

    context 'when setting a "changelog_type"' do
      before do
        change.changelog_type = 'removed'
      end

      it 'incudes "Changelog: removed"' do
        expect(change.commit_message).to eq(
          <<~MARKDOWN
          The title

          The description

          This change was generated by
          [gitlab-housekeeper](https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-housekeeper)
          using the Object keep.

          To provide feedback on your experience with `gitlab-housekeeper` please create an issue with the
          label ~"GitLab Housekeeper" and consider pinging the author of this keep.


          Changelog: removed
          MARKDOWN
        )
      end
    end
  end

  context 'when setting a "changelog_ee"' do
    before do
      change.changelog_ee = true
    end

    it 'includes "EE: true"' do
      expect(change.commit_message).to eq(
        <<~MARKDOWN
          The title

          The description

          This change was generated by
          [gitlab-housekeeper](https://gitlab.com/gitlab-org/gitlab/-/tree/master/gems/gitlab-housekeeper)
          using the Object keep.

          To provide feedback on your experience with `gitlab-housekeeper` please create an issue with the
          label ~"GitLab Housekeeper" and consider pinging the author of this keep.


          Changelog: other
          EE: true
        MARKDOWN
      )
    end
  end

  describe '#valid?' do
    it 'is not valid if missing required attributes' do
      [:identifiers, :title, :description, :changed_files].each do |attribute|
        change = create_change
        expect(change).to be_valid
        change.public_send("#{attribute}=", nil)
        expect(change).not_to be_valid
      end
    end
  end

  describe '#matches_filters?' do
    let(:identifiers) { %w[this-is a-list of IdentifierS] }
    let(:change) { create_change(identifiers: identifiers) }

    it 'matches when all regexes match at least one identifier' do
      expect(change.matches_filters?([/list/, /Ide.*fier/])).to eq(true)
    end

    it 'does not match when none of the regexes match' do
      expect(change.matches_filters?([/nomatch/, /Ide.*fffffier/])).to eq(false)
    end

    it 'does not match when only some of the regexes match' do
      expect(change.matches_filters?([/nomatch/, /Ide.*fier/])).to eq(false)
    end

    it 'matches an empty list of filters' do
      expect(change.matches_filters?([])).to eq(true)
    end
  end
end
