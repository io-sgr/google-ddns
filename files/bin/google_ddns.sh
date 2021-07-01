#  Copyright (C) 2014-2021  SgrAlpha
#
#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#!/usr/bin/env sh

show_help() {
   cat << EOF

Example:
sh $0 \\
   --key-file=/credential.json \\
   --zone=default --domain=example.com \\
   --proxy-type=http --proxy-addr=localhost --proxy-port=8080

Options:
   -k|--key-file	Key file
   -z|--zone		Zone name
   -d|--domain		Domain name
   -t|--proxy-type	Proxy type
   -a|--proxy-addr	Proxy address
   -p|--proxy-port	Proxy port

EOF
}

for i in "$@"
do
case $i in
    -k=*|--key-file=*)
    KEY_FILE="${i#*=}"
    shift
    ;;
    -z=*|--zone=*)
    ZONE="${i#*=}"
    shift
    ;;
    -d=*|--domain=*)
    DOMAIN_NAME="${i#*=}"
    shift
    ;;
    -t=*|--proxy-type=*)
    PROXY_TYPE="${i#*=}"
    shift
    ;;
    -a=*|--proxy-addr=*)
    PROXY_ADDR="${i#*=}"
    shift
    ;;
    -p=*|--proxy-port=*)
    PROXY_PORT="${i#*=}"
    shift
    ;;
    *)
    echo "Unknow options: $i"
    show_help
    exit 1
    ;;
esac
done

if [[ -z "${KEY_FILE}" ]]; then
    echo "Missing key file."
    show_help
    exit 1
fi

if [[ ! -f "${KEY_FILE}" ]]; then
    echo "Key file not found at location: ${KEY_FILE}"
    exit 1
fi

if [[ -z "${ZONE}" ]]; then
    echo "Missing zone."
    show_help
    exit 1
fi

if [[ -z "${DOMAIN_NAME}" ]]; then
    echo "Missing domain."
    show_help
    exit 1
fi

gcloud auth activate-service-account --key-file="${KEY_FILE}"

GCP_PROJECT=`cat "${KEY_FILE}" | jq .project_id --raw-output`
echo "GCP Project: ${GCP_PROJECT}"
gcloud config set project "${GCP_PROJECT}"

if [[ ! -z "${PROXY_TYPE}" ]]; then
    gcloud config set proxy/type ${PROXY_TYPE}
fi
if [[ ! -z "${PROXY_ADDR}" ]]; then
    gcloud config set proxy/address ${PROXY_ADDR}
fi
if [[ ! -z "${PROXY_PORT}" ]]; then
    gcloud config set proxy/port ${PROXY_PORT}
fi

submit_tx() {
    CHANGE_ID=`gcloud dns record-sets transaction execute --zone="${ZONE}" --format=json | jq .id --raw-output`
    if [[ -z "${CHANGE_ID}" ]]; then
        echo "Something wrong when submitting transaction."
	gcloud dns record-sets transaction abort --zone="${ZONE}"
	exit 1
    fi
    until $(gcloud dns record-sets changes describe ${CHANGE_ID} --zone="${ZONE}" --format=json 2>&1 > /dev/null); do
        echo "Waiting transaction to be done ..."
	sleep 1
    done
    echo "Transaction is `gcloud dns record-sets changes describe ${CHANGE_ID} --zone="${ZONE}" --format=json | jq .status --raw-output`"
}

update() {
    TYPE=$1

    CURRENT_IP=`dig +short myip.opendns.com "${TYPE}" @resolver1.opendns.com`
    if [[ -z "${CURRENT_IP}" ]]; then
        echo "No type '${TYPE}' IP address found, skipping ..."
        return 0
    fi

    OLD_IP=`gcloud dns record-sets list --zone="${ZONE}" --name="${DOMAIN_NAME}." --type="${TYPE}" --format=json | jq ".[0].rrdatas[0]" | jq "select(. != null)" --raw-output`

    if [[ -z "${OLD_IP}" ]]; then
        echo "No old type '${TYPE}' IP address of '${DOMAIN_NAME}' found, creating type '${TYPE}' record to '${CURRENT_IP}' ..."
        gcloud dns record-sets transaction start --zone="${ZONE}"
        gcloud dns record-sets transaction add --zone="${ZONE}" --name="${DOMAIN_NAME}." --type="${TYPE}" --ttl=300 "${CURRENT_IP}"
        submit_tx
    elif [[ "${CURRENT_IP}" != "${OLD_IP}" ]]; then
        echo "The type '${TYPE}' IP address of '${DOMAIN_NAME}' changed from '${OLD_IP}' to '${CURRENT_IP}', updating ..."
        gcloud dns record-sets transaction start --zone="${ZONE}"
        gcloud dns record-sets transaction remove --zone="${ZONE}" --name="${DOMAIN_NAME}." --type="${TYPE}" --ttl=300 "${OLD_IP}"
        gcloud dns record-sets transaction add --zone="${ZONE}" --name="${DOMAIN_NAME}." --type="${TYPE}" --ttl=300 "${CURRENT_IP}"
        submit_tx
    else
        echo "The type '${TYPE}' IP address of '${DOMAIN_NAME}' is still '${OLD_IP}', no need to update."
    fi
}

update "AAAA"
update "A"

echo "Updated time: `date`"
