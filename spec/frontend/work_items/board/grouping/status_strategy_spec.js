import { statusStrategy } from '~/work_items/board/grouping/status_strategy';
import getBoardNamespaceStatusesQuery from 'ee_else_ce/work_items/board/graphql/get_namespace_statuses.query.graphql';

describe('status grouping strategy', () => {
  const value = {
    id: 'gid://gitlab/Status/2',
    name: 'In progress',
    iconName: 'status-running',
    color: '#1f75cb',
    category: 'IN_PROGRESS',
  };

  it('groups by the status property', () => {
    expect(statusStrategy.property).toBe('status');
  });

  it('uses the namespace statuses query for its column values', () => {
    expect(statusStrategy.valuesQuery).toBe(getBoardNamespaceStatusesQuery);
  });

  describe('extractValues', () => {
    it('returns the root namespace status nodes', () => {
      const statuses = [{ id: '1' }, { id: '2' }];
      const data = { namespace: { rootNamespace: { statuses: { nodes: statuses } } } };

      expect(statusStrategy.extractValues(data)).toBe(statuses);
    });

    it('returns an empty array when statuses are absent', () => {
      expect(statusStrategy.extractValues({})).toEqual([]);
      expect(statusStrategy.extractValues(undefined)).toEqual([]);
    });
  });

  describe('columnFilter', () => {
    it('filters the column work items by status name', () => {
      expect(statusStrategy.columnFilter(value)).toEqual({ status: { name: 'In progress' } });
    });
  });

  describe('moveInput', () => {
    it('builds the status widget update input from the value id', () => {
      expect(statusStrategy.moveInput(value)).toEqual({
        statusWidget: { status: 'gid://gitlab/Status/2' },
      });
    });
  });

  describe('patchCard', () => {
    it('refreshes the status widget display fields in place', () => {
      const node = {
        widgets: [
          {
            type: 'STATUS',
            status: { __typename: 'WorkItemStatusCustom', id: 'old', name: 'To do' },
          },
        ],
      };

      statusStrategy.patchCard(node, value);

      expect(node.widgets[0].status).toEqual({
        __typename: 'WorkItemStatusCustom',
        id: 'gid://gitlab/Status/2',
        name: 'In progress',
        iconName: 'status-running',
        color: '#1f75cb',
        category: 'IN_PROGRESS',
      });
    });

    it('does nothing when the node has no status widget', () => {
      const node = { widgets: [] };

      expect(() => statusStrategy.patchCard(node, value)).not.toThrow();
    });
  });

  describe('headerDecoration', () => {
    it('returns an icon decoration when the value has an icon', () => {
      expect(statusStrategy.headerDecoration(value)).toEqual({
        type: 'icon',
        name: 'status-running',
        color: '#1f75cb',
      });
    });

    it('returns no decoration when the value has no icon', () => {
      expect(statusStrategy.headerDecoration({ name: 'No icon' })).toEqual({ type: 'none' });
    });
  });
});
