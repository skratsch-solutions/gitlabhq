<script>
import { GlTable, GlAlert, GlBadge, GlTooltipDirective } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { cloneWithoutReferences } from '~/lib/utils/common_utils';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import MirrorActions from './mirror_actions.vue';

export default {
  name: 'MirrorTable',
  components: {
    GlTable,
    GlAlert,
    GlBadge,
    MirrorActions,
    TimeAgoTooltip,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['projectId', 'settingsEnabled', 'repositoryMirrorsAvailable'],
  props: {
    initialMirrors: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      alertMessage: '',
      showAlert: false,
    };
  },
  computed: {
    tableItems() {
      return cloneWithoutReferences(this.initialMirrors);
    },
  },
  methods: {
    mirrorBranchesText(item) {
      switch (item.mirrorBranchesSetting) {
        case 'protected':
          return this.$options.i18n.allProtectedBranches;
        case 'regex':
          return this.$options.i18n.specificBranches;
        default:
          return this.$options.i18n.allBranches;
      }
    },
    directionText(item) {
      return item.direction === 'pull' ? this.$options.i18n.pull : this.$options.i18n.push;
    },
    hideAlert() {
      this.showAlert = false;
    },
    // TODO: Implement in follow-up MR
    onSync() {},
    onToggle() {},
    onDelete() {},
  },
  fields: [
    { key: 'url', label: s__('Mirror|Repository'), tdClass: '!gl-align-middle' },
    { key: 'direction', label: s__('Mirror|Direction'), tdClass: '!gl-align-middle' },
    {
      key: 'lastUpdateStartedAt',
      label: s__('Mirror|Last update attempt'),
      tdClass: '!gl-align-middle',
    },
    {
      key: 'lastUpdateAt',
      label: s__('Mirror|Last successful update'),
      tdClass: '!gl-align-middle',
    },
    { key: 'errorStatus', label: s__('Mirror|Status'), tdClass: '!gl-align-middle' },
    { key: 'actions', label: __('Actions'), thAlignRight: true, tdClass: '!gl-align-middle' },
  ],
  i18n: {
    push: __('Push'),
    pull: __('Pull'),
    never: s__('Mirror|Never'),
    disabledTooltip: s__('Mirror|This mirror is disabled and will not sync.'),
    error: s__('Mirror|Error'),
    disabled: s__('Mirror|Disabled'),
    emptyState: __('There are currently no mirrored repositories.'),
    failedToRemove: s__('Mirror|Failed to remove mirror.'),
    failedToSync: s__('Mirror|Failed to sync mirror.'),
    failedToDisable: s__('Mirror|Failed to disable mirror.'),
    failedToEnable: s__('Mirror|Failed to enable mirror.'),
    allBranches: s__('Mirror|All branches'),
    allProtectedBranches: s__('Mirror|All protected branches'),
    specificBranches: s__('Mirror|Specific branches'),
  },
};
</script>

<template>
  <div>
    <gl-alert v-if="showAlert" variant="danger" class="gl-mb-4" @dismiss="hideAlert">
      {{ alertMessage }}
    </gl-alert>
    <gl-table :items="tableItems" :fields="$options.fields" stacked="md" show-empty>
      <template #cell(url)="{ item }">
        {{ item.url }}
        <div v-if="repositoryMirrorsAvailable && item.mirrorBranchesSetting" class="gl-mt-3">
          <gl-badge
            v-gl-tooltip
            :title="item.mirrorBranchRegex || ''"
            data-testid="mirror-branches-badge"
          >
            {{ mirrorBranchesText(item) }}
          </gl-badge>
        </div>
      </template>
      <template #cell(direction)="{ item }">
        {{ directionText(item) }}
      </template>
      <template #cell(lastUpdateStartedAt)="{ item }">
        <time-ago-tooltip v-if="item.lastUpdateStartedAt" :time="item.lastUpdateStartedAt" />
        <span v-else>{{ $options.i18n.never }}</span>
      </template>
      <template #cell(lastUpdateAt)="{ item }">
        <time-ago-tooltip v-if="item.lastUpdateAt" :time="item.lastUpdateAt" />
        <span v-else>{{ $options.i18n.never }}</span>
      </template>
      <template #cell(errorStatus)="{ item }">
        <gl-badge
          v-if="!item.enabled"
          v-gl-tooltip
          variant="warning"
          :title="$options.i18n.disabledTooltip"
        >
          {{ $options.i18n.disabled }}
        </gl-badge>
        <gl-badge v-if="item.lastError" v-gl-tooltip variant="danger" :title="item.lastError">
          {{ $options.i18n.error }}
        </gl-badge>
      </template>
      <template #cell(actions)="{ item }">
        <mirror-actions
          v-if="settingsEnabled"
          :mirror="item"
          @sync="onSync"
          @toggle="onToggle"
          @delete="onDelete"
        />
      </template>
      <template #empty>
        <p data-testid="mirror-table-empty-state" class="gl-mb-0 gl-text-center gl-text-subtle">
          {{ $options.i18n.emptyState }}
        </p>
      </template>
    </gl-table>
  </div>
</template>
