#! /bin/sh
# shellcheck disable=2034,2154
# SC2034: VAR appears unused => VAR used for templating
# SC2154: VAR is referenced but not assigned => VAR is assigned with eval statement in 01init.sh function

_path 'bash_aliases' '/etc/profile.d/99aliases.d'
_path 'bash_completion' '/etc/profile.d/99completion.d'
_path 'data' '/opt/data'
_path 'crontabs' '/etc/crontabs'
_path 'crontabs_log' '/var/log/cron.log'
_path 'etc_ngx' '/etc/nginx'
_path "${DOCKER_ID}" '/usr/local/bin'
_path 'opt_scripts' '/opt/scripts'
_path 'opt_ssh' '/opt/ssh'
_path "${SAFEDEPOSIT_ID}" '/root/.password-store'
_path 'socket' '/var/run/docker.sock'
_path 'ssh_root' '/root/.ssh'
_path 'tpm' '/root/.tmux/plugins/tpm'
_path 'var_log' '/var/log'
_path "${WORKSPACES_ID}" '/workspaces'
_path 'completion' "${DATA_PATH}/99completion"
_path "${ENTRYPOINT_ID}" "${OPT_SCRIPTS_PATH}/docker_entrypoint.sh"
_path 'entrypointd' "$(dirname "${ENTRYPOINT_PATH}")/$(basename -s '.sh' "${ENTRYPOINT_PATH}").d"
_path 'cron_log' "${VAR_LOG_PATH}/cron.log"
_path "${COMPOSE_PROJECT_NAME}" "${WORKSPACES_PATH}/${COMPOSE_PROJECT_NAME}"
_path "${SPACEPORN_ID}" "${WORKSPACES_PATH}/${SPACEPORN_ID}"
