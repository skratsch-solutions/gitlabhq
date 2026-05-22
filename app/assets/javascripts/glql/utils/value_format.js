import { formatNumber } from '~/locale';
import {
  timeIntervalInWords,
  humanizeTimeInterval,
} from '~/lib/utils/datetime/date_format_utility';

export const formatCount = (value) => formatNumber(value);

// Compact notation for chart axes where horizontal space is tight: 2,500,000 → 2.5M.
// Cells and tooltips keep the full-digit `formatCount` for precision.
export const formatCountCompact = (value) =>
  formatNumber(value, { notation: 'compact', maximumFractionDigits: 1 });

export const formatRate = (value) => {
  const percentage = value * 100;
  const rounded = percentage % 1 === 0 ? percentage.toFixed(0) : percentage.toFixed(1);
  return `${rounded}%`;
};

export const formatDuration = (seconds) => timeIntervalInWords(seconds, { abbreviated: true });

// Compact notation for chart axes: keeps the largest applicable unit only
// (`1h 27m 32s` → `1.5h`). Cells and tooltips keep the full-digit `formatDuration`.
export const formatDurationCompact = (seconds) =>
  humanizeTimeInterval(seconds, { abbreviated: true });

const rawString = (value) => (value == null ? '' : String(value));

// Each unit owns its cell and axis formatters. Rates render the same in both
// contexts; counts and durations get a compact variant on the axis.
const UNITS = {
  count: { cell: formatCount, axis: formatCountCompact },
  rate: { cell: formatRate, axis: formatRate },
  duration: { cell: formatDuration, axis: formatDurationCompact },
};

const unitByFieldKey = {
  acceptanceRate: 'rate',
  successRate: 'rate',
  failureRate: 'rate',
  canceledRate: 'rate',
  skippedRate: 'rate',
  acceptedCount: 'count',
  rejectedCount: 'count',
  shownCount: 'count',
  totalCount: 'count',
  usersCount: 'count',
  suggestionSizeSum: 'count',
  duration: 'duration',
  queuedDuration: 'duration',
  durationQuantile: 'duration',
};

export const unitFor = (fieldKey) => unitByFieldKey[fieldKey] ?? null;

export const formatterFor = (fieldKey) => UNITS[unitFor(fieldKey)]?.cell ?? rawString;

export const axisFormatterFor = (fieldKey) => UNITS[unitFor(fieldKey)]?.axis ?? rawString;
