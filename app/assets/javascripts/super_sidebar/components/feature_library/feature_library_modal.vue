<script>
import { GlModal, GlSearchBoxByType, GlScrollableTabs, GlTab, GlEmptyState } from '@gitlab/ui';
import { MOCK_CATALOG } from './mock_catalog';
import { CATEGORIES, ALL_CATEGORY_ID, MODAL_ID } from './constants';
import FeatureLibraryItem from './feature_library_item.vue';
import FeatureLibraryRecommended from './feature_library_recommended.vue';

export default {
  name: 'FeatureLibraryModal',
  components: {
    GlModal,
    GlSearchBoxByType,
    GlScrollableTabs,
    GlTab,
    GlEmptyState,
    FeatureLibraryItem,
    FeatureLibraryRecommended,
  },
  modalId: MODAL_ID,
  categories: CATEGORIES,
  props: {
    panelType: {
      type: String,
      required: true,
    },
    currentPinnedIds: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  emits: ['pin-toggle'],
  data() {
    return {
      searchQuery: '',
      activeCategoryId: ALL_CATEGORY_ID,
    };
  },
  computed: {
    matchesPanel() {
      return MOCK_CATALOG.filter((i) => i.panels.includes(this.panelType));
    },
    filteredItems() {
      const q = this.searchQuery.trim().toLowerCase();
      return this.matchesPanel.filter((item) => {
        if (this.activeCategoryId !== ALL_CATEGORY_ID && item.category !== this.activeCategoryId) {
          return false;
        }
        if (!q) return true;
        return (
          item.title.toLowerCase().includes(q) || (item.description || '').toLowerCase().includes(q)
        );
      });
    },
    recommendedItems() {
      return this.matchesPanel.filter((i) => i.recommended);
    },
    showRecommended() {
      return (
        !this.searchQuery &&
        this.activeCategoryId === ALL_CATEGORY_ID &&
        this.recommendedItems.length > 0
      );
    },
    gridItems() {
      if (this.showRecommended) {
        return this.filteredItems.filter((i) => !i.recommended);
      }
      return this.filteredItems;
    },
    showEmptyState() {
      return this.gridItems.length === 0 && !this.showRecommended;
    },
  },
  methods: {
    isPinned(itemId) {
      return this.currentPinnedIds.includes(itemId);
    },
    onTabClick(categoryId) {
      this.activeCategoryId = categoryId;
    },
    onPinToggle(itemId, nextState, title) {
      this.$emit('pin-toggle', itemId, nextState, title);
    },
    onHidden() {
      this.searchQuery = '';
      this.activeCategoryId = ALL_CATEGORY_ID;
    },
  },
};
</script>

<template>
  <gl-modal
    :modal-id="$options.modalId"
    :aria-label="s__('FeatureLibrary|GitLab features')"
    modal-class="gl-backdrop-blur-sm gl-p-5"
    body-class="gl-flex gl-flex-col"
    size="lg"
    centered
    scrollable
    hide-header
    hide-footer
    @hidden="onHidden"
  >
    <gl-search-box-by-type
      :value="searchQuery"
      :placeholder="s__('FeatureLibrary|Search GitLab features')"
      class="gl-mb-4 gl-mt-3"
      @input="searchQuery = $event"
    />
    <gl-scrollable-tabs>
      <gl-tab
        v-for="cat in $options.categories"
        :key="cat.id"
        :title="cat.label"
        :active="cat.id === activeCategoryId"
        @click="onTabClick(cat.id)"
      />
    </gl-scrollable-tabs>
    <div data-testid="feature-library-scroll-area" class="gl-min-h-0 gl-grow gl-overflow-y-auto">
      <feature-library-recommended
        v-if="showRecommended"
        :items="recommendedItems"
        :pinned-ids="currentPinnedIds"
        @pin-toggle="onPinToggle"
      />
      <ul
        v-if="gridItems.length > 0"
        data-testid="feature-library-grid"
        class="gl-grid gl-list-none gl-grid-cols-1 gl-gap-3 gl-p-0 sm:gl-grid-cols-2 md:gl-grid-cols-3"
      >
        <feature-library-item
          v-for="item in gridItems"
          :key="item.item_id"
          :item="item"
          :pinned="isPinned(item.item_id)"
          @pin-toggle="onPinToggle"
        />
      </ul>
      <gl-empty-state
        v-if="showEmptyState"
        :title="s__('FeatureLibrary|No features match your search')"
        :description="s__('FeatureLibrary|Try a different search term or category.')"
      />
    </div>
  </gl-modal>
</template>
