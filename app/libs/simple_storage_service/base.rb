require "active_job/arguments"

module SimpleStorageService
	class Base
		class_attribute :storage_services, instance_writer: false, default: []
		class_attribute :size_limit, instance_writer: false, default: 5.megabytes

		attr_accessor :attachment, :blob, :metadata

		class << self
			def store_on(name, options = {})
				storage_services.push(name: name, options: options)
			end

			def size_limit(limit)
				self.size_limit = limit
			end

			def store(attachment, blob)
				new.store(attachment, blob)
			end

			def retrieve(attachment)
				new.retrieve(attachment)
			end
		end

		def store(attachment, blob)
			self.attachment = attachment
			self.blob = blob
			self.metadata = Metadata.new(self.blob)

			validate_store!

			run_store(enqueue: false)
		end

		def retrieve(attachment)
			self.attachment = attachment

			validate_retrieve!

			run_retrieve
		end

		private
			def run_store(enqueue: true)
				storage_services = self.class.storage_services.dup

				if (index = storage_services.find_index { |m| m[:name] == :database })
					storage_service = storage_services.delete_at(index)
					run_store_type(storage_service, enqueue: false)
				end

				storage_services.each do |storage_service|
					run_store_type(storage_service, enqueue: true)
				end

				self.attachment.update(size: self.metadata.size)
			end

			def run_store_type(storage_service, enqueue:)
				args = {
					service_class: self.class.name,
					options: storage_service[:options],
					attachment: self.attachment,
					blob: self.blob,
					action: :store
				}

				queue = storage_service.dig(:options, :queue)

				store = store_type_for(storage_service[:name])

				if enqueue
					store.set(queue: queue).perform_later(args)
				else
					store.perform_now(args)
				end
			end

			def store_type_for(name)
				"SimpleStorageService::StorageServices::#{name.to_s.camelize}".constantize
			end

			def run_retrieve
				blobs = self.attachment.blobs
				blob = blobs.order(store_type: :asc).first
				store = store_type_for(blob.store_type)

				args = {
					service_class: self.class.name,
					options: {},
					attachment: self.attachment,
					blob: blob,
					action: :retrieve
				}

				blob_data = store.perform_now(args)

				{ id: self.attachment.reference_id, data: blob_data, size: self.attachment.size, created_at: self.attachment.created_at }
			end

			def run_retrieve_type
				store.perform_now(args)
			end

			def validate_store!
				validate_base64_decodable!
				validate_size_limit!
			end

			def validate_retrieve!
				validate_attachment!
			end

			def validate_base64_decodable!
				raise Errors::InvalidBase64, "Invalid base64" unless Decoder.new(self.blob[:data]).decodable?
			end

			def validate_size_limit!
				if size_limit
					raise Errors::SizeLimitExceeded, "Size limit exceeded" if self.metadata.size > size_limit
				end
			end

			def validate_attachment!
				raise Errors::AttachmentNotFound, "Attachment not found" unless self.attachment
				raise Errors::BlobNotFound, "Blob not found" unless self.attachment.blobs.any?
			end
	end

	mattr_accessor :parent_class
	@@parent_class = "SimpleStorageService::StoreJob"
end
