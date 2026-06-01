<script>
import { GlAlert, GlButton, GlSprintf } from '@gitlab/ui';
import { __, n__ } from '~/locale';

export const i18n = {
  title: __('Some changes are not shown.'),
  plainDiff: __('Plain diff'),
  emailPatch: __('Patches'),
  download: __('To view all changes, download the diff.'),
};

export default {
  name: 'HiddenFilesWarning',
  i18n,
  components: {
    GlAlert,
    GlButton,
    GlSprintf,
  },
  props: {
    total: {
      type: [Number, String],
      required: true,
    },
    visible: {
      type: Number,
      required: true,
    },
    plainDiffPath: {
      type: String,
      default: undefined,
      required: false,
    },
    emailPatchPath: {
      type: String,
      default: undefined,
      required: false,
    },
  },
  computed: {
    listedCount() {
      // Accepts a number or a "N+" string; pluralization and display use the integer.
      return parseInt(this.total, 10) || 0;
    },
    listedMessage() {
      return n__(
        'Only the first %{count} file is listed on this page.',
        'Only the first %{count} files are listed on this page.',
        this.listedCount,
      );
    },
    expandedMessage() {
      return n__(
        '%{count} file is expanded by default.',
        '%{count} files are expanded by default.',
        this.visible,
      );
    },
  },
};
</script>

<template>
  <gl-alert variant="warning" class="gl-mb-5" :title="$options.i18n.title" :dismissible="false">
    <gl-sprintf :message="listedMessage">
      <template #count>
        <strong>{{ listedCount }}</strong>
      </template>
    </gl-sprintf>
    <gl-sprintf :message="expandedMessage">
      <template #count>
        <strong>{{ visible }}</strong>
      </template>
    </gl-sprintf>
    {{ $options.i18n.download }}
    <template #actions>
      <gl-button v-if="plainDiffPath" :href="plainDiffPath" class="gl-alert-action gl-mr-3">
        {{ $options.i18n.plainDiff }}
      </gl-button>
      <gl-button v-if="emailPatchPath" :href="emailPatchPath" class="gl-alert-action">
        {{ $options.i18n.emailPatch }}
      </gl-button>
    </template>
  </gl-alert>
</template>
