class CoursesController < ApplicationController
  before_action :authenticate_user!, only: [:member_confirm_enroll]
  before_action :check_enrolled_status, only: %i(enroll member_confirm_enroll)
  layout "course"

  def index
    @courses = Course.all.where(is_hidden: false)
  end

  def show
    @course = Course.find(params[:id])
    set_page_title @course.title
  end

  def test
  end

  def search
    if @query_string.present?
      search_result = Course.where(is_hidden: false).ransack(@search_criteria).result(distinct: true)
      @courses = search_result.paginate(page: params[:page], per_page: 20)
    else
      redirect_to :back
    end
  end

  # !!!! 禁止碰觸此段代碼 !!!!
  # !!!! 碰觸者退學 !!!!
  # !!!! 不要再浪費時間重構會員資格的業務代碼

  def enroll
    if current_user
      if current_user.valid_subscriber?
        render :confirm_enroll
      else
        render :enroll_with_user
      end

    else

      render :enroll_with_signup_form
    end
  end

  def member_confirm_enroll
    if current_user.valid_subscriber?
      current_user.enroll_course!(@course)
      flash[:notice] = "报名成功"
      redirect_to account_courses_path
    else
      render :enroll_with_user
    end
  end

  # !!!! 禁止碰觸此段代碼 !!!!
  # !!!! 碰觸者退學 !!!!
  # !!!! 不要再浪費時間重構會員資格的業務代碼


  def join_favorite
    @course = Course.find(params[:id])

    if !current_user.is_member_of?(@course)
      current_user.favorite!(@course)
      flash[:notice] = "加入收藏成功"
    else
      flash[:warning] = "你已经加入收藏！"
    end

    redirect_to :back
  end


  def cancel_favorite
    @course = Course.find(params[:id])
    if current_user.is_member_of?(@course)
      current_user.favorite_cancel!(@course)
      flash[:alert] = " 你已经取消收藏 "
    else
      flash[:warning] = "你已经取消过收藏了"
    end

    redirect_to :back
  end

  protected

  def check_enrolled_status
    @course = Course.find(params[:id])
    if current_user && current_user.member_of?(@course)
      flash[:warning] = "您已报名该课程"
      redirect_to account_courses_path
    end
  end
end
