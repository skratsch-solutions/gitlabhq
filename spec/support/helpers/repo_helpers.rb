# frozen_string_literal: true

module RepoHelpers
  extend self

  # Text file in repo
  #
  # Ex.
  #
  #   # Get object
  #   blob = RepoHelpers.text_blob
  #
  #   blob.path # => 'files/js/commit.js.coffee'
  #   blob.data # => 'class Commit...'
  #
  # Build the options hash that's passed to Rugged::Commit#create

  def sample_blob
    OpenStruct.new(
      oid: '5f53439ca4b009096571d3c8bc3d09d30e7431b3',
      path: "files/js/commit.js.coffee",
      data: <<EOS
class Commit
  constructor: ->
    $('.files .diff-file').each ->
      new CommitFile(this)

@Commit = Commit
EOS
    )
  end

  def sample_commit
    OpenStruct.new(
      id: "570e7b2abdd848b95f2f578043fc23bd6f6fd24d",
      sha: "570e7b2abdd848b95f2f578043fc23bd6f6fd24d",
      parent_id: '6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9',
      author_full_name: "Dmitriy Zaporozhets",
      author_email: "dmitriy.zaporozhets@gmail.com",
      files_changed_count: 2,
      line_code: '2f6fcd96b88b36ce98c38da085c795a27d92a3dd_15_14',
      line_code_path: 'files/ruby/popen.rb',
      del_line_code: '2f6fcd96b88b36ce98c38da085c795a27d92a3dd_13_13',
      referenced_by: [],
      message: <<EOS
Change some files
Signed-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
EOS
    )
  end

  def another_sample_commit
    OpenStruct.new(
      id: "e56497bb5f03a90a51293fc6d516788730953899",
      sha: "e56497bb5f03a90a51293fc6d516788730953899",
      parent_id: '4cd80ccab63c82b4bad16faa5193fbd2aa06df40',
      author_full_name: "Sytse Sijbrandij",
      author_email: "sytse@gitlab.com",
      files_changed_count: 1,
      referenced_by: [],
      message: <<EOS
Add directory structure for tree_helper spec

This directory structure is needed for a testing the method flatten_tree(tree) in the TreeHelper module

See [merge request #275](https://gitlab.com/gitlab-org/gitlab-foss/merge_requests/275#note_732774)

See merge request !2
EOS
    )
  end

  def sample_big_commit
    OpenStruct.new(
      id: "913c66a37b4a45b9769037c55c2d238bd0942d2e",
      sha: "913c66a37b4a45b9769037c55c2d238bd0942d2e",
      author_full_name: "Dmitriy Zaporozhets",
      author_email: "dmitriy.zaporozhets@gmail.com",
      referenced_by: [],
      message: <<EOS
Files, encoding and much more
Signed-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
EOS
    )
  end

  def sample_image_commit
    OpenStruct.new(
      id: "2f63565e7aac07bcdadb654e253078b727143ec4",
      sha: "2f63565e7aac07bcdadb654e253078b727143ec4",
      author_full_name: "Dmitriy Zaporozhets",
      author_email: "dmitriy.zaporozhets@gmail.com",
      old_blob_id: '33f3729a45c02fc67d00adb1b8bca394b0e761d9',
      new_blob_id: '2f63565e7aac07bcdadb654e253078b727143ec4',
      referenced_by: [],
      message: <<EOS
Modified image
Signed-off-by: Dmitriy Zaporozhets <dmitriy.zaporozhets@gmail.com>
EOS
    )
  end

  def sample_compare(extra_changes = [])
    changes = [
      {
        line_code: 'a5cc2925ca8258af241be7e5b0381edf30266302_20_20',
        file_path: '.gitignore'
      },
      {
        line_code: '7445606fbf8f3683cd42bdc54b05d7a0bc2dfc44_4_6',
        file_path: '.gitmodules'
      }
    ] + extra_changes

    commits = %w[
      5937ac0a7beb003549fc5fd26fc247adbce4a52e
      570e7b2abdd848b95f2f578043fc23bd6f6fd24d
      6f6d7e7ed97bb5f0054f2b1df789b39ca89b6ff9
      d14d6c0abdd253381df51a723d58691b2ee1ab08
      c1acaa58bbcbc3eafe538cb8274ba387047b69f8
    ].reverse # last commit is recent one

    reviewers = [
      {
        "user" => {
          "name" => "Jane",
          "emailAddress" => "jane@doe.com",
          "displayName" => "Jane Doe",
          "slug" => "jane_doe"
        }
      },
      {
        "user" => {
          "name" => "John",
          "emailAddress" => "john@smith.com",
          "displayName" => "John Smith",
          "slug" => "john_smith"
        }
      }
    ]

    OpenStruct.new(
      source_branch: 'master',
      target_branch: 'feature',
      changes: changes,
      commits: commits,
      reviewers: reviewers
    )
  end

  def create_file_in_repo(
    project, start_branch, branch_name, filename, content,
    commit_message: 'Add new content')
    Files::CreateService.new(
      project,
      project.first_owner,
      commit_message: commit_message,
      start_branch: start_branch,
      branch_name: branch_name,
      file_path: filename,
      file_content: content
    ).execute
  end

  def create_and_delete_files(project, files, &block)
    files.each do |filename, content|
      project.repository.create_file(
        project.creator,
        filename,
        content,
        message: "Automatically created file #{filename}",
        branch_name: project.default_branch_or_main
      )
    end

    yield

  ensure
    files.each do |filename, _content|
      project.repository.delete_file(
        project.creator,
        filename,
        message: "Automatically deleted file #{filename}",
        branch_name: project.default_branch_or_main
      )
    end
  end

  def sync_local_files_to_project(project, user, branch_name, files:)
    actions = []

    entries = project.repository.tree(branch_name, recursive: true).entries
    entries.map! { |e| e.dir? ? project.repository.tree(branch_name, e.path, recursive: true).entries : e }
    current_files = entries.flatten.select(&:file?).map(&:path).uniq

    # Delete old
    actions.concat (current_files - files).map { |file| { action: :delete, file_path: file } }
    # Add new
    actions.concat (files - current_files).map { |file|
                     { action: :create, file_path: file, content: read_file(file) }
                   }

    # Update changed
    (current_files & files).each do |file|
      content = read_file(file)
      if content != project.repository.blob_data_at(branch_name, file)
        actions << { action: :update, file_path: file, content: content }
      end
    end

    if actions.any?
      puts "Syncing files to #{branch_name} branch"
      # changes = actions.group_by { |a| a[:action] }.transform_values { |values| values.pluck(:file_path) }
      # changes.each do |action, paths|
      #   puts "#{action}: #{paths}"
      # end
      project.repository.commit_files(user, branch_name: branch_name, message: 'syncing', actions: actions)
    else
      puts "No file syncing needed"
    end
  end

  def read_file(file, ignore_ci_component: true)
    content = File.read(file)

    return content unless ignore_ci_component

    fake_job = <<~YAML
    .ignore:
      script: echo ok
    YAML

    file.end_with?('.yml') && %r{^\s*- component:.*CI_SERVER_}.match?(content) ? fake_job : content
  end
end
