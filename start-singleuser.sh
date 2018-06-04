#!/bin/bash
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.

set -e


if [ ! -d /home/jovyan/work/custom/lib ]
  then
    mkdir -p /home/jovyan/work/custom/lib 
fi
if [ ! -d /home/jovyan/work/custom/bin ]
  then
    mkdir -p /home/jovyan/work/custom/bin 
fi

notebook_arg=""
if [ -n "${NOTEBOOK_DIR:+x}" ]
then
    notebook_arg="--notebook-dir=${NOTEBOOK_DIR}"
fi

exec /usr/sbin/sshd

exec jupyterhub-singleuser \
  --port=8888 \
  --ip=0.0.0.0 \
  --user=$JPY_USER \
  --cookie-name=$JPY_COOKIE_NAME \
  --base-url=$JPY_BASE_URL \
  --hub-prefix=$JPY_HUB_PREFIX \
  --hub-api-url=$JPY_HUB_API_URL \
  ${notebook_arg} \
  $@