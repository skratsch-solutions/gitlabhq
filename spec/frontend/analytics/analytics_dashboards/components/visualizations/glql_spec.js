import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GlqlVisualization from '~/analytics/analytics_dashboards/components/visualizations/glql.vue';
import GlqlResolver from '~/glql/components/common/resolver.vue';

describe('GlqlVisualization', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = shallowMountExtended(GlqlVisualization, {
      propsData: props,
    });
  };

  const findResolver = () => wrapper.findComponent(GlqlResolver);

  it('renders the GLQL resolver', () => {
    const glqlQuery = 'type = Issue AND state = opened';

    createWrapper({ data: glqlQuery });

    expect(findResolver().exists()).toBe(true);
    expect(findResolver().props()).toEqual({
      glqlQuery,
      trackingEventName: 'render_analytics_dashboard_glql_panel',
    });
  });
});
