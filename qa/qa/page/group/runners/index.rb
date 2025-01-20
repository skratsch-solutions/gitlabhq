# frozen_string_literal: true

module QA
  module Page
    module Group
      module Runners
        class Index < Page::Base
          view "app/assets/javascripts/ci/runner/group_runners/group_runners_app.vue" do
            element 'new-group-runner-button'
          end

          # Returns total count of all runner types
          #
          # @return [Integer]
          def count_all_runners
            find_element("runner-count-all").text.to_i
          end

          # Returns total count of group runner types
          #
          # @return [Integer]
          def count_group_runners
            find_element("runner-count-group").text.to_i
          end

          # Returns total count of project runner types
          #
          # @return [Integer]
          def count_project_runners
            find_element("runner-count-project").text.to_i
          end

          # Returns count of online runners
          #
          # @return [Integer]
          def count_online_runners
            within_element("runner-stats-online") do
              find_element("non-animated-value").text.to_i
            end
          end

          def has_active_runner?(runner)
            within_element("runner-row-#{runner.id}") do
              has_content?(runner.name)
              has_element?('status-active-icon')
            end
          end

          def has_runner_with_expected_tags?(runner)
            within_element("runner-row-#{runner.id}") do
              runner.tags.all? { |tag| has_content?(tag) }
            end
          end

          def has_no_runner?(runner)
            has_no_element?("runner-row-#{runner.id}")
          end

          def go_to_runner_managers_page(runner)
            within_element("runner-row-#{runner.id}") do
              within_element("td-summary") do
                find_element("a[href*='/runners/#{runner.id}']").click
              end
            end
          end
        end
      end
    end
  end
end
