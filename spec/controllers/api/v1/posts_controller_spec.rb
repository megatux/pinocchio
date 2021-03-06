require 'rails_helper'

describe Api::V1::PostsController do

	let!(:user) { create(:user) }
	let!(:a_post) { create(:post) }
	let!(:non_existing_post_id) { Post.order(:id).last.id + 1 }

	describe "GET #index" do
		let!(:other_post) { create(:post) }

		it "renders the json index" do
			get :index, format: :json
			expect(response).to have_http_status(:success)
			expect(response.header['Content-Type']).to include Mime::JSON
			expect(json).to have_key('posts')
			expect(json['posts'].size).to eq(2)
		end
	end

	describe "GET #show" do

		it "renders the json post" do
			get :show, id: a_post, format: :json
			expect(response).to have_http_status(:success)
			expect(response.header['Content-Type']).to include Mime::JSON
			expect(json).to eq(active_record_to_json a_post)
		end

		context "post does not exists" do
			it "fails with Not-Found" do
				get :show, id: non_existing_post_id, format: :json
				expect(response).to have_http_status(404)
			end
		end
	end

	describe "POST to create a Post" do
		let!(:unsaved_post) { build(:post) }

		context "without a valid authentication token" do
			it "fails" do
				post :create, post: unsaved_post.attributes, format: :json
				expect(response).to have_http_status(401)
			end
		end

		context "with a valid authentication token" do
		  before { set_http_auth user.api_auth_token }

			it "succeed" do
				post :create, post: unsaved_post.attributes, format: :json
				expect(response).to have_http_status(:success)
			end
		end
	end

	describe "DELETE to remove a Post" do

		it "fails when not authenticated" do
			delete :destroy, id: a_post.id, format: :json
			expect(response).to have_http_status(401)
		end

		context "user is not the creator" do
			before { set_http_auth user.api_auth_token }

			it "fails with Forbidden status" do
				delete :destroy, id: a_post.id, format: :json
				expect(response).to have_http_status(403)
			end
		end

		context "user is the post's creator" do
			before { set_http_auth a_post.user.api_auth_token }

			it "succeed" do
				expect {
					delete :destroy, id: a_post.id
					expect(response).to have_http_status(204)
				}.to change(Post, :count).by(-1)
			end
		end

		context "post does not exists" do
			before { set_http_auth a_post.user.api_auth_token }

			it "fails with Not-Found" do
				delete :destroy, id: non_existing_post_id
				expect(response).to have_http_status(404)
			end
		end

		describe "PUT #update" do

			context "not authenticated" do
				it "fails with Forbidden status" do
					put :update, id: a_post.id, format: :json
					expect(response).to have_http_status(401)
				end
			end

			context "non-existing Post" do
				before { set_http_auth a_post.user.api_auth_token }

				it "fails with Not-Found" do
					put :update, id: non_existing_post_id, post: a_post.attributes, format: :json
					expect(response).to have_http_status(404)
				end
			end

			context "valid request" do
				before { set_http_auth a_post.user.api_auth_token }

				it "updates the post" do
					put :update, id: a_post.id, post: a_post.attributes, format: :json
					expect(response).to have_http_status(204)
				end
			end
		end
	end
end