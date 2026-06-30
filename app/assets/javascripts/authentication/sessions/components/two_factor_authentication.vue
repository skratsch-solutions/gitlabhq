<script>
import RecoveryCode from './recovery_code.vue';
import TotpCode from './totp_code.vue';

/**
 * @typedef {'recovery'|'totp'} Method
 */

export default {
  name: 'TwoFactorAuthentication',
  components: {
    RecoveryCode,
    TotpCode,
  },
  props: {
    path: {
      type: String,
      required: true,
    },
    adminMode: {
      type: Boolean,
      required: false,
      default: false,
    },
    activeMethod: {
      type: String,
      required: false,
      default: '',
    },
    rememberMe: {
      type: String,
      required: true,
    },
    rememberMeEnabled: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      /** @type {Method} */
      method: this.activeMethod || 'totp',
    };
  },
  methods: {
    /**
     * @param {Method} method
     */
    isMethod(method) {
      return this.method === method;
    },
    /**
     * @param {Method} method
     */
    setMethod(method) {
      this.method = method;
    },
  },
};
</script>

<template>
  <div>
    <totp-code
      v-if="isMethod('totp')"
      :path="path"
      :remember-me="rememberMe"
      :remember-me-enabled="rememberMeEnabled"
      @switch-method="setMethod"
    />
    <recovery-code
      v-else-if="isMethod('recovery')"
      :path="path"
      :admin-mode="adminMode"
      :remember-me="rememberMe"
      :remember-me-enabled="rememberMeEnabled"
    />
  </div>
</template>
