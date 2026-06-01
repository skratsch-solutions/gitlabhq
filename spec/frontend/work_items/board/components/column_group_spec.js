import { GlLoadingIcon } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import getBoardWorkItemsQuery from 'ee_else_ce/work_items/board/graphql/get_board_work_items.query.graphql';
import getWorkItemsRestQuery from 'ee_else_ce/work_items/list/graphql/get_work_items_rest.query.graphql';
import ColumnGroup from '~/work_items/board/components/column_group.vue';
import ColumnHeader from '~/work_items/board/components/column_header.vue';
import WorkItemCard from '~/work_items/board/components/work_item_card.vue';
import { mockStatus, buildWorkItemNode, buildBoardWorkItemsResponse } from '../mock_data';

jest.mock('~/sentry/sentry_browser_wrapper');

Vue.use(VueApollo);

describe('ColumnGroup', () => {
  let wrapper;

  const boardQueryHandler = jest.fn();
  const restQueryHandler = jest.fn();

  const findColumnHeader = () => wrapper.findComponent(ColumnHeader);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findWorkItemCards = () => wrapper.findAllComponents(WorkItemCard);
  const findEmptyState = () => wrapper.findByTestId('empty-state');
  const findErrorState = () => wrapper.findByTestId('error-state');

  const baseQueryVariables = {
    state: 'opened',
    sort: 'CREATED_DESC',
  };

  const createComponent = ({ props = {}, glFeatures = {} } = {}) => {
    const apolloProvider = createMockApollo([
      [getBoardWorkItemsQuery, boardQueryHandler],
      [getWorkItemsRestQuery, restQueryHandler],
    ]);

    wrapper = shallowMountExtended(ColumnGroup, {
      apolloProvider,
      provide: {
        glFeatures,
      },
      propsData: {
        value: mockStatus,
        groupProperty: 'status',
        rootPageFullPath: 'full/path',
        baseQueryVariables,
        ...props,
      },
    });
  };

  beforeEach(() => {
    boardQueryHandler.mockResolvedValue(buildBoardWorkItemsResponse([buildWorkItemNode(1)]));
    restQueryHandler.mockResolvedValue(buildBoardWorkItemsResponse([buildWorkItemNode(1)]));
  });

  describe('column header', () => {
    it('passes the value, groupProperty, and item count to ColumnHeader', async () => {
      createComponent();
      await waitForPromises();

      expect(findColumnHeader().props('value')).toEqual(mockStatus);
      expect(findColumnHeader().props('groupProperty')).toBe('status');
      expect(findColumnHeader().props('count')).toBe(1);
    });
  });

  describe('while loading', () => {
    it('renders a loading icon and no cards or empty state', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findWorkItemCards()).toHaveLength(0);
      expect(findEmptyState().exists()).toBe(false);
    });
  });

  describe('when no work items are returned', () => {
    beforeEach(async () => {
      boardQueryHandler.mockResolvedValue(buildBoardWorkItemsResponse([]));
      createComponent();
      await waitForPromises();
    });

    it('hides the loading icon', () => {
      expect(findLoadingIcon().exists()).toBe(false);
    });

    it('renders the empty state message', () => {
      expect(findEmptyState().text()).toBe('No items');
    });

    it('does not render any work item cards', () => {
      expect(findWorkItemCards()).toHaveLength(0);
    });
  });

  describe('when work items are returned', () => {
    const nodes = [buildWorkItemNode(1), buildWorkItemNode(2), buildWorkItemNode(3)];

    beforeEach(async () => {
      boardQueryHandler.mockResolvedValue(buildBoardWorkItemsResponse(nodes));
      createComponent();
      await waitForPromises();
    });

    it('renders one WorkItemCard per node', () => {
      expect(findWorkItemCards()).toHaveLength(nodes.length);
    });

    it('passes each work item to its card', () => {
      const renderedItems = findWorkItemCards().wrappers.map((card) => card.props('item'));
      expect(renderedItems).toEqual(nodes);
    });

    it('does not render the empty state or loading icon', () => {
      expect(findEmptyState().exists()).toBe(false);
      expect(findLoadingIcon().exists()).toBe(false);
    });
  });

  describe('query variables', () => {
    it('passes firstPageSize, fullPath, base variables, and grouped value', async () => {
      createComponent();
      await waitForPromises();

      expect(boardQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          firstPageSize: 20,
          fullPath: 'full/path',
          ...baseQueryVariables,
          status: { name: mockStatus.name },
        }),
      );
    });

    it('uses groupProperty as the variable key for the grouped value', async () => {
      createComponent({ props: { groupProperty: 'customGroup' } });
      await waitForPromises();

      expect(boardQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          customGroup: { name: mockStatus.name },
        }),
      );
    });

    it('overrides base variables that collide with the grouped value key', async () => {
      createComponent({
        props: {
          baseQueryVariables: { ...baseQueryVariables, status: { name: 'should-be-overridden' } },
        },
      });
      await waitForPromises();

      expect(boardQueryHandler).toHaveBeenCalledWith(
        expect.objectContaining({
          status: { name: mockStatus.name },
        }),
      );
    });
  });

  describe('query selection by feature flags', () => {
    it('uses getWorkItemsRestQuery when both workItemRestApiFrontendUsers and workItemRestApi are enabled', async () => {
      createComponent({
        glFeatures: { workItemRestApiFrontendUsers: true, workItemRestApi: true },
      });
      await waitForPromises();

      expect(restQueryHandler).toHaveBeenCalled();
      expect(boardQueryHandler).not.toHaveBeenCalled();
    });

    it.each([
      { workItemRestApiFrontendUsers: true, workItemRestApi: false },
      { workItemRestApiFrontendUsers: false, workItemRestApi: true },
      { workItemRestApiFrontendUsers: false, workItemRestApi: false },
    ])('uses getBoardWorkItemsQuery when flags are %o', async (glFeatures) => {
      createComponent({ glFeatures });
      await waitForPromises();

      expect(boardQueryHandler).toHaveBeenCalled();
      expect(restQueryHandler).not.toHaveBeenCalled();
    });
  });

  describe('when the work items query errors', () => {
    const queryError = new Error('GraphQL failure');

    beforeEach(async () => {
      boardQueryHandler.mockRejectedValue(queryError);
      createComponent();
      await waitForPromises();
    });

    it('renders the error message', () => {
      expect(findErrorState().text()).toBe(
        'An error occurred while fetching work items for this column.',
      );
    });

    it('captures the error in Sentry', () => {
      expect(Sentry.captureException).toHaveBeenCalledWith(queryError);
    });

    it('does not render the loading icon, empty state, or work item cards', () => {
      expect(findLoadingIcon().exists()).toBe(false);
      expect(findEmptyState().exists()).toBe(false);
      expect(findWorkItemCards()).toHaveLength(0);
    });

    it('clears the error when the query subsequently succeeds', async () => {
      boardQueryHandler.mockResolvedValue(buildBoardWorkItemsResponse([buildWorkItemNode(1)]));
      wrapper.vm.$apollo.queries.workItems.refetch();
      await waitForPromises();

      expect(findErrorState().exists()).toBe(false);
      expect(findWorkItemCards()).toHaveLength(1);
    });
  });
});
