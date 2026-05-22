import {
  formatCount,
  formatCountCompact,
  formatRate,
  formatDuration,
  formatDurationCompact,
  formatterFor,
  axisFormatterFor,
  unitFor,
} from '~/glql/utils/value_format';

describe('formatCount', () => {
  it.each`
    value      | expected
    ${0}       | ${'0'}
    ${42}      | ${'42'}
    ${1000}    | ${'1,000'}
    ${1234567} | ${'1,234,567'}
  `('formats $value as $expected', ({ value, expected }) => {
    expect(formatCount(value)).toBe(expected);
  });
});

describe('formatCountCompact', () => {
  it.each`
    value      | expected
    ${0}       | ${'0'}
    ${42}      | ${'42'}
    ${999}     | ${'999'}
    ${1000}    | ${'1K'}
    ${1500}    | ${'1.5K'}
    ${1234}    | ${'1.2K'}
    ${1234567} | ${'1.2M'}
    ${2500000} | ${'2.5M'}
  `('formats $value as $expected', ({ value, expected }) => {
    expect(formatCountCompact(value)).toBe(expected);
  });
});

describe('formatRate', () => {
  it.each`
    value     | expected
    ${0}      | ${'0%'}
    ${1}      | ${'100%'}
    ${0.5}    | ${'50%'}
    ${0.425}  | ${'42.5%'}
    ${0.001}  | ${'0.1%'}
    ${0.9875} | ${'98.8%'}
  `('formats $value as $expected', ({ value, expected }) => {
    expect(formatRate(value)).toBe(expected);
  });
});

describe('formatDuration', () => {
  it.each`
    seconds  | expected
    ${0}     | ${'0s'}
    ${30}    | ${'30s'}
    ${60}    | ${'1m'}
    ${90}    | ${'1m 30s'}
    ${3600}  | ${'1h'}
    ${3661}  | ${'1h 1m 1s'}
    ${86400} | ${'1d'}
  `('formats $seconds seconds as $expected', ({ seconds, expected }) => {
    expect(formatDuration(seconds)).toBe(expected);
  });
});

describe('formatDurationCompact', () => {
  it.each`
    seconds  | expected
    ${0}     | ${'0s'}
    ${30}    | ${'30s'}
    ${60}    | ${'1min'}
    ${90}    | ${'1.5min'}
    ${2000}  | ${'33.3min'}
    ${3600}  | ${'1h'}
    ${3661}  | ${'1h'}
    ${10000} | ${'2.8h'}
    ${86400} | ${'1d'}
  `('formats $seconds seconds as $expected', ({ seconds, expected }) => {
    expect(formatDurationCompact(seconds)).toBe(expected);
  });
});

describe('formatterFor', () => {
  it.each`
    fieldKey               | input     | expected
    ${'totalCount'}        | ${1234}   | ${'1,234'}
    ${'usersCount'}        | ${42}     | ${'42'}
    ${'shownCount'}        | ${1801}   | ${'1,801'}
    ${'acceptedCount'}     | ${1}      | ${'1'}
    ${'rejectedCount'}     | ${567}    | ${'567'}
    ${'suggestionSizeSum'} | ${500000} | ${'500,000'}
    ${'acceptanceRate'}    | ${0.75}   | ${'75%'}
    ${'successRate'}       | ${0.95}   | ${'95%'}
    ${'failureRate'}       | ${0.04}   | ${'4%'}
    ${'canceledRate'}      | ${0.01}   | ${'1%'}
    ${'skippedRate'}       | ${0.001}  | ${'0.1%'}
    ${'duration'}          | ${3600}   | ${'1h'}
    ${'queuedDuration'}    | ${90}     | ${'1m 30s'}
    ${'durationQuantile'}  | ${3661}   | ${'1h 1m 1s'}
  `(
    'returns a formatter for $fieldKey that maps $input to $expected',
    ({ fieldKey, input, expected }) => {
      expect(formatterFor(fieldKey)(input)).toBe(expected);
    },
  );

  it('returns an identity-string formatter for unknown field keys', () => {
    const formatter = formatterFor('unknownField');
    expect(formatter(123)).toBe('123');
    expect(formatter('hello')).toBe('hello');
  });

  it('renders nullish values as an empty string for unknown field keys', () => {
    const formatter = formatterFor('unknownField');
    expect(formatter(null)).toBe('');
    expect(formatter(undefined)).toBe('');
  });
});

describe('axisFormatterFor', () => {
  it.each`
    fieldKey               | input      | expected
    ${'totalCount'}        | ${2500000} | ${'2.5M'}
    ${'usersCount'}        | ${1500}    | ${'1.5K'}
    ${'shownCount'}        | ${1234}    | ${'1.2K'}
    ${'acceptedCount'}     | ${1234567} | ${'1.2M'}
    ${'rejectedCount'}     | ${999}     | ${'999'}
    ${'suggestionSizeSum'} | ${500000}  | ${'500K'}
  `('uses compact notation for count $fieldKey', ({ fieldKey, input, expected }) => {
    expect(axisFormatterFor(fieldKey)(input)).toBe(expected);
  });

  it.each`
    fieldKey              | input    | expected
    ${'successRate'}      | ${0.819} | ${'81.9%'}
    ${'durationQuantile'} | ${10000} | ${'2.8h'}
    ${'duration'}         | ${3661}  | ${'1h'}
    ${'queuedDuration'}   | ${90}    | ${'1.5min'}
  `('uses the unit-specific axis formatter for $fieldKey', ({ fieldKey, input, expected }) => {
    expect(axisFormatterFor(fieldKey)(input)).toBe(expected);
  });

  it('falls through to identity for unknown field keys', () => {
    expect(axisFormatterFor('unknownField')(123)).toBe('123');
  });
});

describe('unitFor', () => {
  it.each`
    fieldKey               | expected
    ${'totalCount'}        | ${'count'}
    ${'usersCount'}        | ${'count'}
    ${'suggestionSizeSum'} | ${'count'}
    ${'acceptanceRate'}    | ${'rate'}
    ${'failureRate'}       | ${'rate'}
    ${'duration'}          | ${'duration'}
    ${'durationQuantile'}  | ${'duration'}
  `('maps $fieldKey to unit $expected', ({ fieldKey, expected }) => {
    expect(unitFor(fieldKey)).toBe(expected);
  });

  it('returns null for unknown field keys', () => {
    expect(unitFor('unknownField')).toBeNull();
  });
});
