# frozen_string_literal: true

module Gitlab
  module PrinciplesDistiller
    class Sync
      # Manifest loading, validation, frontmatter handling, affected-principle
      # detection, AGENTS.md / SKILL.md generation, and prerequisite-note
      # injection. Owns the SSOT file_cache.
      #
      # `@data` is not synchronized; callers must load before forking (see
      # `Sync#parallel_distill`'s assertion).
      class Manifest
        MANIFEST_PATH = '.ai/principles/manifest.yml'
        PRINCIPLES_DIR = '.ai/principles/distilled'
        CLAUDE_SKILL_DIR = '.claude/skills/gitlab-coding-principles'
        CLAUDE_SKILL_PATH = "#{CLAUDE_SKILL_DIR}/SKILL.md".freeze
        AGENTS_SKILL_PATH = '.agents/skills/gitlab-coding-principles/SKILL.md'

        # Global, cross-cutting files regenerated from the manifest on every
        # run. They embed the full routing table for ALL principles, so SSOT
        # teams have no stake in their content; the per-team MR fan-out routes
        # them to a separate "tooling" MR (see Sync::AutoMr).
        TOOLING_PATHS = [
          'AGENTS.md',
          'CLAUDE.md',
          AGENTS_SKILL_PATH,
          CLAUDE_SKILL_PATH
        ].freeze

        AUTO_MR_REQUIRED_KEYS = %w[branch_prefix title_template labels remove_source_branch].freeze

        def initialize
          @file_cache = {}
          @file_cache_mutex = Mutex.new
        end

        attr_reader :file_cache

        # The parsed YAML hash. The writer is a public test seam: specs
        # can inject fixtures without a manifest.yml on disk, bypassing
        # validate_principles!. Production code only reaches `data` via
        # `load`, where validation runs.
        attr_writer :data

        def data
          @data ||= load
        end

        def loaded?
          !@data.nil?
        end

        def load
          path = Workspace.safe_join(MANIFEST_PATH)
          abort Rainbow("ERROR: Manifest not found at #{path}").red unless File.exist?(path)

          @data = YAML.safe_load_file(path)
          validate_principles!
          @data
        end

        def principles
          data.fetch('principles', {})
        end

        def static_entries
          data.fetch('static_entries', [])
        end

        def principle_config(name)
          principles[name]
        end

        # No hardcoded fallbacks: missing keys fail fast rather than
        # masking misconfig with stale defaults.
        def auto_mr_config
          cfg = data['auto_mr']
          abort Rainbow("ERROR: manifest.yml is missing the `auto_mr:` block").red unless cfg.is_a?(Hash)

          missing = AUTO_MR_REQUIRED_KEYS - cfg.keys
          abort Rainbow("ERROR: manifest.yml `auto_mr:` is missing keys: #{missing.join(', ')}").red if missing.any?

          cfg
        end

        def principles_path(name)
          File.join(PRINCIPLES_DIR, principles_filename(name))
        end

        # The team-grouping label for a principle. Defaults to the `group`
        # field; principles without a group fall back to "Other" so they
        # still get their own MR rather than being silently dropped.
        #
        # TODO: `group` is an interim grouping axis. The dedicated `owner_team`
        # field (mapping each principle to its SSOT-owning CODEOWNERS team) is
        # tracked as Phase 2 in
        # https://gitlab.com/gitlab-org/gitlab/-/issues/599920.
        def principle_team(name)
          principle_config(name)&.dig('group') || 'Other'
        end

        # URL/branch-safe slug derived from the team label, used as the
        # per-team branch suffix (e.g. "Code Review" -> "code-review").
        #
        # TODO: an explicit `team_slug` manifest field is deferred to Phase 2
        # of https://gitlab.com/gitlab-org/gitlab/-/issues/599920.
        def team_slug(team)
          team.to_s.downcase.strip.gsub(/[^a-z0-9]+/, '-').gsub(/\A-+|-+\z/, '')
        end

        # Groups the given principle names by team label, preserving the
        # manifest's declaration order for both teams and members.
        def group_principles_by_team(names)
          ordered = principles.keys & names.to_a
          ordered.each_with_object({}) do |name, by_team|
            (by_team[principle_team(name)] ||= []) << name
          end
        end

        def build_diff_hint(sha, source_paths)
          ['git', 'diff', "#{sha[0, 12]}..HEAD", '--', *source_paths].shelljoin
        end

        def load_frontmatter_data
          Dir.glob(Workspace.safe_join(PRINCIPLES_DIR, '*.md')).each_with_object({}) do |path, data|
            name = File.basename(path, '.md')
            frontmatter = extract_frontmatter(File.read(path))
            next unless frontmatter&.key?('source_checksum')

            data[name] = {
              checksum: frontmatter['source_checksum'],
              distilled_at_sha: frontmatter['distilled_at_sha']
            }
          end
        end

        def extract_frontmatter(content)
          return unless content.start_with?("---\n")

          _empty, frontmatter, _rest = content.split("---\n", 3)
          YAML.safe_load(frontmatter) if frontmatter
        end

        def strip_frontmatter(content)
          return content unless content.start_with?("---\n")

          parts = content.split("---\n", 3)
          parts.size == 3 ? parts[2].lstrip : content
        end

        def compute_checksum(config)
          sources = config.fetch('sources', [])
          digest = OpenSSL::Digest.new('SHA256')

          # Hash routing-relevant fields so changes to description, group,
          # prerequisite, or file_filters invalidate the checksum.
          # `to_json` keeps the encoding canonical across YAML quote-style
          # round-trips while preserving the nil/""/false distinction.
          %w[description group prerequisite].each do |key|
            digest.update("#{key}=#{config[key].to_json}")
          end
          Array(config['file_filters']).each { |filter| digest.update(filter) }

          baseline_path = config['baseline']
          if baseline_path
            digest.update(baseline_path)
            baseline_content = read_repo_file(baseline_path)
            digest.update(baseline_content) if baseline_content
          end

          sources.each do |source|
            digest.update(source['path'])
            content = read_repo_file(source['path'])
            digest.update(content) if content
          end

          # 16 hex chars: collision-free for ~25 principles, short enough
          # to skim in MR diffs.
          digest.hexdigest[0, 16]
        end

        def affected_principles(force: false, only: nil)
          frontmatter_data = load_frontmatter_data

          principles.each_with_object({}) do |(name, config), affected|
            if only && !only.include?(name) # -- standalone script without Rails
              puts "  ⏭️  #{name}: #{Rainbow('skipped (not in --only list)').faint}"
              next
            end

            current_checksum = compute_checksum(config)
            stored = frontmatter_data[name]
            stored_checksum = stored&.dig(:checksum)

            if !force && current_checksum == stored_checksum
              puts "  ✅ #{name}: #{Rainbow('up to date').green}"
            else
              sources = config.fetch('sources', [])
              distilled_at_sha = stored&.dig(:distilled_at_sha)
              affected[name] = {
                config: config,
                changed_sources: sources,
                prior_sha: distilled_at_sha
              }

              reason = if force
                         'forced'
                       else
                         (stored_checksum ? 'sources or docs changed' : 'no previous checksum')
                       end

              puts "  🔄 #{name}: #{Rainbow('needs update').yellow} (#{reason})"

              if distilled_at_sha
                source_paths = sources.map { |s| s['path'] }
                baseline_path = config['baseline']
                source_paths.unshift(baseline_path) if baseline_path
                diff_cmd = build_diff_hint(distilled_at_sha, source_paths)
                puts "     🔍 To see what changed: #{Rainbow(diff_cmd).cyan}"
              end
            end
          end
        end

        def read_repo_file(path)
          # Guard file_cache writes from concurrent parallel_distill threads.
          @file_cache_mutex.synchronize do
            file_cache[path] ||= begin
              # `path` originates from the manifest YAML; `safe_join` rejects
              # traversal segments that would escape the workspace. Same
              # guarantee applies to the other `Workspace.safe_join` callsites
              # in this gem.
              full_path = Workspace.safe_join(path)
              if File.exist?(full_path)
                File.read(full_path)
              else
                dir = full_path.sub(%r{(\.md|/)$}, '')
                idx_path = File.join(dir, '_index.md')
                File.read(idx_path) if File.exist?(idx_path)
              end
            end
          end
        end

        def sources_footer(config)
          sources = config.fetch('sources', [])
          return '' if sources.empty?

          lines = sources.map { |s| "- #{s['path']}" }.join("\n")
          <<~FOOTER
            ## Authoritative sources

            For the full picture, see:

            #{lines}
          FOOTER
        end

        # Writes the gitlab-coding-principles SKILL.md to both .agents/
        # (OpenCode) and .claude/ (Claude Code).
        def generate_principles_skill
          routing_table = build_skill_routing_table

          skill_content = <<~SKILL
            ---
            name: gitlab-coding-principles
            description: Load all relevant GitLab development principles before planning or implementing. Evaluates every principle group to ensure cross-domain coverage.
            ---

            # Load Project Principles

            #{routing_table.rstrip}
          SKILL

          written = []
          [
            Workspace.safe_join(AGENTS_SKILL_PATH),
            Workspace.safe_join(CLAUDE_SKILL_PATH)
          ].each do |path|
            next if File.exist?(path) && File.read(path) == skill_content

            FileUtils.mkdir_p(File.dirname(path))
            File.write(path, skill_content)
            written << path.delete_prefix("#{Workspace.path}/")
          end

          if written.any?
            puts "  Written skill to: #{written.join(', ')}"
          else
            puts Rainbow('  Skill already up to date').faint
          end
        end

        # Refreshes the generated OpenCode-context section in AGENTS.md (and
        # copies the result to CLAUDE.md for parity).
        def generate_agents_md_context_loading
          routing_table = build_skill_routing_table

          generated_header = '<!-- BEGIN GENERATED: gitlab-ai-principles-distiller — do not edit manually -->'
          generated_footer = '<!-- END GENERATED -->'

          opencode_section = [
            generated_header,
            '### OpenCode',
            '',
            routing_table.rstrip,
            generated_footer
          ].join("\n")

          agents_path = Workspace.safe_join('AGENTS.md')
          return unless File.exist?(agents_path)

          content = File.read(agents_path)

          updated = content.sub(
            /#{Regexp.escape(generated_header)}\n.*?#{Regexp.escape(generated_footer)}/m,
            opencode_section
          )

          return if updated == content

          File.write(agents_path, updated)

          claude_path = Workspace.safe_join('CLAUDE.md')
          File.write(claude_path, updated)

          puts "  Updated AGENTS.md and CLAUDE.md (#{principles.size} principles, " \
            "#{static_entries.size} static entries)"
        end

        # Idempotent. Updates existing notes if wording changed.
        def inject_prerequisite_notes
          principles.each_key do |name|
            note = prerequisite_note(name)
            next unless note

            path = Workspace.safe_join(principles_path(name))
            next unless File.exist?(path)

            content = File.read(path)

            auto_header_pattern = /^(<!-- Auto-generated.*-->)\n\n*/

            if content.include?('> **Prerequisite:**')
              stripped = content.sub(/^> \*\*Prerequisite:\*\*.*\n\n+/, '')
              updated = stripped.sub(auto_header_pattern, "\\1\n\n#{note}")
              next if updated == content

              File.write(path, updated)
              puts "  #{name}: updated prerequisite note"
              next
            end

            updated = content.sub(auto_header_pattern, "\\1\n\n#{note}")
            next if updated == content

            File.write(path, updated)
            puts "  #{name}: injected prerequisite note"
          end
        end

        # Returns the blockquote note to prepend to a non-prerequisite
        # distilled file, or nil if no prerequisite siblings apply.
        def prerequisite_note(name)
          config = principle_config(name)
          return if config.nil? || config['prerequisite']

          group = config['group']
          return if group.nil?

          prereqs = principles.select do |n, c|
            n != name && c['group'] == group && c['prerequisite']
          end
          return if prereqs.empty?

          paths = prereqs.keys.map { |n| ".ai/principles/distilled/#{n}.md" }.join(', ')
          note = "> **Prerequisite:** If you haven't already, also read #{paths} - " \
            "it contains foundational rules that apply to all #{group.downcase} work."
          "#{note}\n\n"
        end

        private

        # Surfaces misconfigured principles at load time. Only invoked
        # from `load`; specs injecting via `data=` skip this.
        def validate_principles!
          missing = principles.each_with_object([]) do |(name, config), bad|
            bad << name if Array(config['sources']).empty?
          end
          return if missing.empty?

          abort Rainbow(
            "ERROR: manifest.yml principles missing required `sources:` entries: #{missing.join(', ')}"
          ).red
        end

        def principles_filename(name)
          "#{name}.md"
        end

        # Routing-table body shared by AGENTS.md and the SKILL.md files.
        def build_skill_routing_table
          groups = {}
          groups_order = []
          principles.each do |name, config|
            group = config['group'] || 'Other'
            unless groups.key?(group)
              groups[group] = []
              groups_order << group
            end

            groups[group] << { name: name, description: config['description'],
                               prerequisite: config['prerequisite'] == true }
          end

          lines = [
            'Evaluate ALL groups below and load principles from EVERY group that applies to',
            'your task. Most tasks span multiple groups (e.g., a model change may need',
            'Backend, Database, and Testing principles). DO NOT stop after the first group.',
            'When your task involves database queries, scopes, or data access patterns,',
            'ALWAYS load Database principles regardless of which files you are editing.',
            ''
          ]
          groups_order.each do |group|
            lines << "**#{group}:**"
            prerequisites = groups[group].select { |e| e[:prerequisite] }

            groups[group].each do |entry|
              line = "- **#{entry[:description]}**: Read .ai/principles/distilled/#{entry[:name]}.md"
              line += agents_md_prerequisite_suffix(entry, prerequisites, group)
              lines << line
            end

            lines << ''
          end

          static_entries.each do |entry|
            lines << "- **#{entry['description']}**: Read #{entry['path']}"
          end

          lines.join("\n")
        end

        def agents_md_prerequisite_suffix(entry, prerequisites, group)
          if entry[:prerequisite]
            " *(load for any #{group.downcase} work)*"
          elsif prerequisites.any?
            also = prerequisites.map { |p| ".ai/principles/distilled/#{p[:name]}.md" }.join(', ')
            " *(also load: #{also})*"
          else
            ''
          end
        end
      end
    end
  end
end
