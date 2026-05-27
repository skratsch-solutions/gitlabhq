<script>
import { GlBadge } from '@gitlab/ui';
import { WINDOWS_BUILD_LABELS } from '../../constants/index';

export default {
  name: 'PlatformBadge',
  components: { GlBadge },
  props: {
    platform: {
      type: Object,
      required: true,
    },
  },
  computed: {
    platformText() {
      const { os, architecture, variant, osVersion } = this.platform;
      let text = `${os}/${architecture}`;

      if (variant) {
        text += `/${variant}`;
      }

      if (os === 'windows' && osVersion) {
        const buildNumber = parseInt(osVersion.split('.')[2], 10);
        const label = WINDOWS_BUILD_LABELS[buildNumber];
        if (label) {
          text += ` (${label})`;
        }
      }

      return text;
    },
  },
};
</script>

<template>
  <gl-badge>{{ platformText }}</gl-badge>
</template>
