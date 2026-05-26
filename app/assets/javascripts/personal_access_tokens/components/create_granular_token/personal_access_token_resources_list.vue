<script>
import {
  GlButton,
  GlIcon,
  GlCollapse,
  GlFormCheckboxGroup,
  GlFormCheckbox,
  GlPopover,
  GlAnimatedChevronRightDownIcon,
} from '@gitlab/ui';
import { xor } from 'lodash-es';
import { groupPermissionsByResourceAndCategory } from '~/personal_access_tokens/utils';

export default {
  name: 'PersonalAccessTokenResourcesList',
  components: {
    GlButton,
    GlIcon,
    GlCollapse,
    GlFormCheckboxGroup,
    GlFormCheckbox,
    GlPopover,
    GlAnimatedChevronRightDownIcon,
  },
  props: {
    value: {
      type: Array,
      required: false,
      default: () => [],
    },
    permissions: {
      type: Array,
      required: false,
      default: () => [],
    },
    scope: {
      type: String,
      required: true,
      validator: (value) => ['namespace', 'user'].includes(value),
    },
    isFiltering: {
      type: Boolean,
      required: true,
    },
  },
  emits: ['input'],
  data() {
    return {
      expanded: [],
    };
  },
  computed: {
    selected: {
      get() {
        return this.value;
      },
      set(newValue) {
        this.$emit('input', newValue);
      },
    },
    resourcesGroupedByCategory() {
      return groupPermissionsByResourceAndCategory(this.permissions);
    },
  },
  methods: {
    toggle(category) {
      this.expanded = xor(this.expanded, [category]);
    },
    isExpanded(category) {
      return this.isFiltering || this.expanded.includes(category);
    },
  },
};
</script>
<template>
  <gl-form-checkbox-group v-model="selected">
    <div v-for="category in resourcesGroupedByCategory" :key="category.key" class="gl-mb-4">
      <gl-button
        category="tertiary"
        class="!gl-border-none"
        :class="{ 'gl-pointer-events-none': isFiltering }"
        button-text-classes="gl-flex gl-gap-3 gl-font-bold gl-text-gray-900"
        :disabled="isFiltering"
        @click="toggle(category.key)"
      >
        <gl-animated-chevron-right-down-icon :is-on="isExpanded(category.key)" />
        {{ category.name }}
      </gl-button>

      <gl-collapse :visible="isExpanded(category.key)">
        <div
          v-for="resource in category.resources"
          :key="resource.key"
          class="gl-flex gl-items-center"
        >
          <gl-form-checkbox :value="resource.key" class="gl-ml-6 gl-mt-4">
            {{ resource.name }}
          </gl-form-checkbox>

          <span v-if="resource.description" class="gl-ml-3 gl-mt-2">
            <gl-icon
              :id="`${scope}-${resource.key}`"
              name="information-o"
              class="gl-cursor-pointer"
            />
            <gl-popover
              :target="`${scope}-${resource.key}`"
              triggers="focus"
              no-fade
              boundary="viewport"
            >
              {{ resource.description }}
            </gl-popover>
          </span>
        </div>
      </gl-collapse>
    </div>
  </gl-form-checkbox-group>
</template>
