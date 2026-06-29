import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import { initPipelineCountListener } from './utils';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

/**
 * Used in:
 *  - Project Pipelines List (projects:pipelines)
 *  - Commit details View > Pipelines Tab > Pipelines Table (projects:commit:pipelines)
 *  - Merge request details View > Pipelines Tab > Pipelines Table (projects:merge_requests:show)
 *  - New merge request View > Pipelines Tab > Pipelines Table (projects:merge_requests:creations:new)
 */
export default () => {
  const pipelineTableViewEl = document.querySelector('#commit-pipeline-table-view');

  if (pipelineTableViewEl) {
    // Update MR and Commits tabs
    initPipelineCountListener(pipelineTableViewEl);

    if (pipelineTableViewEl.dataset.disableInitialization === undefined) {
      const table = new Vue({
        name: 'CommitPipelinesTableRoot',
        components: {
          CommitPipelinesTable: () =>
            import('~/commit/pipelines/legacy_pipelines_table_wrapper.vue'),
        },
        apolloProvider,
        render(createElement) {
          return createElement('commit-pipelines-table', {
            props: {
              endpoint: pipelineTableViewEl.dataset.endpoint,
            },
          });
        },
      }).$mount();
      pipelineTableViewEl.appendChild(table.$el);
    }
  }
};
