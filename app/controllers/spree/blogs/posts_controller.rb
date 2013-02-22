class Spree::Blogs::PostsController < Spree::BaseController

  include SpreeEssentialBlog::PostsControllerHelper

  helper "spree/products"

  before_filter :get_sidebar, :only => [:index, :search, :show]

  def index
    @posts_by_month = default_scope.limit(50).group_by { |post| post.posted_at.strftime("%B %Y") }
    scope = default_scope
    if params[:year].present?
      year  = params[:year].to_i
      month = 1
      day   = 1
      if has_month = params[:month].present?
        if has_day = params[:day].present?
          day  = params[:day].to_i
        end
        month = params[:month].to_i
      end
      start = Date.new(year, month, day)
      stop  = start + 1.year
      if has_month
        stop = start + 1.month
        if has_day
          stop = start + 1.day
        end
      end
      scope = scope.where("posted_at >= ? AND posted_at <= ?", start, stop)
    end
    page_id = get_safe_page_id(params)
    @posts = scope.page(page_id).per(Spree::Post.per_page)
  end

  def search
    query = params[:query].gsub(/%46/, '.')
    page_id = get_safe_page_id(params)
    @posts = default_scope.tagged_with(query).page(page_id).per(Spree::Post.per_page)
    get_tags
    render :template => 'spree/blogs/posts/index'
  end

  def show
    @post = default_scope.includes(:tags, :images, :products).find_by_path(params[:id]) rescue nil
    return redirect_to archive_posts_path unless @post
  end

  def archive
    @posts = default_scope.all
  end

private

  # Avoid SQL injections etc by sending you to page
  # 1 if the page number doesn't look like a number
  def get_safe_page_id(params)
    return 1 unless params.present?
    page = params.fetch(:page, nil)
    id = page.to_i # Weird strings become 0
    (id == 0) ? 1 : id
  end

end
