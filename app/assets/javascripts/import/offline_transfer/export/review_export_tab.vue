<script>
import { GlPagination, GlSprintf } from '@gitlab/ui';
import { n__ } from '~/locale';
import GroupRow from '~/import/offline_transfer/components/group_row.vue';

export default {
  name: 'ReviewExportTab',
  components: {
    GroupRow,
    GlPagination,
    GlSprintf,
  },
  props: {
    selectedGroups: {
      type: Array,
      required: true,
    },
    bucketName: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      currentPage: 1,
    };
  },
  computed: {
    reviewText() {
      return n__(
        'OfflineTransferExport|%{count} group will be exported to %{bucket}. Select %{boldStart}Start export%{boldEnd} to confirm.',
        'OfflineTransferExport|%{count} groups will be exported to %{bucket}. Select %{boldStart}Start export%{boldEnd} to confirm.',
        this.groupCount,
      );
    },
    groupCount() {
      return this.selectedGroups.length;
    },
    pageGroups() {
      const start = (this.currentPage - 1) * this.$options.PAGE_SIZE;
      return this.selectedGroups.slice(start, start + this.$options.PAGE_SIZE);
    },
    showPagination() {
      return this.selectedGroups.length > this.$options.PAGE_SIZE;
    },
  },
  watch: {
    selectedGroups() {
      this.currentPage = 1;
    },
  },
  PAGE_SIZE: 10,
};
</script>

<template>
  <div>
    <p class="gl-leading-24" data-testid="review-text">
      <gl-sprintf :message="reviewText">
        <template #count>{{ groupCount }}</template>
        <template #bucket
          ><strong>{{ bucketName }}</strong></template
        >
        <template #bold="{ content }"
          ><strong>{{ content }}</strong></template
        >
      </gl-sprintf>
    </p>
    <ul class="gl-mb-0 gl-list-none gl-p-0">
      <group-row
        v-for="group in pageGroups"
        :key="group.id"
        :name="group.fullName"
        :description="group.description"
        :avatar-url="group.avatarUrl"
      />
    </ul>
    <gl-pagination
      v-if="showPagination"
      v-model="currentPage"
      :per-page="$options.PAGE_SIZE"
      :total-items="groupCount"
      align="center"
    />
  </div>
</template>
