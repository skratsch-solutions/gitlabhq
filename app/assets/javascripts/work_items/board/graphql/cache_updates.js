import produce from 'immer';
import { cloneDeep } from 'lodash-es';
import { findStatusWidget } from '~/work_items/utils';

const getConnection = (data) => data?.namespace?.workItems;

// Deep snapshot of the moved card so it can be reinserted into the target column;
// null when the column or item is absent.
export const readWorkItemFromColumn = ({ cache, query, variables, workItemId }) => {
  const data = cache.readQuery({ query, variables });
  const node = getConnection(data)?.nodes?.find((item) => item.id === workItemId);
  return node ? cloneDeep(node) : null;
};

// No-op on a missing cache entry, so a move still works when a sibling column is unloaded.
export const removeWorkItemFromColumn = ({ cache, query, variables, workItemId }) => {
  cache.updateQuery({ query, variables }, (sourceData) => {
    if (!getConnection(sourceData)) {
      return sourceData;
    }

    return produce(sourceData, (draftData) => {
      const { nodes } = getConnection(draftData);
      const index = nodes.findIndex((item) => item.id === workItemId);
      if (index !== -1) {
        nodes.splice(index, 1);
      }
    });
  });
};

// Inserts at index and patches the status widget so the card badge matches the
// target column during the optimistic window. No-op on a missing cache entry.
export const addWorkItemToColumn = ({ cache, query, variables, workItem, index, status }) => {
  cache.updateQuery({ query, variables }, (sourceData) => {
    if (!getConnection(sourceData)) {
      return sourceData;
    }

    return produce(sourceData, (draftData) => {
      const { nodes } = getConnection(draftData);
      if (nodes.some((item) => item.id === workItem.id)) {
        return;
      }

      const node = cloneDeep(workItem);
      const statusWidget = status && findStatusWidget(node);
      if (statusWidget) {
        // Keep the existing widget/status __typename; only refresh display fields.
        statusWidget.status = {
          ...statusWidget.status,
          id: status.id,
          name: status.name,
          iconName: status.iconName,
          color: status.color,
          category: status.category,
        };
      }

      nodes.splice(index, 0, node);
    });
  });
};
