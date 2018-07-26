#######################################
# Check if Rancher API is ready (accessible and returns non-5xx)
#
# Arguments:
#   rancherUrl         the url to the rancher api endpoint
#
# Returns:
#   -
#
# Author: Christopher Hauser <post@c-ha.de>
#######################################

function getRancherStatusCode(){
    rancherUrl=$1
    curl -I ${rancherUrl}/ 2>/dev/null | head -n 1 | cut -d$' ' -f2
    if [[ $${PIPESTATUS[0]} -eq 0 ]]; then
        return 0
    else
        return 1
    fi
}
function rancherIsReady(){
    rancherUrl=$1
    statuscode=$(getRancherStatusCode $rancherUrl)
    if [[ $statuscode == "" || "$statuscode" =~ ^5.* ]];  then
        return 1
    else
        return 0
    fi
}

if [[ ${BASH_SOURCE[0]} != $0 ]]; then
  export -f rancherIsReady
else
  rancherIsReady "${@}"
  exit $?
fi