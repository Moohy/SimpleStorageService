class Blob < ApplicationRecord
  belongs_to :attachment

  enum store_type: { database: 0, local: 1, s3: 2, ftp: 3 }

  validates_uniqueness_of :store_type, scope: :attachment_id
end
