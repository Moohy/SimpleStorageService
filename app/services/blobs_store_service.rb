class BlobsStoreService < SimpleStorageService::Base
	size_limit 10.megabytes
	store_on :database
	# store_on :s3, queue: :store_s3, bucket: "simple-storage-service", region: "eu-west-1"
	# store_on :local, queue: :store_local, path: '/tmp'
	# store_on :ftp, queue: :store, path: '/home/user'
end
