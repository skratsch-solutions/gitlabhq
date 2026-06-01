import { mount } from '@vue/test-utils';
import { GlButton } from '@gitlab/ui';
import HiddenFilesWarning from '~/diffs/components/hidden_files_warning.vue';

const defaultProps = {
  total: '10',
  visible: 5,
  plainDiffPath: 'plain-diff-path',
  emailPatchPath: 'email-patch-path',
};

describe('HiddenFilesWarning', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(HiddenFilesWarning, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  it('has a correct plain diff URL', () => {
    createComponent();
    const plainDiffLink = wrapper.findAllComponents(GlButton).at(0);

    expect(plainDiffLink.attributes('href')).toBe(defaultProps.plainDiffPath);
  });

  it('has a correct email patch URL', () => {
    createComponent();
    const emailPatchLink = wrapper.findAllComponents(GlButton).at(1);

    expect(emailPatchLink.attributes('href')).toBe(defaultProps.emailPatchPath);
  });

  it('does not render buttons when links are not provided', () => {
    createComponent({ plainDiffPath: undefined, emailPatchPath: undefined });
    expect(wrapper.findAllComponents(GlButton)).toHaveLength(0);
  });

  const renderedText = () => wrapper.text().replace(/\s+/g, ' ').trim();

  it('renders the listed, expanded and download sentences', () => {
    createComponent();
    expect(renderedText()).toContain(
      'Only the first 10 files are listed on this page. 5 files are expanded by default. To view all changes, download the diff.',
    );
  });

  it('declines the listed sentence in the singular form', () => {
    createComponent({ total: 1 });
    expect(renderedText()).toContain('Only the first 1 file is listed on this page.');
  });

  it('declines the expanded sentence in the singular form', () => {
    createComponent({ visible: 1 });
    expect(renderedText()).toContain('1 file is expanded by default.');
  });

  it('drops the "+" suffix when total is passed as a "N+" string', () => {
    createComponent({ total: '10+' });
    expect(renderedText()).toContain('Only the first 10 files are listed on this page.');
  });
});
