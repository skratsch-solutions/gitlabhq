<script>
import GlqlResolver from '~/glql/components/common/resolver.vue';

export default {
  name: 'GlqlVisualization',
  components: {
    GlqlResolver,
  },
  props: {
    data: {
      type: String,
      required: false,
      default: '',
    },
  },
};
</script>

<template>
  <glql-resolver :glql-query="data" tracking-event-name="render_analytics_dashboard_glql_panel" />
</template>
