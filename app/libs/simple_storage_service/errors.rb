module SimpleStorageService
	module Errors
		# Attachment errors
		class InvalidBase64 < StandardError; end
		class SizeLimitExceeded < StandardError; end
		class AttachmentNotFound < StandardError; end
		class BlobNotFound < StandardError; end
		class ValidationError < StandardError; end

		# s3 errors
		class UploadError < StandardError; end
		class DownloadError < StandardError; end
		class AwsKeysMissingError < StandardError; end

		# File errors
		class FileNotFoundError < StandardError; end
		class FilePermissionError < StandardError; end
		class FileReadError < StandardError; end
		class FileSpaceError < StandardError; end
		class FileIsDirectoryError < StandardError; end
		class FileWriteError < StandardError; end

		# Ftp errors
		class FtpError < StandardError; end
		class FtpPermissionError < StandardError; end
		class FtpReplyError < StandardError; end
		class FtpKeysMissingError < StandardError; end

		# Request errors
		class RequestError < StandardError
			attr_reader :response

			def initialize(response)
				@response = response
			end
		end
	end
end
