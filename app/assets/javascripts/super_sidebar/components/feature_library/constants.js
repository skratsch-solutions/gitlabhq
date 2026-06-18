import { __ } from '~/locale';

export const MODAL_ID = 'feature-library-modal';

export const TIERS = Object.freeze({
  FREE: 'free',
  PREMIUM: 'premium',
  ULTIMATE: 'ultimate',
  ADD_ON: 'add_on',
});

export const BADGES = Object.freeze({
  BETA: 'beta',
});

export const CATEGORIES = Object.freeze([
  { id: 'all', label: __('All') },
  { id: 'plan', label: __('Plan') },
  { id: 'code', label: __('Code') },
  { id: 'build', label: __('Build') },
  { id: 'secure', label: __('Secure') },
  { id: 'deploy', label: __('Deploy') },
  { id: 'operations', label: __('Operations') },
  { id: 'monitor', label: __('Monitor') },
  { id: 'analyze', label: __('Analyze') },
  { id: 'automate', label: __('Automate') },
  { id: 'manage', label: __('Manage') },
]);

export const ALL_CATEGORY_ID = 'all';
