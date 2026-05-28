// No EE-only visualizations are available in FOSS yet.
// EE consumers resolve this same module path through `ee_else_ce`
// to the EE barrel, which exports the full registry.
export default {
  LineChart: () =>
    import('~/analytics/analytics_dashboards/components/visualizations/line_chart.vue'),
  DataTable: () =>
    import('~/analytics/analytics_dashboards/components/visualizations/data_table/data_table.vue'),
};
