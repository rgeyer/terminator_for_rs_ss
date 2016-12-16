name "terminator v0.1"
rs_ca_ver 20131202
short_description "Find old stuff, delete it.. Save money.."

parameter "hours_old_param" do
  type "number"
  label "Resource Age in hours"
  default 24
end

parameter "skip_tag_param" do
  type "string"
  label "Tag, which if applied to a resource will instruct the terminator to spare that resource"
  default "terminator:skip=true"
end

parameter "skynet_session_id_param" do
  type "string"
  label "Session Id"
end

parameter "skynet_session_token_param" do
  type "string"
  label "Shared Secret"
end

parameter "dry_run_param" do
  type "string"
  label "When true, indicates that no actual termination or deletion should happen. Discovery and audits to Skynet still happen tho."
  default "false"
end

operation "launch" do
  description "Launch"
  definition "launch"
end

operation "everything" do
  description "Terminate Everything"
  definition "terminator"
end

operation "instances" do
  description "Terminate Instances"
  definition "instances"
end

operation "volumes" do
  description "Terminate Volumes"
  definition "volumes"
end

define skynet_session_update($session_id, $session_key, $fields) do
  $urlstr = "https://wstunnel1-1.rightscale.com/_token/terminator-for-rs-ss-dev/api2/session/"+$session_id+"/"
  $authstr = "Token "+$session_key
  $response = http_patch(
    url: $urlstr,
    headers: {
      "Accept": "application/json",
      "content-type": "application/json",
      "Authorization": $authstr
    },
    body: to_json($fields)
  )
  call sys_log("skynet_session_update", {detail: to_json($response)})
end

define skynet_resource_action($session_id, $session_key, $action, $age, $tags, $resource, $type) do
  $authstr = "Token "+$session_key
  $response = http_post(
    url: "https://wstunnel1-1.rightscale.com/_token/terminator-for-rs-ss-dev/api2/resource/",
    headers: {
      "Accept": "application/json",
      "content-type": "application/json",
      "Authorization": $authstr
    },
    body: to_json({
      action: $action,
      age: $age,
      tags: $tags,
      json: $resource,
      session: "/api2/session/"+$session_id+"/",
      rs_type: $type
    })
  )
  call sys_log("skynet_resource_action", {detail: to_json($response)})
end

###############################################################################
# BEGIN Include from cat-and-rcl/definitions/sys.cat.rb
###############################################################################
# Creates a simple array of the specified size.  The array contains integers
# indexed from 1 up to the specified size
#
# @param $size [int] the desired number of elements in the returned array
#
# @return [Array] a 1 indexed array of the specified size
define sys_get_array_of_size($size) return $array do
  $qty = 1
  $qty_ary = []
  while $qty <= to_n($size) do
    $qty_ary << $qty
    $qty = $qty + 1
  end

  $array = $qty_ary
end

# Creates a "log" entry in the form of an audit entry.  The target of the audit
# entry defaults to the deployment created by the CloudApp, but can be specified
# with the "auditee_href" option.
#
# @param $summary [String] the value to write in the "summary" field of an audit entry
# @param $options [Hash] a hash of options where the possible keys are;
#   * detail [String] the message to write to the "detail" field of the audit entry. Default: ""
#   * notify [String] the event notification catgory, one of (None|Notification|Security|Error).  Default: None
#   * auditee_href [String] the auditee_href (target) for the audit entry. Default: @@deployment.href
#
# @see http://reference.rightscale.com/api1.5/resources/ResourceAuditEntries.html#create
define sys_log($summary,$options) do
  $log_default_options = {
    detail: "",
    notify: "None",
    auditee_href: @@deployment.href
  }

  $log_merged_options = $options + $log_default_options
  rs.audit_entries.create(
    notify: $log_merged_options["notify"],
    audit_entry: {
      auditee_href: $log_merged_options["auditee_href"],
      summary: $summary,
      detail: $log_merged_options["detail"]
    }
  )
end

# Returns a resource collection containing clouds which have the specified relationship.
#
# @param $rel [String] the name of the relationship to filter on.  See cloud
#   media type for a full list
#
# @return [CloudResourceCollection] The clouds which have the specified relationship
#
# @see http://reference.rightscale.com/api1.5/media_types/MediaTypeCloud.html
define sys_get_clouds_by_rel($rel) return @clouds do
  @clouds = concurrent map @cloud in rs.clouds.get() return @cloud_with_rel do
    $rels = select(@cloud.links, {"rel": $rel})
    if size($rels) > 0
      @cloud_with_rel = @cloud
    else
      @cloud_with_rel = rs.clouds.empty()
    end
  end
end

# Fetches the account id of "this" cloud app using the default tags set on a
# deployment created by SS.
# selfservice:href=/api/manager/projects/12345/executions/54354bd284adb8871600200e
#
# @return [String] The account ID of the current cloud app
define sys_get_account_id() return $account_id do
  call sys_get_account_id_of_deployment(@@deployment) retrieve $account_id
end

# Fetches the account id of any cloud app using the default tags set on a
# deployment created by SS.
# selfservice:href=/api/manager/projects/12345/executions/54354bd284adb8871600200e
#
# @param @deployment [DeploymentResourceCollection] The deployment to inspect
#   and return the account ID for.
#
# @return [String] The account ID of the cloud app for the specified deployment
define sys_get_account_id_of_deployment(@deployment) return $account_id do
  call get_tags_for_resource(@deployment) retrieve $tags_on_deployment
  $href_tag = map $current_tag in $tags_on_deployment return $tag do
    if $current_tag =~ "(selfservice:href)"
      $tag = $current_tag
    end
  end

  if type($href_tag) == "array" && size($href_tag) > 0
    $tag_split_by_value_delimiter = split(first($href_tag), "=")
    $tag_value = last($tag_split_by_value_delimiter)
    $value_split_by_slashes = split($tag_value, "/")
    $account_id = $value_split_by_slashes[4]
  else
    $account_id = "N/A"
  end
end

# Fetches the execution id of "this" cloud app using the default tags set on a
# deployment created by SS.
# selfservice:href=/api/manager/projects/12345/executions/54354bd284adb8871600200e
#
# @return [String] The execution ID of the current cloud app
define sys_get_execution_id() return $execution_id do
  call sys_get_execution_id_of_deployment(@@deployment) retrieve $execution_id
end

# Fetches the execution id of any cloud app using the default tags set on a
# deployment created by SS.
# selfservice:href=/api/manager/projects/12345/executions/54354bd284adb8871600200e
#
# @param @deployment [DeploymentResourceCollection] The deployment to inspect
#   and return the execution ID for.
#
# @return [String] The execution ID of the cloud app for the specified deployment
define sys_get_execution_id_of_deployment(@deployment) return $execution_id do
  call get_tags_for_resource(@deployment) retrieve $tags_on_deployment
  $href_tag = map $current_tag in $tags_on_deployment return $tag do
    if $current_tag =~ "(selfservice:href)"
      $tag = $current_tag
    end
  end

  if type($href_tag) == "array" && size($href_tag) > 0
    $tag_split_by_value_delimiter = split(first($href_tag), "=")
    $tag_value = last($tag_split_by_value_delimiter)
    $value_split_by_slashes = split($tag_value, "/")
    $execution_id = last($value_split_by_slashes)
  else
    $execution_id = "N/A"
  end

end

# Fetches the href of "this" cloud app using the default tags set on a
# deployment created by SS.
# selfservice:href=/api/manager/projects/12345/executions/54354bd284adb8871600200e
#
# @return [String] The href of the current cloud app
define sys_get_href() return $href do
  call sys_get_href_of_deployment(@@deployment) retrieve $href
end

# Fetches the href of any cloud app using the default tags set on a
# deployment created by SS.
# selfservice:href=/api/manager/projects/12345/executions/54354bd284adb8871600200e
#
# @param @deployment [DeploymentResourceCollection] The deployment to inspect
#   and return the href for.
#
# @return [String] The href of the cloud app for the specified deployment
define sys_get_href_of_deployment(@deployment) return $href do
  call get_tags_for_resource(@deployment) retrieve $tags_on_deployment
  $href_tag = map $current_tag in $tags_on_deployment return $tag do
    if $current_tag =~ "(selfservice:href)"
      $tag = $current_tag
    end
  end

  if type($href_tag) == "array" && size($href_tag) > 0
    $tag_split_by_value_delimiter = split(first($href_tag), "=")
    $href = last($tag_split_by_value_delimiter)
  else
    $href = "N/A"
  end

end

# Fetches the email/username of the user who launched "this" cloud app using the default tags set on a
# deployment created by SS.
# selfservice:launched_by=foo@bar.baz
#
# @return [String] The email/username of the user who launched the current cloud app
define sys_get_launched_by() return $launched_by do
  call sys_get_launched_by_of_deployment(@@deployment) retrieve $launched_by
end

# Fetches the email/username of the user who launched any cloud app using the default tags set on a
# deployment created by SS.
# selfservice:launched_by=foo@bar.baz
#
# @param @deployment [DeploymentResourceCollection] The deployment to inspect
#   and return the launched by user for.
#
# @return [String] The email/username of the user who launched the cloud app for the specified deployment
define sys_get_launched_by_of_deployment(@deployment) return $launched_by do
  call get_tags_for_resource(@deployment) retrieve $tags_on_deployment
  $href_tag = map $current_tag in $tags_on_deployment return $tag do
    if $current_tag =~ "(selfservice:launched_by)"
      $tag = $current_tag
    end
  end

  if type($href_tag) == "array" && size($href_tag) > 0
    $tag_split_by_value_delimiter = split(first($href_tag), "=")
    $launched_by = last($tag_split_by_value_delimiter)
  else
    $launched_by = "N/A"
  end

end

# Fetches the name of the template "this" cloud app was launched from using the default tags set on a
# deployment created by SS.
# selfservice:launched_from=foobarbaz
#
# @return [String] The name of the template used to launch the current cloud app
define sys_get_launched_from() return $launched_from do
  call sys_get_launched_from_of_deployment(@@deployment) retrieve $launched_from
end

# Fetches the name of the template any cloud app was launched from using the default tags set on a
# deployment created by SS.
# selfservice:launched_from=foobarbaz
#
# @param @deployment [DeploymentResourceCollection] The deployment to inspect
#   and return the template used to launch the cloud app that owns it.
#
# @return [String] The name of the template used to launch the cloud app for the specified deployment
define sys_get_launched_from_of_deployment(@deployment) return $launched_from do
  call get_tags_for_resource(@deployment) retrieve $tags_on_deployment
  $href_tag = map $current_tag in $tags_on_deployment return $tag do
    if $current_tag =~ "(selfservice:launched_from)"
      $tag = $current_tag
    end
  end

  if type($href_tag) == "array" && size($href_tag) > 0
    $tag_split_by_value_delimiter = split(first($href_tag), "=")
    $launched_from = last($tag_split_by_value_delimiter)
  else
    $launched_from = "N/A"
  end

end

# Fetches the type of the template "this" cloud app was launched from using the default tags set on a
# deployment created by SS.
# selfservice:launched_from_type=source
#
# @return [String] The type of the template used to launch the current cloud app
define sys_get_launched_from_type() return $launched_from_type do
  call sys_get_launched_from_type_of_deployment(@@deployment) retrieve $launched_from_type
end

# Fetches the type of the template any cloud app was launched from using the default tags set on a
# deployment created by SS.
# selfservice:launched_from_type=source
#
# @param @deployment [DeploymentResourceCollection] The deployment to inspect
#   and return the type of template used to launch the cloud app that owns it.
#
# @return [String] The type of the template used to launch the cloud app for the specified deployment
define sys_get_launched_from_type_of_deployment(@deployment) return $launched_from_type do
  call get_tags_for_resource(@deployment) retrieve $tags_on_deployment
  $href_tag = map $current_tag in $tags_on_deployment return $tag do
    if $current_tag =~ "(selfservice:launched_from_type)"
      $tag = $current_tag
    end
  end

  if type($href_tag) == "array" && size($href_tag) > 0
    $tag_split_by_value_delimiter = split(first($href_tag), "=")
    $launched_from_type = last($tag_split_by_value_delimiter)
  else
    $launched_from_type = "N/A"
  end

end

# Concurrently finds and deletes all servers and arrays. Useful as a replacement
# for auto-terminate to clean up more quickly.
define sys_concurrent_terminate_servers_and_arrays() do
  concurrent do
    sub task_name:"terminate servers" do
      concurrent foreach @server in @@deployment.servers() do
        delete(@server)
      end
    end

    sub task_name:"terminate server_arrays" do
      concurrent foreach @array in @@deployment.server_arrays() do
        delete(@array)
      end
    end
  end
end

# Used as an alternative to provision(@resource), this will create the specified
# resource, but not launch it. Intended for use with Servers and ServerArrays
#
# @param @resource [Server|ServerArray] the resource definition to be created,
#   but not launched
#
# @return [Server|ServerArray] the created resource
define sys_create_resource_only(@resource) return @created_resource do
  $resource = to_object(@resource)
  $resource_type = $resource["type"]
  $fields = $resource["fields"]
  @created_resource = rs.$resource_type.create($fields)
end
###############################################################################
# END Include from cat-and-rcl/definitions/sys.cat.rb
###############################################################################


###############################################################################
# BEGIN Include from cat-and-rcl/definitions/tag.cat.rb
###############################################################################
# Returns all tags for a specified resource. Assumes that only one resource
# is passed in, and will return tags for only the first resource in the collection.
#
# @param @resource [ResourceCollection] a ResourceCollection containing only a
#   single resource for which to return tags
#
# @return $tags [Array<String>] an array of tags assigned to @resource
define get_tags_for_resource(@resource) return $tags do
  $tags = []
  $tags_response = rs.tags.by_resource(resource_hrefs: [@resource.href])
  $inner_tags_ary = first(first($tags_response))["tags"]
  $tags = map $current_tag in $inner_tags_ary return $tag do
    $tag = $current_tag["name"]
  end
  $tags = $tags
end
###############################################################################
# END Include from cat-and-rcl/definitions/tag.cat.rb
###############################################################################


define instances($hours_old_param,$skip_tag_param,$skynet_session_token_param,$skynet_session_id_param,$dry_run_param) do
  sub task_name:"instances" do
    concurrent map @cloud in rs.clouds.get() do
      concurrent map @instance in @cloud.instances(filter: ["state<>inactive","state<>terminated"]) do
        sub task_name:"instance", on_error:skip_on_422() do
          $retries = 0
          $tags = []
          $raw_created_at = null
          $has_deployment = false
          $instance = null

          call get_tags_for_resource(@instance) retrieve $tags
          if type($tags) == "null"
            $tags = []
          end
          $raw_created_at = @instance.created_at
          $rels = select(@instance.links, {"rel": "deployment"})
          $has_deployment = size($rels) > 0
          $instance = to_object(@instance)

          $instances_hours_old_seconds = (to_n($hours_old_param)*60)*60

          $created_at = to_n(to_d($raw_created_at))
          $created_delta = to_n(now()) - $created_at

          $is_old_enough = $created_delta > $instances_hours_old_seconds
          $is_not_tagged = logic_not(contains?($tags, [$skip_tag_param]))
          $belongs_to_cloudapp = false
          # TODO: Check if these are related to a CloudApp in SS, behave differently in that case?

          if $has_deployment
            @deployment = @instance.deployment()
            call sys_get_execution_id_of_deployment(@deployment) retrieve $execution_id
            if $execution_id != "N/A"
              call sys_log("Execution ID for deployment", {detail: $execution_id})
              #call skynet_resource_action($skynet_session_id_param,$skynet_session_token_param,"Cloud App Discovered",1,[],to_object(@deployment),"cloudapp")
              $belongs_to_cloudapp = true
            end
          end

          if $is_old_enough
            if $belongs_to_cloudapp
              call skynet_resource_action($skynet_session_id_param,$skynet_session_token_param,"Skipped - Belongs to a CloudApp", $created_delta, $tags, to_object(@instance), type(@instance))
            elsif !$is_not_tagged
              call skynet_resource_action($skynet_session_id_param,$skynet_session_token_param,"Skipped - Tagged to be saved", $created_delta, $tags, to_object(@instance), type(@instance))
            else
              call skynet_resource_action($skynet_session_id_param,$skynet_session_token_param,"Terminated", $created_delta, $tags, to_object(@instance), type(@instance))
              if $dry_run_param == "false"
                call sys_log("Actual Termination", {detail: @instance.id})
              end
            end
          else
            call skynet_resource_action($skynet_session_id_param,$skynet_session_token_param,"Skipped - Not Old Enough", $created_delta, $tags, to_object(@instance), type(@instance))
          end
        end
      end
    end
  end
end

define volumes($hours_old_param,$skip_tag_param,$skynet_session_token_param,$skynet_session_id_param,$dry_run_param) do
  sub task_name:"volumes" do
    $ts = now()
    call sys_get_clouds_by_rel("volumes") retrieve @clouds
    $delta = to_n(now() - $ts)
    $performance_filtered_clouds = $delta
    concurrent map @cloud in @clouds do
      concurrent map @volume in @cloud.volumes() do
        # Filter by attachment first
        $attachment = select(@volume.links, {"rel": "current_volume_attachment"})
        $created_at = to_n(to_d(@volume.created_at))
        $created_delta = to_n(now()) - $created_at

        call get_tags_for_resource(@volume) retrieve $tags
        if type($tags) == "null"
          $tags = []
        end

        $is_unattached = size($attachment) == 0
        $is_not_tagged = logic_not(contains?($tags, [$skip_tag_param]))
        if $is_unattached & $is_not_tagged
          call skynet_resource_action($skynet_session_id_param,$skynet_session_token_param,"Terminated", $created_delta, $tags, to_object(@volume), type(@volume))
        else
          call skynet_resource_action($skynet_session_id_param,$skynet_session_token_param,"Skipped", $created_delta, $tags, to_object(@volume), type(@volume))
        end

        # TODO: Filter by tag
      end
    end
  end
end

define terminator($hours_old_param,$skip_tag_param,$skynet_session_token_param,$skynet_session_id_param,$dry_run_param) do
  concurrent do
    call instances($hours_old_param,$skip_tag_param,$skynet_session_token_param,$skynet_session_id_param)

    call volumes($hours_old_param,$skip_tag_param,$skynet_session_token_param,$skynet_session_id_param)

    sub task_name:"snapshots" do
      #call get_clouds_by_rel("volume_snapshots") retrieve @clouds
    end

    sub task_name:"ips" do

    end

    sub task_name:"ssh_keys" do

    end

    # sub task_name:"server_templates" do
    #
    # end

    # sub task_name:"Services? ELB, RDS, Other stuff?" do
    #
    # end
  end
end

define launch($skynet_session_token_param,$skynet_session_id_param) do
  $fields = {
    "cat_start_time": "now",
    "cat_version_reported": "0.1"
  }
  call skynet_session_update($skynet_session_id_param, $skynet_session_token_param, $fields)
end

define skip_on_422() do
  $all_not_found = true
  foreach $error in $_errors do
    if $error["response"]["code"] != "422"
      $all_not_found = false
    end
  end
  if $all_not_found
    $_error_behavior = "skip"
  end
end
