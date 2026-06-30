import { mountExtended } from 'helpers/vue_test_utils_helper';
import TwoFactorAuthentication from '~/authentication/sessions/components/two_factor_authentication.vue';
import TotpCode from '~/authentication/sessions/components/totp_code.vue';
import RecoveryCode from '~/authentication/sessions/components/recovery_code.vue';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

describe('TwoFactorAuthentication', () => {
  let wrapper;

  const defaultProps = {
    path: '/users/sign_in',
    rememberMe: '1',
    rememberMeEnabled: true,
  };

  const createComponent = (props = {}) => {
    wrapper = mountExtended(TwoFactorAuthentication, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findTotpCode = () => wrapper.findComponent(TotpCode);
  const findRecoveryCode = () => wrapper.findComponent(RecoveryCode);

  beforeEach(() => {
    createComponent();
  });

  it('defaults to rendering TotpCode', () => {
    expect(findTotpCode().exists()).toBe(true);
    expect(findRecoveryCode().exists()).toBe(false);
  });

  it('forwards props to the active child', () => {
    expect(findTotpCode().props()).toMatchObject({
      path: defaultProps.path,
      rememberMe: defaultProps.rememberMe,
      rememberMeEnabled: defaultProps.rememberMeEnabled,
    });
  });

  it('renders activeMethod instead of the default when provided', () => {
    createComponent({ activeMethod: 'recovery' });

    expect(findRecoveryCode().exists()).toBe(true);
    expect(findTotpCode().exists()).toBe(false);
  });

  describe('when switch-method "recovery" is emitted', () => {
    beforeEach(async () => {
      await findTotpCode().vm.$emit('switch-method', 'recovery');
    });

    it('shows RecoveryCode and hides TotpCode', () => {
      expect(findRecoveryCode().exists()).toBe(true);
      expect(findTotpCode().exists()).toBe(false);
    });

    it('forwards props to RecoveryCode', () => {
      expect(findRecoveryCode().props()).toMatchObject({
        path: defaultProps.path,
        rememberMe: defaultProps.rememberMe,
        rememberMeEnabled: defaultProps.rememberMeEnabled,
      });
    });
  });
});
