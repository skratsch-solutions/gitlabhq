import { getMovePositionIds } from '~/work_items/board/utils';

describe('work item board utils', () => {
  describe('getMovePositionIds', () => {
    const nodes = [
      { id: 'gid://gitlab/WorkItem/1' },
      { id: 'gid://gitlab/WorkItem/2' },
      { id: 'gid://gitlab/WorkItem/3' },
    ];

    describe('within the same column', () => {
      it('returns the card at the drop index as moveBeforeId when moving down', () => {
        expect(getMovePositionIds({ nodes, sameColumn: true, oldIndex: 0, newIndex: 2 })).toEqual({
          moveBeforeId: 'gid://gitlab/WorkItem/3',
        });
      });

      it('returns the card at the drop index as moveAfterId when moving up', () => {
        expect(getMovePositionIds({ nodes, sameColumn: true, oldIndex: 2, newIndex: 0 })).toEqual({
          moveAfterId: 'gid://gitlab/WorkItem/1',
        });
      });

      it('returns no ids when dropped in place', () => {
        expect(getMovePositionIds({ nodes, sameColumn: true, oldIndex: 1, newIndex: 1 })).toEqual(
          {},
        );
      });
    });

    describe('across columns', () => {
      it('returns the surrounding cards when dropped between two cards', () => {
        expect(getMovePositionIds({ nodes, sameColumn: false, newIndex: 1 })).toEqual({
          moveBeforeId: 'gid://gitlab/WorkItem/1',
          moveAfterId: 'gid://gitlab/WorkItem/2',
        });
      });

      it('returns only moveAfterId when dropped at the start', () => {
        expect(getMovePositionIds({ nodes, sameColumn: false, newIndex: 0 })).toEqual({
          moveBeforeId: undefined,
          moveAfterId: 'gid://gitlab/WorkItem/1',
        });
      });

      it('returns only moveBeforeId when dropped at the end', () => {
        expect(getMovePositionIds({ nodes, sameColumn: false, newIndex: nodes.length })).toEqual({
          moveBeforeId: 'gid://gitlab/WorkItem/3',
          moveAfterId: undefined,
        });
      });

      it('returns no ids when the target column is empty', () => {
        expect(getMovePositionIds({ nodes: [], sameColumn: false, newIndex: 0 })).toEqual({
          moveBeforeId: undefined,
          moveAfterId: undefined,
        });
      });
    });
  });
});
