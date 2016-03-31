class GroupsController < ApplicationController
  before_filter :groups_enabled?

  def index
    @filters = params[:filters] || {}
    if @filters['member']
      @filters['options'] = { 'member' => { 'and' => true } }
    end
    groups_response = cmr_client.get_cmr_groups(@filters, token)

    @users = urs_users

    if groups_response.success?
      @groups = groups_response.body['items']
    else
      Rails.logger.error("Get Cmr Groups Error: #{groups_response.inspect}")
      flash[:error] = Array.wrap(groups_response.body['errors'])[0]
      @groups = nil
    end
  end

  def show
    @concept_id = params[:id]
    group_response = cmr_client.get_group(@concept_id, token)

    if group_response.success?
      @group = group_response.body
      request_group_members(@concept_id)
    else
      flash[:error] = Array.wrap(group_response.body['errors'])[0]
      redirect_to groups_path
    end
  end

  def new
    @group = {}

    @users_options = urs_users
    @selected_users = []
  end

  def create
    group = params[:group]
    members = params[:selected_members] || []

    if valid_group?(group)
      group['provider_id'] = @current_user.provider_id
      group_creation_response = cmr_client.create_group(group.to_json, token)

      if group_creation_response.success?
        concept_id = group_creation_response.body['concept_id']
        flash[:success] = 'Group was successfully created.'

        add_members_to_group(members, concept_id)
        redirect_to group_path(concept_id)
      else
        # Log error message
        Rails.logger.error("Group Creation Error: #{group_creation_response.inspect}")

        group_creation_error = Array.wrap(group_creation_response.body['errors'])[0]
        flash[:error] = group_creation_error
        @group = group
        set_previously_selected_members(members)
        render :new
      end
    else
      @group = group
      set_previously_selected_members(members)
      render :new
    end
  end

  def edit
    concept_id = params[:id]
    group_response = cmr_client.get_group(concept_id, token)

    if group_response.success?
      @group = group_response.body

      group_members_response = cmr_client.get_group_members(concept_id, token)
      if group_members_response.success?
        group_member_uids = group_members_response.body

        all_users = urs_users
        selected_users = all_users.select { |user| group_member_uids.include?(user[:uid]) }
        @users_options = all_users - selected_users
        @selected_users = []
      else
        Rails.logger.error("Group Members Request: #{group_members_response.inspect}")

        error = Array.wrap(group_members_response.body['errors'])[0]
        flash[:error] = error
      end
    else
      flash[:error] = Array.wrap(group_response.body['errors'])[0]
      redirect_to groups_path
    end
  end

  def update
    concept_id = params[:id]
    group = params[:group]
    members = params[:selected_members]

    if group
      if valid_group?(group)
        group['provider_id'] = @current_user.provider_id
        update_response = cmr_client.update_group(concept_id, group.to_json, token)

        if update_response.success?
          concept_id = update_response.body['concept_id']
          redirect_to group_path(concept_id)
        else
          Rails.logger.error("Group Update Error: #{update_response.inspect}")

          flash[:error] = Array.wrap(update_response.body['errors'])[0]
          @group = group
          render :edit
        end
      else
        @group = group
        render :edit
      end
    elsif members
      add_members_to_group(members, concept_id)
      redirect_to group_path(concept_id)
    end
  end

  def remove_members
    members = params[:members]

    unless members.empty?
      remove_members = cmr_client.remove_group_members(params[:id], members, token)

      if remove_members.success?
        flash[:success] = 'Members successfully removed.'
      else
        Rails.logger.error("Remove Members Error: #{remove_members.inspect}")

        flash[:error] = Array.wrap(remove_members.body['errors'])[0]
      end
    end

    redirect_to group_path
  end

  def destroy
    concept_id = params[:id]
    delete_group_response = cmr_client.delete_group(concept_id, token)
    if delete_group_response.success?
      group_name = params[:name]
      flash[:success] = "Group #{group_name} successfully deleted."
      redirect_to groups_path
    else
      # Log error message
      Rails.logger.error("Group Deletion Error: #{delete_group_response.inspect}")

      delete_group_error = Array.wrap(delete_group_response.body['errors'])[0]
      flash[:error] = delete_group_error
      redirect_to group_path(concept_id)
    end
  end

  private

  def set_previously_selected_members(members)
    all_users = urs_users
    selected = []
    not_selected = []
    all_users.each { |user| members.include?(user[:uid]) ? selected << user : not_selected << user }

    @users_options = not_selected
    @selected_users = selected
  end

  def request_group_members(concept_id)
    group_members_response = cmr_client.get_group_members(concept_id, token)
    if group_members_response.success?
      group_members_uids = group_members_response.body

      # match uids in group from cmr to all users
      @members = urs_users.select { |user| group_members_uids.include?(user[:uid]) }

      @members.sort_by { |user| user[:name].downcase }
    else
      # Log error message
      Rails.logger.error("Get Group Members Error: #{group_members_response.inspect}")

      get_group_members_error = Array.wrap(group_members_response.body['errors'])[0]
      flash[:error] = get_group_members_error
    end
  end

  def add_members_to_group(members, concept_id)
    return if members.empty?

    add_members_response = cmr_client.add_group_members(concept_id, members, token)
    if add_members_response.success?
      if flash[:success] == 'Group was successfully created.'
        flash[:success] = 'Group was successfully created and members successfully added.'
      else
        flash[:success] = 'Members successfully added.'
      end
    else
      # Log error message
      Rails.logger.error("Add Members to Group Error: #{add_members_response.inspect}")

      add_members_error = Array.wrap(add_members_response.body['errors'])[0]
      flash[:error] = add_members_error
    end
  end

  def map_urs_users(urs_users)
    # get users into hash with name, email, uid
    urs_users.map do |_uid, user|
      {
        name: "#{user['first_name']} #{user['last_name']}",
        email: user['email_address'],
        uid: user['uid']
      }
    end
  end

  def urs_users
    users_response = cmr_client.get_urs_users
    if users_response.success?
      map_urs_users(users_response.body.sort_by { |_uid, user| user['first_name'].downcase })
    else
      # Log error message
      Rails.logger.error("Users Request Error: #{users_response.inspect}")

      users_response_error = Array.wrap(users_response.body['error'])[0]
      flash[:error] = users_response_error
      []
    end
  end

  def groups_enabled?
    redirect_to dashboard_path unless Rails.configuration.groups_enabled
  end

  def valid_group?(group)
    case
    when group[:name].empty? && group[:description].empty?
      flash[:error] = 'Group Name and Description are required.'
    when group[:name].empty?
      flash[:error] = 'Group Name is required.'
    when group[:description].empty?
      flash[:error] = 'Group Description is required.'
    else
      return true
    end
    false
  end
end