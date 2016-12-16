# terminator_for_rs_ss
A set of tools for periodically scraping RightScale account(s) for unused resources, and terminating them


/api/session/<session_id>/modules/<module_name>/<action>
/api/session/<session_id>/<action>

Session:
A unique session of terminator execution, initialized by skynet. The session id will
be dynamically generated, and will be used as the authentication key between the cat
and skynet.

Session model should record;
* Skynet requested start time
* CAT start time
* CAT version
* CAT finish time
* Target account - validate this to ensure it's an "authorized" consumer
* Requested modules and for each
  * Skynet requested start time
  * CAT start time

Module:
Equivalent to a resource type/collection which can be terminated. This should be something which
can be enabled/disabled on a per account and per session basis.

Resource:
A resource and the action that was performed on that resource (deleted, stopped, skipped, etc)

Resource model should record;
* resource type
* action
* resource specific things?
* raw json representation of resource


## Features
The concept of a "TTL"
ttl:date=<iso datetime>
ttl:range=<n days/hours/weeks>

The ability to apply the TTL to CloudApps.

The ability to detect that resources belong to a running CloudApp and interact with the CloudApp rather than the individual resources.

Resource Type, or pool exemptions. I.E. Don't terminate volumes under X size, or don't terminate vms on Y cloud (like "free" usage on private clouds)
