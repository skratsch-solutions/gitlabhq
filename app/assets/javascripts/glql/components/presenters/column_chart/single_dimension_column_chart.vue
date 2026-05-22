<script>
import { GlColumnChart, GlStackedColumnChart } from '@gitlab/ui/src/charts';
import { stackedPresentationOptions } from '@gitlab/ui/src/utils/constants';
import {
  buildSeries,
  buildStackedByMetric,
  tooltipContentFromParams,
} from '../../../utils/chart_data';
import { formatterFor, axisFormatterFor, unitFor } from '../../../utils/value_format';
import FormattedTooltipContent from './formatted_tooltip_content.vue';

export default {
  name: 'SingleDimensionColumnChart',
  components: { GlColumnChart, GlStackedColumnChart, FormattedTooltipContent },
  props: {
    data: {
      required: true,
      type: Object,
    },
    dimension: {
      required: true,
      type: Object,
    },
    metrics: {
      required: true,
      type: Array,
    },
    stacked: {
      required: false,
      type: Boolean,
      default: false,
    },
  },
  computed: {
    // GlColumnChart renders 1 metric (single series) or 2 metrics on a dual y-axis.
    // 3+ metrics, or stacking, go through GlStackedColumnChart on a single axis.
    useSingleAxisChart() {
      return this.stacked || this.metrics.length > 2;
    },
    primaryBars() {
      return buildSeries(this.data.nodes, this.dimension, this.metrics[0]);
    },
    secondaryBars() {
      return buildSeries(this.data.nodes, this.dimension, this.metrics[1]);
    },
    multiMetricData() {
      return buildStackedByMetric(this.data.nodes, this.dimension, this.metrics);
    },
    // Keyed by `metric.label` because ECharts identifies series by `seriesName`
    // (= `metric.label`). Two metrics with the same label would collide — labels
    // come from upstream metric definitions and are expected to be unique.
    formatterByLabel() {
      return Object.fromEntries(this.metrics.map((m) => [m.label, formatterFor(m.key)]));
    },
    sharedAxisFormatter() {
      // null when metrics span more than one unit. Fallback to Echart default formatter
      const units = this.metrics.map((m) => unitFor(m.key));
      if (units[0] == null || !units.every((u) => u === units[0])) return null;
      return axisFormatterFor(this.metrics[0]?.key);
    },
    chartOptions() {
      // Dual-axis: per-metric formatter on each axis. ECharts deep-merges yAxis
      // by index when given an array.
      if (this.metrics.length === 2 && !this.useSingleAxisChart) {
        return {
          yAxis: [
            { axisLabel: { formatter: axisFormatterFor(this.metrics[0]?.key) } },
            { axisLabel: { formatter: axisFormatterFor(this.metrics[1]?.key) } },
          ],
        };
      }
      // Stacked single-axis: apply the formatter only when all metrics share a
      // unit. GlStackedColumnChart declares yAxis as an array, so we have to
      // pass an array for the merge to apply.
      if (this.useSingleAxisChart) {
        return this.sharedAxisFormatter
          ? { yAxis: [{ axisLabel: { formatter: this.sharedAxisFormatter } }] }
          : {};
      }
      return { yAxis: { axisLabel: { formatter: axisFormatterFor(this.metrics[0]?.key) } } };
    },
    presentation() {
      return this.stacked ? stackedPresentationOptions.stacked : stackedPresentationOptions.tiled;
    },
    yAxisTitle() {
      if (this.useSingleAxisChart) return '';
      return this.metrics[0]?.label ?? '';
    },
  },
  methods: {
    // Unknown labels fall back to identity rather than the primary metric's
    // formatter — otherwise a mixed-unit chart would mis-format e.g. a count
    // value as a percentage.
    formatValueByLabel(label, value) {
      return (this.formatterByLabel[label] ?? formatterFor(null))(value);
    },
    contentFromParams: tooltipContentFromParams,
  },
};
</script>

<template>
  <gl-stacked-column-chart
    v-if="useSingleAxisChart"
    x-axis-type="category"
    :x-axis-title="dimension.label"
    :y-axis-title="yAxisTitle"
    :group-by="multiMetricData.groups"
    :bars="multiMetricData.bars"
    :option="chartOptions"
    :presentation="presentation"
    :include-legend-avg-max="false"
  >
    <template #tooltip-content="{ params }">
      <formatted-tooltip-content
        :content="contentFromParams(params)"
        :format-value="formatValueByLabel"
      />
    </template>
  </gl-stacked-column-chart>
  <gl-column-chart
    v-else
    :bars="primaryBars"
    :option="chartOptions"
    x-axis-type="category"
    :x-axis-title="dimension.label"
    :y-axis-title="yAxisTitle"
    :secondary-data="secondaryBars"
    :secondary-data-title="metrics[1]?.label"
  >
    <template #tooltip-content="{ params }">
      <formatted-tooltip-content
        :content="contentFromParams(params)"
        :format-value="formatValueByLabel"
      />
    </template>
  </gl-column-chart>
</template>
