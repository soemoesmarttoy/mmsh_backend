class UsersController < ApplicationController
    def index
        users = User.all
        render json: users, status: :ok
    end

    def check_password
        user1 = User.find_by(username: params[:username])
        unless user1
            render json: { messages: "invalid credentials" }, status: :unprocessable_entity
        end
        if params[:password] == user1.password
            render json: user1, status: :ok
        else
            render json: { messages: "invalid credentials" }, status: :unprocessable_entity
        end
    end
    def create
        user1 = User.create!(
            username: params[:username],
            email: params[:email],
            password: params[:password],
            role: params[:role],
        )
        render json: { messages: "success" }, status: :ok
    end

    def get_emails
        users = User.pluck(:email)
        render json: users, status: :ok
    end
    def get_usernames
        users = User.pluck(:username)
        render json: users, status: :ok
    end

    def update
        user1 = User.find_by(id: params[:id])
        user1.password = params[:password]
        user1.role = params[:role]
        user1.save
        render json: {}, status: :ok
    end
end
