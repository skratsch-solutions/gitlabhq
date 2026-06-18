<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton } from '@gitlab/ui';
import { highCountTrim } from '~/lib/utils/text_utility';

export default {
  components: {
    GlButton,
  },
  props: {
    count: {
      type: [Number, String],
      required: true,
    },
    href: {
      type: String,
      required: false,
      default: null,
    },
    icon: {
      type: String,
      required: true,
    },
    label: {
      type: String,
      required: true,
    },
  },
  computed: {
    ariaLabel() {
      return `${this.count} ${this.label}`;
    },
    formattedCount() {
      if (Number.isFinite(this.count)) {
        return highCountTrim(this.count);
      }
      return this.count;
    },
    countExists() {
      return this.count.toString();
    },
  },
};
</script>

<template>
  <gl-button :aria-label="ariaLabel" class="!gl-px-3" :href="href" :icon="icon" category="tertiary">
    <span v-if="countExists" aria-hidden="true" class="gl-text-sm gl-font-semibold">
      {{ formattedCount }}
    </span>
  </gl-button>
</template>
