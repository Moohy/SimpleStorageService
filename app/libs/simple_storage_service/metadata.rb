module SimpleStorageService
	class Metadata
		attr_reader :blob, :size

		def initialize(blob)
			@blob = blob
			@size = Decoder.new(@blob[:data]).decode.bytesize
		end
	end
end
