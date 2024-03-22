module Api
	module V1
		class BlobsController < ApiController
			before_action :set_attachment, only: %i[show]

			# POST /api/v1/blobs
			# {
			# 	"id": "123",    # valid and unique identifier
			# 	"data": "data"  # valid base64 encoded data
			# }
			def create
				@attachment = Attachment.new(reference_id: attachment_params[:id])
				if @attachment.save
					begin
						@attachment.store_blob(attachment_params[:data])
					rescue StandardError => e
						@attachment.destroy
						Rails.logger.error("Error storing attachment, #{e.class.name} - #{e.message}")
					else
						render json: attachment_params , status: :created and return
					end
				end
				render json: {}, status: :unprocessable_entity
			end

			# GET /api/v1/blobs/:reference_id
			def show
				render json: BlobsStoreService.retrieve(@attachment), status: :ok
			end

			private
				def attachment_params
					params.require(:blob).permit(:id, :data)
				end

				def set_attachment
					@attachment = Attachment.find_by!(reference_id: params[:id])
				end
		end
	end
end
