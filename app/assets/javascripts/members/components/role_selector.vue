<script>
import { GlBadge, GlCollapsibleListbox, GlLink, GlPopover, GlSprintf } from '@gitlab/ui';
import { ACCESS_LEVEL_SECURITY_MANAGER_STRING } from '~/access_level/constants';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';

export default {
  ACCESS_LEVEL_SECURITY_MANAGER_STRING,
  badgeId: 'security-manager-role-badge',
  helpPath: helpPagePath('user/permissions'),
  components: { GlBadge, GlCollapsibleListbox, GlLink, GlPopover, GlSprintf },
  inject: {
    manageMemberRolesPath: { default: null },
  },
  props: {
    roles: {
      type: Object,
      required: true,
    },
    value: {
      type: Object,
      required: false,
      default: null,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    headerText: {
      type: String,
      required: false,
      default: s__('MemberRole|Change role'),
    },
  },
  computed: {
    manageRolesText() {
      return this.manageMemberRolesPath ? s__('MemberRole|Manage roles') : '';
    },
  },
  methods: {
    navigateToManageMemberRolesPage() {
      visitUrl(this.manageMemberRolesPath);
    },
    emitRole(selectedValue) {
      const role = this.roles.flatten.find(({ value }) => value === selectedValue);
      this.$emit('input', role);
    },
    openPermissionsHelpPage() {
      visitUrl(helpPagePath('user/permissions'), true);
    },
  },
};
</script>

<template>
  <gl-collapsible-listbox
    :header-text="headerText"
    :reset-button-label="manageRolesText"
    :items="roles.formatted"
    :selected="value && value.value"
    :loading="loading"
    block
    fluid-width
    @reset="navigateToManageMemberRolesPage"
    @select="emitRole"
  >
    <template #list-item="{ item }">
      <div class="gl-flex gl-items-start gl-justify-between gl-gap-2" data-testid="role-data">
        <span data-testid="role-name">{{ item.text }}</span>
        <gl-badge
          v-if="item.value === $options.ACCESS_LEVEL_SECURITY_MANAGER_STRING"
          :id="$options.badgeId"
          variant="info"
        >
          {{ __('New') }}

          <gl-popover
            :target="$options.badgeId"
            :title="s__('MemberRole|Security Manager role now available')"
            css-classes="gl-max-w-xs"
            placement="top"
            boundary="viewport"
          >
            <gl-sprintf
              :message="
                s__(
                  'MemberRole|The Security Manager role provides comprehensive access to security features, including vulnerability management, security dashboards, policy configuration, and compliance tools. Designed for users who manage security and compliance across your organization. %{linkStart}Learn more.%{linkEnd}',
                )
              "
            >
              <template #link="{ content }">
                <gl-link @mousedown.prevent="openPermissionsHelpPage">{{ content }}</gl-link>
              </template>
            </gl-sprintf>
          </gl-popover>
        </gl-badge>
      </div>
      <div
        v-if="item.dropdownDescription || item.description"
        class="gl-mt-1 gl-whitespace-normal gl-text-sm"
        data-testid="role-description"
      >
        <span class="gl-text-subtle">{{ item.dropdownDescription || item.description }}</span>
      </div>
    </template>
  </gl-collapsible-listbox>
</template>
