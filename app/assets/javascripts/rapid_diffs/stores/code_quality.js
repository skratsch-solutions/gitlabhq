import { defineStore } from 'pinia';
import { groupBy } from 'lodash-es';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import Poll from '~/lib/utils/poll';
import { __ } from '~/locale';

export const useCodeQuality = defineStore('codeQuality', {
  state() {
    return {
      endpoint: null,
      files: {},
      loaded: false,
    };
  },
  actions: {
    fetchCodeQuality() {
      if (!this.endpoint || this.loaded) return;

      const poll = new Poll({
        resource: {
          getCodeQualityReports: (endpoint) => axios.get(endpoint),
        },
        data: this.endpoint,
        method: 'getCodeQualityReports',
        successCallback: ({ status, data }) => {
          if (status !== HTTP_STATUS_OK) return;
          this.files = groupBy(data?.new_errors || [], 'file_path');
          this.loaded = true;
          poll.stop();
        },
        errorCallback: (error) => {
          poll.stop();
          createAlert({
            message: __('Failed to load code quality findings. Try reloading the page.'),
            captureError: true,
            error,
          });
        },
      });

      poll.makeRequest();
    },
  },
  getters: {
    findingsForFile() {
      return (filePath) => this.files[filePath] || null;
    },
  },
});
