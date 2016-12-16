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

#include:cat-and-rcl/definitions/sys.cat.rb

#include:cat-and-rcl/definitions/tag.cat.rb

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
