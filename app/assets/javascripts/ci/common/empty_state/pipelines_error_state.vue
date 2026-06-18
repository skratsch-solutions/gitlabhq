<script>
import { GlEmptyState } from '@gitlab/ui';
import ERROR_STATE_SVG from '@gitlab/svgs/dist/illustrations/empty-state/empty-job-failed-md.svg?url';

export default {
  name: 'PipelinesErrorState',
  components: {
    GlEmptyState,
  },
  props: {
    title: {
      type: String,
      required: false,
      default: '',
    },
    description: {
      type: String,
      required: false,
      default: '',
    },
  },
  ERROR_STATE_SVG,
};
</script>
<template>
  <gl-empty-state :svg-path="$options.ERROR_STATE_SVG" :title="title" :description="description" />
</template>
