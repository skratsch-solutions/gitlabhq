# frozen_string_literal: true

module Gitlab
  module PrinciplesDistiller
    class Sync
      # Regenerates the gem-managed fenced regions inside the Duo Code Review
      # custom-instructions file (.gitlab/duo/mr-review-instructions.yaml).
      #
      # Each region is a single Duo instruction group whose body is sourced
      # from a distilled principle. The region is delimited by slim sentinel
      # comments so the generator can find, rebuild, and replace it in place
      # without disturbing the hand-authored groups around it:
      #
      #   # >>> generated: <principle> (gem-managed sentinel; see BEGIN_SUFFIX)
      #   # distilled_at_sha: <sha>
      #   # source_checksum: <checksum>
      #   - name: <hand-authored>
      #     fileFilters:
      #       - "<hand-authored glob>"
      #     instructions: |
      #       <distilled body + Reference paths>
      #   # <<< end generated: <principle>
      #
      # The generator OWNS the directive comments (distilled_at_sha,
      # source_checksum) and the instructions body; it PRESERVES the
      # hand-authored `- name:` and `fileFilters:` lines verbatim, since those
      # encode editorial decisions (group naming, sub-principle scoping) that
      # do not live in the manifest.
      #
      # References are emitted as repo-relative paths (manifest `sources[].path`)
      # because Code Review Flow only fetches in-repo paths or /-/blob/ URLs,
      # not docs.gitlab.com URLs.
      #
      # Discovery is by existing markers only: a principle is regenerated iff
      # its region already exists in the file. Seeding a new fence is a
      # deliberate, reviewed manual step; the generator then keeps it fresh.
      #
      # This module is pure (no I/O): callers inject the distilled data so it
      # can be unit-tested without a workspace, mirroring Sync::Links.
      module DuoInstructions
        extend self

        DUO_PATH = '.gitlab/duo/mr-review-instructions.yaml'

        # Block-scalar bodies are indented six spaces (two for the list item,
        # four for the `instructions:` mapping value).
        BODY_INDENT = '      '

        # Trailing text on the slim BEGIN marker line, after the principle key.
        BEGIN_SUFFIX = '— gitlab-ai-principles-distiller (from .ai/principles/manifest.yml; do not edit)'

        # Marker that opens a generated region. The capture is the principle key.
        BEGIN_MARKER = /^  # >>> generated: (?<principle>\S+) #{Regexp.escape(BEGIN_SUFFIX)}$/

        # Captures one whole generated region (BEGIN line through END line) and
        # the principle key, so the region can be replaced as a unit.
        REGION_PATTERN = /
          ^[ ]{2}\#[ ]>>>[ ]generated:[ ](?<principle>\S+)[ ]#{Regexp.escape(BEGIN_SUFFIX)}$
          .*?
          ^[ ]{2}\#[ ]<<<[ ]end[ ]generated:[ ]\k<principle>$
        /mx

        # Pulls the recorded distilled_at_sha / source_checksum directives out
        # of an existing region so a check can compare them against the current
        # distilled frontmatter.
        DISTILLED_AT_SHA_DIRECTIVE = /^  # distilled_at_sha: (?<sha>\S+)$/
        SOURCE_CHECKSUM_DIRECTIVE = /^  # source_checksum: (?<checksum>\S+)$/

        # Returns the principle keys that currently have a generated region in
        # the file, in document order. Drives marker-only discovery.
        def fenced_principles(yaml_text)
          yaml_text.scan(BEGIN_MARKER).flatten
        end

        # Rebuilds every generated region from the injected `fences` data and
        # returns the updated YAML text (unchanged if every region already
        # matches its regenerated form).
        #
        # @param fences [Hash{String => Hash}] keyed by principle, each value:
        #   { name:, file_filters: [globs], distilled_body:, distilled_at_sha:,
        #     source_checksum:, references: [repo-relative paths] }
        #   Only principles present in `fences` are regenerated; a fenced
        #   principle missing from `fences` is left untouched (its distilled
        #   file may be absent).
        def regenerate(yaml_text, fences:)
          yaml_text.gsub(REGION_PATTERN) do |region|
            principle = Regexp.last_match(:principle)
            data = fences[principle]
            data ? build_region(principle, data, region) : region
          end
        end

        # Returns the principle keys whose recorded region directives no longer
        # match the current distilled file, i.e. the region is stale relative
        # to its distilled source. `fences` carries the current
        # distilled_at_sha / source_checksum for each principle.
        def check(yaml_text, fences:)
          each_region(yaml_text).filter_map do |principle, region|
            data = fences[principle]
            next unless data

            recorded_sha = region[DISTILLED_AT_SHA_DIRECTIVE, :sha]
            recorded_checksum = region[SOURCE_CHECKSUM_DIRECTIVE, :checksum]

            stale = recorded_sha != data[:distilled_at_sha] ||
              recorded_checksum != data[:source_checksum]
            principle if stale
          end
        end

        private

        # Yields [principle, region_text] for each generated region. Returns an
        # Enumerator when no block is given so callers can chain filter_map.
        def each_region(yaml_text)
          return to_enum(:each_region, yaml_text) unless block_given?

          yaml_text.scan(REGION_PATTERN) do
            yield Regexp.last_match(:principle), Regexp.last_match(0)
          end
        end

        # Assembles a full generated region, preserving the hand-authored
        # name/fileFilters block from the existing region and regenerating the
        # directives and instructions body.
        def build_region(principle, data, existing_region)
          [
            begin_marker(principle),
            *directive_comments(data),
            preserved_header(existing_region, data),
            '    instructions: |',
            *body_lines(data),
            end_marker(principle)
          ].join("\n")
        end

        def begin_marker(principle)
          "  # >>> generated: #{principle} #{BEGIN_SUFFIX}"
        end

        def end_marker(principle)
          "  # <<< end generated: #{principle}"
        end

        def directive_comments(data)
          [
            "  # distilled_at_sha: #{data[:distilled_at_sha]}",
            "  # source_checksum: #{data[:source_checksum]}"
          ]
        end

        # Reuses the existing `- name:` and `fileFilters:` lines from the
        # region (everything between the name line and `instructions:`), so the
        # editorial group name and sub-principle scope survive regeneration.
        # Falls back to manifest-derived values when seeding (no prior block).
        def preserved_header(existing_region, data)
          header = existing_region[/^  - name: .+?(?=^    instructions:)/m]
          return header.rstrip if header

          [
            "  - name: #{data[:name]}",
            '    fileFilters:',
            *data[:file_filters].map { |glob| "      - \"#{glob}\"" }
          ].join("\n")
        end

        # The body: the distilled checklist sections copied verbatim, then a
        # Reference line per source (repo-relative path).
        def body_lines(data)
          checklist = indent(data[:distilled_body].rstrip)
          references = data[:references].map { |path| "#{BODY_INDENT}- Reference: #{path}" }

          [*checklist, *references]
        end

        # Indents each body line by BODY_INDENT, leaving blank lines empty so
        # the YAML block scalar has no trailing whitespace.
        def indent(text)
          text.lines(chomp: true).map { |line| line.empty? ? '' : "#{BODY_INDENT}#{line}" }
        end
      end
    end
  end
end
