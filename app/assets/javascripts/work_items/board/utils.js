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

// The count-only query uses a different query document so it always has its own cache
// entry. `firstPageSize` is stripped because the count query doesn't accept it, and
// board_view keys its drag-and-drop count updates off these same variables.
export const boardColumnCountVariables = (params) => {
  const { firstPageSize, ...countVariables } = boardColumnQueryVariables(params);
  return countVariables;
};

// Relative-position arguments for a card move, derived from the target column's
// pre-move order (`nodes`). For a same-column move the source and target lists
// are identical. Mirrors the neighbour logic in boards/components/board_list.vue
// so both boards order items the same way. IDs are full GraphQL global IDs —
// the workItemUpdate mutation parses the gid server-side.
export const getMovePositionIds = ({ nodes = [], sameColumn, oldIndex, newIndex }) => {
  const idAt = (index) => nodes[index]?.id;

  if (sameColumn) {
    // Moving down: the card at the drop index ends up before the moved card.
    if (newIndex > oldIndex) {
      return { moveBeforeId: idAt(newIndex) };
    }
    // Moving up: the card at the drop index ends up after the moved card.
    if (newIndex < oldIndex) {
      return { moveAfterId: idAt(newIndex) };
    }
    // Dropped in place — no reordering.
    return {};
  }

  // Cross-column: the moved card is inserted at newIndex, so its neighbours are
  // the cards currently surrounding that slot.
  return { moveBeforeId: idAt(newIndex - 1), moveAfterId: idAt(newIndex) };
};
