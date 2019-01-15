class UsersController < ApplicationController
  def index
    users = User.connection.select_all(
                "select *, (CASE WHEN (required_licence - (CASE WHEN valid_licence >=0 THEN valid_licence ELSE 0 END)) >= 0 THEN (required_licence - (CASE WHEN valid_licence >=0 THEN valid_licence ELSE 0 END)) ELSE 0 end) def, (cameras_owned + camera_shares) total_cameras from (
                 select *, (select count(cr.id) from cloud_recordings cr left join cameras c on c.owner_id=u.id where c.id=cr.camera_id and cr.status <>'off' and cr.storage_duration <> 1) required_licence,
                 (select SUM(l.total_cameras) from licences l left join users uu on l.user_id=uu.id where uu.id=u.id and cancel_licence=false) valid_licence,
                 (select count(*) from cameras cc left join users uuu on cc.owner_id=uuu.id where uuu.id=u.id) cameras_owned,
                 (select count(*) from camera_shares cs left join users uuuu on cs.user_id=uuuu.id where uuuu.id = u.id) camera_shares,
                 (select count(*) from snapmails sm left join users suser on sm.user_id=suser.id where suser.id = u.id) snapmail_count,
                 (select name from countries ct left join users uuuuu on ct.id=uuuuu.country_id where uuuuu.id=u.id) country,
                 (select count(cs1.id) from camera_shares cs1 where cs1.user_id=u.id and cs1.camera_id = 279) share_id
                 from users u where 1=1 order by created_at desc
                ) t"
              )
    total_records = users.count
    display_length = params["per_page"].to_i
    display_length = display_length < 0 ? total_records : display_length
    display_start = params["page"].to_i <= 1 ? 0 : (params["page"].to_i - 1) * display_length + 1

    index_end = ((params["page"].to_i - 1) * display_length) + display_length
    index_end = index_end > total_records ? total_records - 1 : index_end
    last_page = (total_records / display_length.to_f).round
    records = {
      data: [],
      total: total_records,
      per_page: display_length,
      from: display_start,
      to: index_end,
      current_page: params["page"],
      last_page: last_page,
      next_page_url: params["page"].to_i == last_page ? "" : "/v1/users?sort=#{params["sort"]}&per_page=#{display_length}&page=#{params["page"].to_i + 1}",
      prev_page_url: params["page"].to_i < 1 ? "" : "/v1/users?sort=#{params["sort"]}&per_page=#{display_length}&page=#{params["page"].to_i - 1}"
    }
    (display_start..index_end).each do |index|
      records[:data][records[:data].count] = {
        username: users[index]["username"],
        name: users[index]["firstname"] + " " + users[index]["lastname"],
        email: users[index]["email"],
        api_id: users[index]["api_id"],
        api_key: users[index]["api_key"],
        cameras_owned: users[index]["cameras_owned"],
        camera_shares: users[index]["camera_shares"],
        total_cameras: users[index]["total_cameras"],
        country: users[index]["country"],
        created_at: users[index]["created_at"] ? DateTime.parse(users[index]["created_at"]).strftime("%A, %d %b %Y %l:%M %p") : "",
        confirmed_at: users[index]["confirmed_at"] ? DateTime.parse(users[index]["confirmed_at"]).strftime("%A, %d %b %Y %l:%M %p") : "",
        last_login_at: users[index]["last_login_at"] ? DateTime.parse(users[index]["last_login_at"]).strftime("%A, %d %b %Y %l:%M %p") : "",
        required_licence: users[index]["required_licence"],
        valid_licence: users[index]["valid_licence"],
        def: users[index]["def"],
        payment_method: users[index]["payment_method"],
        id: users[index]["id"],
        referral_url: users[index]["referral_url"],
        snapmail_count: users[index]["snapmail_count"]
      }
    end
    @pageload = false
    render json: records
  end
end
