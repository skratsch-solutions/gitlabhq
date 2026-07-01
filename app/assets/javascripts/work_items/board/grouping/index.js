import { statusStrategy } from './status_strategy';

/**
 * One column's value: an `id` and `name` plus any attribute-specific fields the
 * strategy's `headerDecoration` reads (e.g. `iconName`, `color` for status).
 *
 * @typedef {Object} GroupingValue
 * @property {string} id
 * @property {string} name
 */

/**
 * How a column header renders its value.
 *
 * @typedef {Object} HeaderDecoration
 * @property {'icon'|'none'} type
 * @property {string} [name]
 * @property {string} [color]
 */

/**
 * A board grouping strategy. The work items board groups work items into columns
 * by an attribute (today only `status`; assignee/label/milestone/… in future).
 * Each field isolates one attribute-specific decision, keeping `board_view` and
 * `column_group` attribute-agnostic — so a new attribute is added by writing a
 * strategy and registering it in `STRATEGIES`, with no board-component changes.
 *
 * @typedef {Object} GroupingStrategy
 * @property {string} property - The `groupBy` property it handles, e.g. 'status'.
 * @property {Object} valuesQuery - GraphQL query listing the values that become columns.
 * @property {(data: Object) => GroupingValue[]} extractValues - Pulls the column values from the query result.
 * @property {(value: GroupingValue) => Object} columnFilter - work-items query variables that filter a column, e.g. `{ status: { name } }`.
 * @property {(value: GroupingValue) => Object} moveInput - workItemUpdate input fragment that moves an item into the column, e.g. `{ statusWidget: { status } }`.
 * @property {(node: Object, value: GroupingValue) => void} patchCard - Mutates the cloned card in place so its attribute matches the target column optimistically.
 * @property {(value: GroupingValue) => HeaderDecoration} headerDecoration - How the column header renders the value.
 */

/** @type {Object<string, GroupingStrategy>} */
const STRATEGIES = {
  [statusStrategy.property]: statusStrategy,
};

/**
 * @param {string} property
 * @returns {GroupingStrategy|null} The strategy for the groupBy property, or null when unsupported.
 */
export const groupingStrategyFor = (property) => STRATEGIES[property] ?? null;
