import getBoardWorkItemsQuery from 'ee_else_ce/work_items/board/graphql/get_board_work_items.query.graphql';
import getWorkItemsRestQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_rest.query.graphql';
import { DEFAULT_PAGE_SIZE_BOARD_COLUMN } from '~/work_items/constants';

// Board columns and the drag-and-drop cache updates must use the exact same
// query so they share a single Apollo cache entry.
export const boardColumnQuery = (glFeatures) =>
  glFeatures.workItemRestApiFrontendUsers &&
  (glFeatures.workItemRestApiIndex || glFeatures.workItemRestApi)
    ? getWorkItemsRestQuery
    : getBoardWorkItemsQuery;

// The initial (non-paginated) query variables — the cache key `fetchMore` merges
// pages into, which the drag-and-drop cache updates must match exactly.
export const boardColumnQueryVariables = ({
  rootPageFullPath,
  baseQueryVariables,
  groupProperty,
  value,
}) => ({
  fullPath: rootPageFullPath,
  ...baseQueryVariables,
  firstPageSize: DEFAULT_PAGE_SIZE_BOARD_COLUMN,
  [groupProperty]: { name: value.name }, // must be last to override base
});
