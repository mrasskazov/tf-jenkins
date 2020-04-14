#!/bin/bash -eE
set -o pipefail

[ "${DEBUG,,}" == "true" ] && set -x

my_file="$(readlink -e "$0")"
my_dir="$(dirname $my_file)"

source "$my_dir/definitions"

echo 'INFO: Deploy RHOSP overcloud'

create_env_file="stackrc.$JOB_NAME.env"
rsync -a -e "ssh -i $WORKER_SSH_KEY $SSH_OPTIONS" $WORKSPACE/$create_env_file $IMAGE_SSH_USER@$mgmt_ip:./
rsync -a -e "ssh -i $WORKER_SSH_KEY $SSH_OPTIONS" $WORKSPACE/src $IMAGE_SSH_USER@$mgmt_ip:./

cat <<EOF | ssh -i $WORKER_SSH_KEY $SSH_OPTIONS $IMAGE_SSH_USER@$mgmt_ip || res=1
export RHEL_USER=$RHEL_USER
export RHEL_PASSWORD=$RHEL_PASSWORD
[ "${DEBUG,,}" == "true" ] && set -x
export WORKSPACE=\$HOME
export DEBUG=$DEBUG
export CONTAINER_REGISTRY="$CONTAINER_REGISTRY"
export CONTRAIL_CONTAINER_TAG="$CONTRAIL_CONTAINER_TAG$TAG_SUFFIX"
export ENABLE_RHEL_REGISTRATION='false'
export PATH=\$PATH:/usr/sbin
source $create_env_file
cd src/tungstenfabric/tf-devstack/rhosp
./run.sh
EOF

echo "INFO: Deploy TF finished"
exit $res
