# frozen_string_literal: true

module Sidebars
  module Admin
    module Menus
      class MonitoringMenu < ::Sidebars::Admin::BaseMenu
        override :configure_menu_items
        def configure_menu_items
          add_item(system_info_menu_item)
          add_item(background_migrations_menu_item)
          add_item(background_jobs_menu_item)
          add_item(health_check_menu_item)
          add_item(metrics_dashboard_menu_item)
          true
        end

        override :title
        def title
          s_('Admin|Monitoring')
        end

        override :sprite_icon
        def sprite_icon
          'monitor'
        end

        override :extra_container_html_options
        def extra_container_html_options
          { testid: 'admin-monitoring-menu-link' }
        end

        private

        def system_info_menu_item
          ::Sidebars::MenuItem.new(
            title: _('System information'),
            link: admin_system_info_path,
            active_routes: { controller: 'system_info' },
            item_id: :system_info
          )
        end

        def background_migrations_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Background migrations'),
            link: admin_background_migrations_path,
            active_routes: { controller: 'background_migrations' },
            item_id: :background_migrations
          )
        end

        def background_jobs_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Background jobs'),
            link: admin_background_jobs_path,
            active_routes: { controller: 'background_jobs' },
            item_id: :background_jobs
          )
        end

        def health_check_menu_item
          ::Sidebars::MenuItem.new(
            title: _('Health check'),
            link: admin_health_check_path,
            active_routes: { controller: 'health_check' },
            item_id: :health_check
          )
        end

        def metrics_dashboard_menu_item
          return ::Sidebars::NilMenuItem.new(item_id: :metrics_dashboard) unless
            Gitlab::CurrentSettings.current_application_settings.grafana_enabled?

          ::Sidebars::MenuItem.new(
            title: _('Metrics Dashboard'),
            link: Gitlab::CurrentSettings.current_application_settings.grafana_url,
            active_routes: { path: Gitlab::CurrentSettings.current_application_settings.grafana_url },
            item_id: :metrics_dashboard
          )
        end
      end
    end
  end
end

Sidebars::Admin::Menus::MonitoringMenu.prepend_mod_with('Sidebars::Admin::Menus::MonitoringMenu')
