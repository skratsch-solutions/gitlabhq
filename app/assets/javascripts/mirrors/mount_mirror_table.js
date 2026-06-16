import Vue from 'vue';
import MirrorTable from 'ee_else_ce/mirrors/components/mirror_table.vue';

export default function mountMirrorTable() {
  const el = document.getElementById('js-mirror-table');
  if (!el) return null;

  const { mirrors, projectId, settingsEnabled, repositoryMirrorsAvailable, pullMirror } =
    el.dataset;

  return new Vue({
    el,
    name: 'MirrorTableRoot',
    provide: {
      projectId: Number(projectId),
      settingsEnabled: settingsEnabled === 'true',
      repositoryMirrorsAvailable: repositoryMirrorsAvailable === 'true',
    },
    render(h) {
      return h(MirrorTable, {
        props: {
          initialMirrors: JSON.parse(mirrors),
          initialPullMirror: pullMirror ? JSON.parse(pullMirror) : null,
        },
      });
    },
  });
}
