<script>
import { GlModal, GlSearchBoxByType, GlScrollableTabs, GlTab, GlEmptyState } from '@gitlab/ui';
import { debounce } from 'lodash-es';
import { InternalEvents } from '~/tracking';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import {
  EVENT_OPEN_FEATURE_LIBRARY_MODAL,
  EVENT_SEARCH_FEATURES_IN_FEATURE_LIBRARY_MODAL,
  EVENT_CLICK_CATEGORY_TAB_IN_FEATURE_LIBRARY_MODAL,
  EVENT_PIN_ITEM_IN_FEATURE_LIBRARY_MODAL,
  EVENT_UNPIN_ITEM_IN_FEATURE_LIBRARY_MODAL,
  EVENT_NAVIGATE_TO_FEATURE_FROM_FEATURE_LIBRARY_MODAL,
} from '../../tracking_constants';
import { ALL_CATEGORY, ALL_CATEGORY_ID, MODAL_ID } from './constants';
import FeatureLibraryItem from './feature_library_item.vue';

const trackingMixin = InternalEvents.mixin();

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
  mixins: [trackingMixin],
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
          link: item.link,
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
  created() {
    this.debouncedTrackSearch = debounce(
      () => this.trackEvent(EVENT_SEARCH_FEATURES_IN_FEATURE_LIBRARY_MODAL),
      DEFAULT_DEBOUNCE_AND_THROTTLE_MS,
    );
  },
  beforeUnmount() {
    this.debouncedTrackSearch.cancel();
  },
  methods: {
    isPinned(itemId) {
      return this.currentPinnedIds.includes(itemId);
    },
    onShown() {
      this.trackEvent(EVENT_OPEN_FEATURE_LIBRARY_MODAL);
    },
    onTabClick(categoryId) {
      this.activeCategoryId = categoryId;
      this.trackEvent(EVENT_CLICK_CATEGORY_TAB_IN_FEATURE_LIBRARY_MODAL, {
        label: categoryId,
      });
    },
    onSearchInput(value) {
      this.searchQuery = value;
      if (value.trim()) {
        this.debouncedTrackSearch();
      }
    },
    onPinToggle(itemId, nextState, title) {
      this.$emit('pin-toggle', itemId, nextState, title);
      const event = nextState
        ? EVENT_PIN_ITEM_IN_FEATURE_LIBRARY_MODAL
        : EVENT_UNPIN_ITEM_IN_FEATURE_LIBRARY_MODAL;
      this.trackEvent(event, { label: itemId });
    },
    onNavigate(itemId) {
      this.trackEvent(EVENT_NAVIGATE_TO_FEATURE_FROM_FEATURE_LIBRARY_MODAL, {
        label: itemId,
      });
    },
    onHidden() {
      this.debouncedTrackSearch.cancel();
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
    modal-class="feature-library-modal gl-backdrop-blur-sm gl-px-2 sm:gl-px-5"
    body-class="gl-flex gl-flex-col"
    size="lg"
    scrollable
    hide-header
    hide-footer
    @shown="onShown"
    @hidden="onHidden"
  >
    <gl-search-box-by-type
      :value="searchQuery"
      :placeholder="s__('FeatureLibrary|Search GitLab features')"
      class="gl-mb-4 gl-mt-3"
      @input="onSearchInput"
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
    <div
      data-testid="feature-library-scroll-area"
      class="feature-library-scroll-area gl-min-h-0 gl-grow gl-overflow-y-auto"
    >
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
          @navigate="onNavigate"
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
