<script>
import { GlButton, GlBadge, GlIcon, GlLink } from '@gitlab/ui';
import { sprintf, __, s__ } from '~/locale';
import { TIERS } from './constants';

export default {
  name: 'FeatureLibraryItem',
  components: { GlButton, GlBadge, GlIcon, GlLink },
  i18n: {
    free: __('Free'),
    premium: __('Premium'),
    ultimate: __('Ultimate'),
    addOn: __('Add-on'),
    pinLabel: s__('FeatureLibrary|Pin %{title}'),
    unpinLabel: s__('FeatureLibrary|Unpin %{title}'),
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
    pinned: {
      type: Boolean,
      required: false,
      default: false,
    },
    solidBackground: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['pin-toggle', 'navigate'],
  computed: {
    tierLabel() {
      switch (this.item.tier) {
        case TIERS.PREMIUM:
          return this.$options.i18n.premium;
        case TIERS.ULTIMATE:
          return this.$options.i18n.ultimate;
        case TIERS.ADD_ON:
          return this.$options.i18n.addOn;
        case TIERS.FREE:
        default:
          return this.$options.i18n.free;
      }
    },
    pinAriaLabel() {
      const template = this.pinned ? this.$options.i18n.unpinLabel : this.$options.i18n.pinLabel;
      return sprintf(template, { title: this.item.title });
    },
    pinIconName() {
      return this.pinned ? 'thumbtack-solid' : 'thumbtack';
    },
  },
  methods: {
    onPinClick() {
      this.$emit('pin-toggle', this.item.id, !this.pinned, this.item.title);
    },
    onNavigate() {
      this.$emit('navigate', this.item.id);
    },
  },
};
</script>

<template>
  <li
    class="gl-flex gl-items-start gl-gap-3 gl-rounded-xl gl-p-3"
    :class="
      solidBackground ? 'gl-bg-default hover:gl-shadow-md' : 'gl-bg-transparent hover:gl-bg-strong'
    "
  >
    <span
      class="gl-flex gl-h-7 gl-w-7 gl-shrink-0 gl-items-center gl-justify-center gl-rounded-lg gl-bg-strong"
    >
      <gl-icon :name="item.icon" :size="16" />
    </span>
    <div class="gl-min-w-0 gl-flex-grow">
      <gl-link
        v-if="item.link"
        variant="meta"
        :href="item.link"
        data-testid="feature-library-item-title"
        class="gl-font-bold"
        @click="onNavigate"
      >
        {{ item.title }}
      </gl-link>
      <span v-else data-testid="feature-library-item-title" class="gl-font-bold">
        {{ item.title }}
      </span>
      <p data-testid="feature-library-item-description" class="gl-mb-1 gl-text-sm">
        {{ item.description }}
      </p>
      <gl-badge data-testid="feature-library-item-tier" size="sm" variant="neutral">
        {{ tierLabel }}
      </gl-badge>
    </div>
    <gl-button
      category="tertiary"
      :icon="pinIconName"
      :aria-label="pinAriaLabel"
      :aria-pressed="pinned"
      :selected="pinned"
      @click="onPinClick"
    />
  </li>
</template>
