<script>
import { normalizeRender } from '~/lib/utils/vue3compat/normalize_render';

export default normalizeRender({
  name: 'StrategiesDefault',
  mounted() {
    this.$emit('change', { parameters: {} });
  },
  render() {
    return this.$scopedSlots.default?.();
  },
});
</script>
