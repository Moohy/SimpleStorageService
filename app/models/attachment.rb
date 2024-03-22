class Attachment < ApplicationRecord
	has_many :blobs, dependent: :destroy

	validates :reference_id, presence: true, uniqueness: true

	def store_blob(blob)
		BlobsStoreService.store(self, { data: blob })
	end
end
