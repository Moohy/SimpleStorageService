module SimpleStorageService
	module StorageServices
		class Base < SimpleStorageService.parent_class.constantize
			attr_reader :options, :attachment, :blob, :action, :logger


			def assign_args(args)
				@options = args[:options] || {}
				@attachment = args[:attachment]
				@blob = args[:blob]
				@action = args[:action]
				@logger = @options.fetch(:logger, Rails.logger)
				self
			end

			def perform(args)
				assign_args(args)

				case @action
				when :store
					validate!
					store
				when :retrieve
					retrieve
				else
						raise ArgumentError, "Invalid action: #{@action}"
				end
			end

			def store
				raise NotImplementedError, "Store services must implement a store service"
			end

			def retrieve
				raise NotImplementedError, "Store services must implement a retrieve service"
			end
		end
	end
end
