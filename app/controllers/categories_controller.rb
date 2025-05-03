class CategoriesController < ApplicationController
  def index
    categories = Category.all
    render json: categories
  end

  def create
    category = Category.new(category_params)
    if category.save
      render json: category, status: :created
    else
      render json: { errors: category.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
  end

  def delete
  end

  def category_params
    params.require(:category).permit(:name, :category_type)
  end
end
