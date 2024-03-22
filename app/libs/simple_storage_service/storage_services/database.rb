module SimpleStorageService
	module StorageServices
		class Database < Base
			def store
				self.attachment.blobs.create!(params)
			end

			def retrieve
				self.blob["data"]["data"]
			end

			def validate!
				true
			end

			private
				def params
					{
						data: {
							data: self.blob[:data]
						},
						store_type: self.class.name.downcase.split("::").last.to_sym,
					}
				end
		end
	end
end
