# frozen_string_literal: true

module VirtualRegistries
  class CachedResponseUploader < GitlabUploader
    include ObjectStorage::Concern
    extend ::Gitlab::Utils::Override

    storage_location :dependency_proxy

    alias_method :upload, :model

    before :cache, :set_content_type

    delegate :filename, to: :model

    def store_dir
      dynamic_segment
    end

    override :check_remote_file_existence_on_upload?
    def check_remote_file_existence_on_upload?
      false
    end

    override :sync_model_object_store?
    def sync_model_object_store?
      true
    end

    private

    def set_content_type(file)
      file.content_type = model.content_type
    end

    def dynamic_segment
      model.object_storage_key
    end
  end
end
