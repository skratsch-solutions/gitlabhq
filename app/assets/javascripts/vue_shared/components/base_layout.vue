<script>
import { GlLoadingIcon } from '@gitlab/ui';
import PageHeading from './page_heading.vue';

export default {
  name: 'BaseLayout',
  components: {
    GlLoadingIcon,
    PageHeading,
  },
  props: {
    heading: {
      type: String,
      required: false,
      default: null,
    },
    headingTag: {
      type: String,
      required: false,
      default: null,
      validator: (value) => value === null || ['h1', 'h2'].includes(value),
    },
    description: {
      type: String,
      required: false,
      default: null,
    },
    pageHeadingSrOnly: {
      type: Boolean,
      required: false,
      default: false,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <div class="gl-base-layout">
    <slot name="before"></slot>
    <page-heading
      :heading="heading"
      :heading-tag="headingTag"
      :class="{ 'gl-sr-only': pageHeadingSrOnly }"
    >
      <template v-if="$scopedSlots['heading-wrapper']" #heading-wrapper>
        <slot name="heading-wrapper"></slot>
      </template>
      <template v-if="$scopedSlots.heading" #heading>
        <slot name="heading"></slot>
      </template>
      <template v-if="$scopedSlots.actions" #actions>
        <slot name="actions"></slot>
      </template>
      <template v-if="$scopedSlots.description || description" #description>
        <slot v-if="$scopedSlots.description" name="description"></slot>
        <template v-else>{{ description }}</template>
      </template>
    </page-heading>
    <div
      v-if="$scopedSlots.alerts"
      class="gl-base-layout-alerts js-base-layout-alerts"
      data-testid="base-layout-alerts"
    >
      <slot name="alerts"></slot>
    </div>
    <div data-testid="base-layout-content">
      <slot v-if="loading" name="loading">
        <gl-loading-icon class="gl-base-layout-loading-icon" size="lg" />
      </slot>
      <slot v-else name="content">
        <slot></slot>
      </slot>
    </div>
  </div>
</template>
