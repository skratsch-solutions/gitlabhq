<script>
import { GlModal, GlSearchBoxByType, GlScrollableTabs, GlTab, GlEmptyState } from '@gitlab/ui';
import { ALL_CATEGORY, ALL_CATEGORY_ID, MODAL_ID } from './constants';
import FeatureLibraryItem from './feature_library_item.vue';

export default {
  name: 'FeatureLibraryModal',
  components: {
    GlModal,
    GlSearchBoxByType,
    GlScrollableTabs,
    GlTab,
    GlEmptyState,
    FeatureLibraryItem,
  },
  modalId: MODAL_ID,
  props: {
    sections: {
      type: Array,
      required: false,
      default: () => [],
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
    // Sections that hold at least one feature-library-enriched item, mapped to category tabs.
    libraryCategories() {
      return [ALL_CATEGORY, ...this.catalogSections.map(({ id, title }) => ({ id, label: title }))];
    },
    catalogSections() {
      return this.sections
        .map((section) => ({
          ...section,
          items: (section.items || []).filter((item) => item.description),
        }))
        .filter((section) => section.items.length > 0);
    },
    catalog() {
      return this.catalogSections.flatMap((section) =>
        section.items.map((item) => ({
          id: item.id,
          title: item.title,
          description: item.description,
          icon: item.library_icon || item.icon,
          tier: item.tier,
          category: section.id,
        })),
      );
    },
    filteredItems() {
      const q = this.searchQuery.trim().toLowerCase();
      return this.catalog.filter((item) => {
        if (this.activeCategoryId !== ALL_CATEGORY_ID && item.category !== this.activeCategoryId) {
          return false;
        }
        if (!q) return true;
        return (
          item.title.toLowerCase().includes(q) || (item.description || '').toLowerCase().includes(q)
        );
      });
    },
    showEmptyState() {
      return this.filteredItems.length === 0;
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
        v-for="cat in libraryCategories"
        :key="cat.id"
        :title="cat.label"
        :active="cat.id === activeCategoryId"
        @click="onTabClick(cat.id)"
      />
    </gl-scrollable-tabs>
    <div data-testid="feature-library-scroll-area" class="gl-min-h-0 gl-grow gl-overflow-y-auto">
      <!-- TODO: render <feature-library-recommended> here once nav items expose a `recommended`
           data point. The component exists but is unrendered: the server-driven catalog has no
           recommended flag yet. -->
      <ul
        v-if="filteredItems.length > 0"
        data-testid="feature-library-grid"
        class="gl-grid gl-list-none gl-grid-cols-1 gl-gap-3 gl-p-0 sm:gl-grid-cols-2 md:gl-grid-cols-3"
      >
        <feature-library-item
          v-for="item in filteredItems"
          :key="item.id"
          :item="item"
          :pinned="isPinned(item.id)"
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
