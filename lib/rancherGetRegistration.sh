#######################################
# Returns registration details from existing token or creates new token
#
# Arguments:
#   rancherUrl         the url to the rancher api endpoint
#
# Returns:
#   -
#
# Author: Christopher Hauser <post@c-ha.de>
#######################################

source /usr/local/bin/error
source /usr/local/bin/retry

function getRancherToken(){
    rancherUrl=$1
    tokenId=$2

    token=($(curl -s -X GET ${rancherUrl}/v1/registrationtokens/${tokenId} | jq -r '.data[0].state'))
    if [[ ${token[0]} == "active" ]]; then
        return 0
    else
        return 1
    fi
}

function waitForRancherToken(){
    rancherUrl=$1
    tokenId=$2
    retry 10 5 "Rancher API is not accessible." "getRancherToken $rancherUrl $tokenId"
    if [[ $? != 0 ]]; then
        return 1
    else
        return 0
    fi
}

function rancherGetRegistration(){
    rancherUrl=$1

    registrationData=($(curl -s -X GET ${rancherUrl}/v1/registrationtokens | jq -r '.data[0].image, .data[0].registrationUrl'))
    if [[ "${registrationData[0]}" == "null" ]]; then
        projectId=$(curl -s -X GET ${rancherUrl}/v1/projects | jq -r '.data[0].id')

        # create new token
        tokenId=($(curl -s -X POST ${rancherUrl}/v1/projects/${projectId}/registrationtokens | jq -r '.id, .type'))
        if [[ ${tokenId[1]} == "error" ]]; then
            error "error while creating new token."
            return 1
        fi
        # wait for token
        waitForRancherToken $rancherUrl $tokenId
        if [[ $? != 0 ]]; then
            error "Rancher Token ${tokenId[0]} not ready."
            return 1
        fi

        # get token
        registrationData=($(curl -s -X GET -u ${rancherUrl}/v1/registrationtokens/${tokenId} | jq -r '.data[0].image, .data[0].registrationUrl'))
    fi

    if [[ "${registrationData[0]}" == "null" ]]; then
        error "registrationData image is null"
        return 1
    fi

    echo "${registrationData[0]} ${registrationData[1]}"
}

if [[ ${BASH_SOURCE[0]} != $0 ]]; then
  export -f rancherGetRegistration
else
  rancherGetRegistration "${@}"
  exit $?
fi