#!/usr/bin/env ruby
# frozen_string_literal: true

require 'optparse'

require_relative 'per_test_coverage_artifact_downloader'

# CLI wrapper around PerTestCoverageArtifactDownloader. Reads the bridge job
# that triggered the per-test-coverage child pipeline, finds every job whose
# name matches the given regex, and pulls each job's artifacts into the
# output directory. The export jobs in `.gitlab/ci/coverage.gitlab-ci.yml`
# then feed the unpacked NDJSON / JSON files into the gem's
# `--per-test-coverage` flag.

options = { pattern: nil, output_dir: '.' }

OptionParser.new do |opts|
  opts.banner = 'Usage: download_per_test_coverage_artifacts.rb -p REGEX [-o PATH]'

  opts.on('-p', '--pattern REGEX', String,
    'Job-name regex matched against the child pipeline jobs (e.g. ' \
      '"^rspec(-ee)? .+ per-test-coverage( [0-9]+/[0-9]+)?$").') do |value|
    options[:pattern] = Regexp.new(value)
  end

  opts.on('-o', '--output-dir PATH', String,
    "Directory to extract artifacts into (default: #{options[:output_dir]}).") do |value|
    options[:output_dir] = value
  end

  opts.on('-h', '--help', 'Print this help and exit') do
    puts opts
    exit
  end
end.parse!

abort "Missing required --pattern. Run with --help for usage." unless options[:pattern]

exit PerTestCoverageArtifactDownloader.new(
  job_name_pattern: options[:pattern],
  output_dir: options[:output_dir]
).run
