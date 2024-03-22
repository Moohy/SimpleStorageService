module SimpleStorageService
	module StorageServices
		class Local < Base
			def store
				write
				self.attachment.blobs.create!(params)
			end

			def retrieve
				read
			end

			def validate!
				validate_path!
			end

			private
				def params
					{
						data: {
							path: self.options[:path],
							filename: "#{self.attachment.reference_id}.txt",
						},
						store_type: self.class.name.downcase.split("::").last.to_sym,
					}
				end

				def validate_path!
					path = self.options[:path]

					if path.nil? || path.empty?
						raise SimpleStorageService::Errors::ValidationError, "Path is a required option for Local storage service."
					end
				end

				def read
					begin
						File.read("#{self.blob.data["path"]}/#{self.blob.data["filename"]}")
					rescue Errno::ENOENT
						raise SimpleStorageService::Errors::FileNotFoundError, "File not found"
					rescue Errno::EACCES
						raise SimpleStorageService::Errors::FilePermissionError, "Permission denied"
					rescue StandardError
						raise SimpleStorageService::Errors::FileReadError, "Error reading file"
					end
				end

				def write
					begin
						File.open("#{self.options[:path]}/#{self.attachment.reference_id}.txt", 'wb') do |file|
							file.write(self.blob[:data])
						end
					rescue Errno::EACCES
						raise SimpleStorageService::Errors::FilePermissionError, "Permission denied"
					rescue Errno::ENOSPC
						raise SimpleStorageService::Errors::FileSpaceError, "No space left on device"
					rescue Errno::EISDIR
						raise SimpleStorageService::Errors::FileIsDirectoryError, "Is a directory"
					rescue StandardError
						raise SimpleStorageService::Errors::FileWriteError, "Error writing file"
					end
				end
		end
	end
end


