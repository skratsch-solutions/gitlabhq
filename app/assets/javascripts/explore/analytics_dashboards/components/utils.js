import { DATE_RANGE_OPTIONS } from './constants';

export const getDateRangeOption = (optionKey) => DATE_RANGE_OPTIONS[optionKey] || null;

export const dateRangeOptionToFilter = ({ startDate, endDate, key }) => ({
  startDate,
  endDate,
  dateRangeOption: key,
});
