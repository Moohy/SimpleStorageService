module SimpleStorageService
	class Decoder
		attr_reader :data

		def initialize(data)
			@data = data
		end

		def decode
			raise Errors::InvalidBase64, "Invalid base64" unless decodable?
			Base64.decode64(@data)
		end

		def decodable?
			@data.is_a?(String) && Base64.strict_encode64(Base64.decode64(@data)) == @data
		end
	end
end
