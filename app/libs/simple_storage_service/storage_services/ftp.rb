module SimpleStorageService
	module StorageServices
		class Ftp < Base
			require 'net/ftp'
			require 'tempfile'

			def store
				store_file
				self.attachment.blobs.create!(params)
			end

			def retrieve
				retrieve_file
			end

			def validate!
				validate_ftp_keys!
				validate_path!
			end

			private

				def params
					{
						data: {
							ftp_host: ENV['FTP_HOST'],
							path: self.options[:path],
							filename: "#{self.attachment.reference_id}.txt"
						},
						store_type: self.class.name.downcase.split("::").last.to_sym,
					}
				end

				def self.validate_ftp_keys!
					ftp_host = ENV['FTP_HOST']
					ftp_user = ENV['FTP_USER']
					ftp_password = ENV['FTP_PASSWORD']

					if ftp_host.nil? || ftp_user.nil? || ftp_password.nil? || ftp_host.empty? || ftp_user.empty? || ftp_password.empty?
						raise SimpleStorageService::Errors::FtpKeysMissingError, "FTP_HOST, FTP_USER, and FTP_PASSWORD are required environment variables for FTP storage service."
					end
				end

				def validate_path!
					path = self.options[:path]

					if path.nil? || path.empty?
						raise SimpleStorageService::Errors::ValidationError, "Path is a required option for FTP storage service."
					end
				end

				def retrieve_file
					begin
						data = nil
						Net::FTP.open(ENV['FTP_HOST'], ENV['FTP_USER'], ENV['FTP_PASSWORD']) do |ftp|
							file = Tempfile.new("#{self.blob.data[:filename]}}")
							ftp.gettextfile("#{self.blob.data[:path]}/#{self.blob.data[:filename]}", file)
							data = file.read
							file.close
						end
					rescue Net::FTPPermError
						raise SimpleStorageService::Errors::FtpPermissionError, "Permission error"
					rescue Net::FTPReplyError
						raise SimpleStorageService::Errors::FtpReplyError, "Reply error"
					rescue StandardError
						raise SimpleStorageService::Errors::FtpError, "FTP Error"
					end
					data
				end

				def store_file
					begin
						Net::FTP.open(ENV['FTP_HOST'], ENV['FTP_USER'], ENV['FTP_PASSWORD']) do |ftp|
							file = Tempfile.new("#{self.attachment.reference_id}.txt")
							file.write(self.blob[:data])
							ftp.puttextfile(file, "#{self.options[:path]}/#{self.attachment.reference_id}.txt")
							file.close
						end
					rescue Net::FTPPermError
						raise SimpleStorageService::Errors::FtpPermissionError, "Permission error"
					rescue Net::FTPReplyError
						raise SimpleStorageService::Errors::FtpReplyError, "Reply error"
					rescue StandardError
						raise SimpleStorageService::Errors::FtpError,  "FTP Error"
					end
				end
		end
	end
end

