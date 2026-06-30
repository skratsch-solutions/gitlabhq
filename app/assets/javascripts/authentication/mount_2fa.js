import Vue from 'vue';
import { parseBoolean } from '~/lib/utils/common_utils';
import TwoFactorAuthentication from './sessions/components/two_factor_authentication.vue';
import { initWebauthnAuthenticate } from './webauthn';

export const mount2faAuthentication = () => {
  const el = document.getElementById('js-2fa');

  if (!el) {
    initWebauthnAuthenticate(); // remove when two_factor_vue flag is deleted.
    return false;
  }
  // totpEnabled (and the webauthn data attrs) are reintroduced in step 2 when the
  // alternate-method buttons land. The dataset still carries them from the HAML.
  const { path, adminMode, activeMethod, rememberMe, rememberMeEnabled } = el.dataset;

  return new Vue({
    el,
    name: 'TwoFactorAuthenticationRoot',
    render(createElement) {
      return createElement(TwoFactorAuthentication, {
        props: {
          path,
          adminMode: parseBoolean(adminMode),
          activeMethod,
          rememberMe,
          rememberMeEnabled: parseBoolean(rememberMeEnabled),
        },
      });
    },
  });
};
