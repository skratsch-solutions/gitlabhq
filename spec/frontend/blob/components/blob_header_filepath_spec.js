import { GlBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BlobHeaderFilepath from '~/blob/components/blob_header_filepath.vue';
import { numberToHumanSize } from '~/lib/utils/number_utils';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { Blob as MockBlob } from './mock_data';

jest.mock('~/lib/utils/number_utils', () => ({
  numberToHumanSize: jest.fn(() => 'a lot'),
}));

describe('Blob Header Filepath', () => {
  let wrapper;

  function createComponent(blobProps = {}, options = {}, propsData = {}) {
    wrapper = shallowMountExtended(BlobHeaderFilepath, {
      propsData: {
        blob: { ...MockBlob, ...blobProps },
        ...propsData,
      },
      ...options,
    });
  }

  const getById = (id) => wrapper.findByTestId(id);
  const findBadge = () => wrapper.findComponent(GlBadge);

  describe('rendering', () => {
    it('matches the snapshot', () => {
      createComponent();
      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders regular name', () => {
      createComponent();
      expect(wrapper.find('.js-blob-header-filepath').text().trim()).toBe(MockBlob.path);
    });

    it('does not fail if the name is empty', () => {
      const emptyPath = '';
      createComponent({ path: emptyPath });
      expect(wrapper.find('.js-blob-header-filepath').exists()).toBe(false);
    });

    it('renders copy-to-clipboard icon that copies path of the Blob', () => {
      createComponent();
      const btn = wrapper.findComponent(ClipboardButton);
      expect(btn.exists()).toBe(true);
      expect(btn.vm.text).toBe(MockBlob.path);
    });

    it('renders filesize in a human-friendly format', () => {
      createComponent();
      expect(numberToHumanSize).toHaveBeenCalled();
      expect(wrapper.vm.blobSize).toBe('a lot');
    });

    it('should not show blob size', () => {
      createComponent({}, {}, { showBlobSize: false });
      expect(wrapper.find('small').exists()).toBe(false);
    });

    it('should have classes by default', () => {
      createComponent();
      expect(getById('file-title-content').attributes('class')).toEqual(
        'file-title-name mr-1 js-blob-header-filepath gl-break-all gl-font-bold',
      );
    });

    it('should have classes when shown as a link', () => {
      createComponent({}, {}, { showAsLink: true });
      expect(getById('file-title-content').attributes('class')).toEqual(
        'file-title-name mr-1 js-blob-header-filepath gl-break-all gl-font-bold !gl-text-blue-700 hover:gl-cursor-pointer',
      );
    });

    it('renders LFS badge if LFS if enabled', () => {
      createComponent({ storedExternally: true, externalStorage: 'lfs' });
      expect(findBadge().text()).toBe('LFS');
    });

    it('renders a slot and prepends its contents to the existing one', () => {
      const slotContent = 'Foo Bar';
      createComponent(
        {},
        {
          scopedSlots: {
            'filepath-prepend': `<span>${slotContent}</span>`,
          },
        },
      );

      expect(wrapper.text()).toContain(slotContent);
      expect(wrapper.text().trim().substring(0, slotContent.length)).toBe(slotContent);
    });
  });

  describe('functionality', () => {
    it('sets gfm value correctly on the clipboard-button', () => {
      createComponent();
      expect(wrapper.vm.gfmCopyText).toBe(`\`${MockBlob.path}\``);
    });
  });
});
