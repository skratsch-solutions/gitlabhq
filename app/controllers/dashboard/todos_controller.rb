# frozen_string_literal: true

class Dashboard::TodosController < Dashboard::ApplicationController
  include ActionView::Helpers::NumberHelper
  include PaginatedCollection
  include Gitlab::Utils::StrongMemoize

  before_action :authorize_read_project!, only: :index
  before_action :authorize_read_group!, only: :index
  before_action :find_todos, only: [:destroy_all]

  feature_category :notifications
  urgency :low

  def index
    push_frontend_feature_flag(:todos_vue_application, current_user)
    push_frontend_feature_flag(:todos_snoozing, current_user)

    # When removing the `todos_vue_application`, also drop the #vue method below
    if Feature.enabled?(:todos_vue_application, current_user)
      render :vue
    else
      @sort = pagination_params[:sort]
      find_todos
      @todos = @todos.page(pagination_params[:page])
      @todos = @todos.with_entity_associations

      return if redirect_out_of_range(@todos, todos_page_count(@todos))

      @allowed_todos = ::Todos::AllowedTargetFilterService.new(@todos, current_user).execute
    end
  end

  # To be removed along with the `todos_vue_application` feature flag.
  # Also make sure to remove the corresponding route in `config/routes/dashboard.rb`.
  def vue
    redirect_to(dashboard_todos_path, status: :found)
  end

  def destroy
    todo = current_user.todos.find(params[:id])

    TodoService.new.resolve_todo(todo, current_user, resolved_by_action: :mark_done)

    respond_to do |format|
      format.html do
        redirect_to dashboard_todos_path, status: :found, notice: _('To-do item successfully marked as done.')
      end
      format.js { head :ok }
      format.json { render json: todos_counts }
    end
  end

  def destroy_all
    updated_ids = TodoService.new.resolve_todos(@todos, current_user, resolved_by_action: :mark_all_done)

    respond_to do |format|
      format.html do
        redirect_to dashboard_todos_path, status: :found, notice: _('Everything on your to-do list is marked as done.')
      end
      format.js { head :ok }
      format.json { render json: todos_counts.merge(updated_ids: updated_ids) }
    end
  end

  def restore
    TodoService.new.restore_todo(current_user.todos.find(params[:id]), current_user)

    render json: todos_counts
  end

  def bulk_restore
    TodoService.new.restore_todos(current_user.todos.id_in(params[:ids]), current_user)

    render json: todos_counts
  end

  private

  def authorize_read_project!
    project_id = params[:project_id]

    return unless project_id.present?

    project = Project.find(project_id)
    render_404 unless can?(current_user, :read_project, project)
  end

  def authorize_read_group!
    group_id = params[:group_id]

    return unless group_id.present?

    group = Group.find(group_id)
    render_404 unless can?(current_user, :read_group, group)
  end

  def find_todos
    @todos ||= TodosFinder.new(current_user, todo_params).execute
  end

  def todos_counts
    {
      count: current_user.todos_pending_count,
      done_count: current_user.todos_done_count
    }
  end

  def todos_page_count(todos)
    if todo_params.except(:sort, :page).empty?
      (current_user.todos_pending_count.to_f / todos.limit_value).ceil
    else
      todos.total_pages
    end
  end

  def todo_params
    aliased_params(
      params.permit(:action_id, :author_id, :project_id, :type, :sort, :state, :group_id)
    )
  end
  strong_memoize_attr :todo_params

  def aliased_params(original_params)
    alias_issue_type(original_params)
    alias_action_id(original_params)

    original_params
  end

  def alias_issue_type(original_params)
    return unless original_params[:type] == Issue.name

    original_params[:type] = [Issue.name, WorkItem.name]
  end

  def alias_action_id(original_params)
    return unless original_params[:action_id].to_i == ::Todo::MENTIONED

    original_params[:action_id] = [::Todo::MENTIONED, ::Todo::DIRECTLY_ADDRESSED]
  end
end
