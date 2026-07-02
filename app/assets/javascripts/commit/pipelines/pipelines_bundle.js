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
 *  - Commit details View > Pipelines Tab > Pipelines Table (projects:commit:pipelines)
 */
export default () => {
  const pipelineTableViewEl = document.querySelector('#commit-pipeline-table-view');

  if (pipelineTableViewEl) {
    // Update MR and Commits tabs
    initPipelineCountListener(pipelineTableViewEl);

    const table = new Vue({
      name: 'CommitPipelinesTableRoot',
      components: {
        CommitPipelinesTable: () => import('~/commit/pipelines/legacy_pipelines_table_wrapper.vue'),
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
};
