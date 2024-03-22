module Api
	class ApiController < ApplicationController
		skip_before_action :verify_authenticity_token
		rescue_from ActiveRecord::RecordNotFound, :with => :record_not_found
		before_action :authenticate_user

		private
			def authenticate_user
				@auth = request.headers['Authorization']
				render json: {}, status: :unauthorized unless valid_auth?
			end

			def valid_auth?
				# I could've added jwt using devise or other gems, made it simple for the sake of having a working project
				@auth.present? && @auth.split(' ').count == 2 && @auth.split(' ').first == 'Bearer'
			end

			def record_not_found
				render json: {}, status: :not_found
			end
	end
end
