import getBoardNamespaceStatusesQuery from 'ee_else_ce/work_items/board/graphql/get_namespace_statuses.query.graphql';
import { findStatusWidget } from '~/work_items/utils';

// Grouping strategy for the `status` attribute.
/** @type {import('./index').GroupingStrategy} */
export const statusStrategy = {
  property: 'status',

  // CE resolves to a stub returning no statuses, so columns only appear under EE.
  valuesQuery: getBoardNamespaceStatusesQuery,

  extractValues(data) {
    return data?.namespace?.rootNamespace?.statuses?.nodes ?? [];
  },

  columnFilter(value) {
    return { status: { name: value.name } };
  },

  moveInput(value) {
    return { statusWidget: { status: value.id } };
  },

  patchCard(node, value) {
    const statusWidget = findStatusWidget(node);
    if (statusWidget) {
      // Leading spread preserves any status fields the column value omits.
      statusWidget.status = { ...statusWidget.status, ...value };
    }
  },

  headerDecoration(value) {
    return value.iconName
      ? { type: 'icon', name: value.iconName, color: value.color }
      : { type: 'none' };
  },
};
