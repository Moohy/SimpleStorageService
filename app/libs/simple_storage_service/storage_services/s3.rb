module SimpleStorageService
	module StorageServices
		class S3 < Base
			require 'net/http'
			require 'uri'
			require 'openssl'
			require 'cgi'

			def store
				upload
				self.attachment.blobs.create!(params)
			end

			def retrieve
				download
			end

			def validate!
				validate_aws_keys!
				validate_options!
			end

			private
				def params
					{
						data: {
							key: "#{self.attachment.reference_id}.txt",
							bucket: self.options[:bucket],
							region: self.options[:region],
							metadata: 'text/plain'
						},
						store_type: self.class.name.downcase.split("::").last.to_sym,
					}
				end

				def validate_aws_keys!
					aws_access_key_id = ENV['AWS_ACCESS_KEY_ID']
					aws_secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']

					if aws_access_key_id.nil? || aws_secret_access_key.nil? || aws_access_key_id.empty? || aws_secret_access_key.empty?
						raise SimpleStorageService::Errors::AwsKeysMissingError, "AWS access key ID and secret access key are required environment variables."
					end
				end

				def validate_options!
					bucket = self.options[:bucket]
					region = self.options[:region]

					if bucket.nil? || region.nil? || bucket.empty? || region.empty?
						raise SimpleStorageService::Errors::ValidationError, "Bucket and region are required options for S3 storage service."
					end
				end

				def download
					access_key_id = ENV['AWS_ACCESS_KEY_ID']
					secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
					expiration = 3600
					bucket_name = self.blob.data["bucket"]
					object_key = self.blob.data["key"]

					self.logger.info "Downloading object '#{object_key}' from bucket '#{bucket_name}'..."

					presigned_url = generate_presigned_url(access_key_id, secret_access_key, bucket_name, object_key, expiration, 'GET')

					request_url = presigned_url.gsub('=', '\=')

					uri = URI.parse(request_url)
					request = Net::HTTP::Get.new(uri)

					response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
						http.request(request)
					end

					if response.code == '200'
						self.logger.info "Object '#{object_key}' downloaded successfully!"
					else
						self.logger.error "Failed to download object '#{object_key}'. HTTP Error #{response.code}: #{response.body}"
						raise SimpleStorageService::Errors::DownloadError, "Failed to download object '#{object_key}'. HTTP Error #{response.code}: #{response.body}"
					end
					response.body
				end

				def upload
					access_key_id = ENV['AWS_ACCESS_KEY_ID']
					secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
					bucket_name = self.options[:bucket]
					expiration = 3600
					object_key = "#{self.attachment.reference_id}.txt"
					object_content = self.blob[:data]

					presigned_url = generate_presigned_url(access_key_id, secret_access_key, bucket_name, object_key, expiration, 'PUT')

					request_url = presigned_url.gsub('=', '\=')

					uri = URI.parse(request_url)
					request = Net::HTTP::Put.new(uri)
					request.body = object_content
					request['Content-Type'] = 'text/plain'

					response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
						http.request(request)
					end

					if response.code == '200'
						self.logger.info "Object '#{object_key}' uploaded successfully!"
					else
						self.logger.error "Failed to upload object '#{object_key}'. HTTP Error #{response.code}: #{response.body}"
						raise SimpleStorageService::Errors::UploadError, "Failed to upload object '#{object_key}'. HTTP Error #{response.code}: #{response.body}"
					end

				end

				def generate_presigned_url(aws_access_key_id, aws_secret_access_key, bucket_name, file_name, expiration_time, http_method)
					expiration = Time.now.utc + expiration_time
					url = "https://#{bucket_name}.s3.amazonaws.com/#{CGI.escape(file_name)}"

					if http_method.upcase == 'PUT'
						string_to_sign = "PUT\n\n\n#{expiration.to_i}\n/#{bucket_name}/#{CGI.escape(file_name)}"
					elsif http_method.upcase == 'GET'
						string_to_sign = "GET\n\n\n#{expiration.to_i}\n/#{bucket_name}/#{CGI.escape(file_name)}"
					else
						raise ArgumentError, "Unsupported HTTP method: #{http_method}. Only PUT and GET are supported."
					end

					signature = OpenSSL::HMAC.digest('sha1', aws_secret_access_key, string_to_sign)
					encoded_signature = Base64.strict_encode64(signature).strip

					"#{url}?AWSAccessKeyId=#{aws_access_key_id}&Expires=#{expiration.to_i}&Signature=#{CGI.escape(encoded_signature)}"
				end
		end
	end
end
