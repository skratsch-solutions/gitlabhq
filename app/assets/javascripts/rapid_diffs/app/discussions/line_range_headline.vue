<script>
import { GlSprintf } from '@gitlab/ui';
import {
  getStartLineNumber,
  getEndLineNumber,
  getLineClasses,
} from '~/notes/components/multiline_comment_utils';

export default {
  name: 'LineRangeHeadline',
  components: {
    GlSprintf,
  },
  props: {
    lineRange: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    startLineNumber() {
      return getStartLineNumber(this.lineRange);
    },
    endLineNumber() {
      return getEndLineNumber(this.lineRange);
    },
    showMultiLineComment() {
      if (!this.startLineNumber || !this.endLineNumber) return false;

      return this.startLineNumber !== this.endLineNumber;
    },
  },
  methods: {
    getLineClasses,
  },
};
</script>

<template>
  <div v-if="showMultiLineComment" class="gl-flex gl-flex-wrap gl-items-center gl-gap-2">
    <gl-sprintf :message="__('Comment on lines %{startLine} to %{endLine}')">
      <template #startLine>
        <span :class="getLineClasses(startLineNumber)">{{ startLineNumber }}</span>
      </template>
      <template #endLine>
        <span :class="getLineClasses(endLineNumber)">{{ endLineNumber }}</span>
      </template>
    </gl-sprintf>
    <slot></slot>
  </div>
</template>
