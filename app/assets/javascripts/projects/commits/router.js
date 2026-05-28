import Vue from 'vue';
import VueRouter from 'vue-router';
import CommitListApp from '~/projects/commits/components/commit_list_app.vue';

Vue.use(VueRouter);

export const createRouter = (basePath, escapedRef) => {
  const router = new VueRouter({
    mode: 'history',
    base: basePath,
    routes: [
      {
        // Support without decoding as well just in case the ref doesn't need to be decoded
        path: `/${escapedRef}/:path*`,
        name: 'commitsPath',
        component: CommitListApp,
      },
      {
        // Sometimes the ref needs decoding depending on how the backend sends it to us
        path: `/${decodeURI(escapedRef)}/:path*`,
        name: 'commitsPathDecoded',
        component: CommitListApp,
      },
      {
        // Wildcard fallback so every URL still matches a route after a ref
        // switch (the specific routes above are hardcoded to the initial ref).
        // params.path may include ref segments for refs containing slashes,
        // so the component must not rely on it for the file path — the ref
        // change handler preserves currentPath independently.
        path: '/:ref/:path*',
        name: 'commitsAnyRef',
        component: CommitListApp,
      },
    ],
  });

  return router;
};
