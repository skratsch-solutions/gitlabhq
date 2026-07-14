import Vue from 'vue';
import OfflineTransferExportHistoryApp from '~/import/offline_transfer/export/history/app.vue';

export const initOfflineTransferExportHistory = () => {
  const el = document.getElementById('js-offline-transfer-export-history');

  if (!el) return null;

  return new Vue({
    el,
    name: 'OfflineTransferExportHistoryRoot',
    render(createElement) {
      return createElement(OfflineTransferExportHistoryApp, {});
    },
  });
};
