module SimpleStorageService
  class StoreJob < ApplicationJob
    queue_as :default

    def perform(*args)
      args[:service_class].new.assign_args(args)
    end
  end
end
