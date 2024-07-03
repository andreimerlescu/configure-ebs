#!/bin/bash

# app_title
function app_title(){
   clear
   tcolt_purple "   _____             __ _                        ______ ____   _____ "
   tcolt_purple "  / ____|           / _(_)                      |  ____|  _ \ / ____|"
   tcolt_purple " | |     ___  _ __ | |_ _  __ _ _   _ _ __ ___  | |__  | |_) | (___  "
   tcolt_purple " | |    / _ \| '_ \|  _| |/ \` | | | | '__/ _ \ |  __| |  _ < \___ \ "
   tcolt_purple " | |___| (_) | | | | | | | (_| | |_| | | |  __/ | |____| |_) |____) |"
   tcolt_purple "  \_____\___/|_| |_|_| |_|\__, |\__,_|_|  \___| |______|____/|_____/ "
   tcolt_purple "                           __/ |                                     "
   tcolt_purple "                          |___/                                      "
   tcolt_gold   "      Created by: Andrei Merlescu (github.com/andreimerlescu)        "
   tcolt_gold   ""
}

# Parameters
declare -A params=(
   [volumeid]=''
   [device]=''
   [label]=''
   [size]=''
   [fs]='xfs'
   [fstrim]=''
   [mount]=''
)

# Usage
declare -A documentation=(
   [volumeid]='The AWS EBS block device ID. Seen as vol#################'
   [device]='The original mapping of the EBS device mapping. Should be /dev/xvd#.'
   [label]='Name of the volume being created'
   [fs]='Filesystem type of the EBS volume'
   [fstrim]='Set to any value to enable fstrim on this EBS volume'
   [mount]='Define the mount point of the EBS volume'
   [size]='Integer of GiB of EBS volume capacity'
)

# print_usage
function print_usage(){
   echo "Usage: ${0} [OPTIONS]"

   # Set the padSize dynamically
   local -i padSize=3;
   for param in "${!params[@]}"; do local -i len="${#param}"; (( len > padSize )) && padSize=len; done
   ((padSize+=3)) # add right buffer

   # Print the usage
   for param in "${!params[@]}"; do
      local d; local p; p="${params[$param]}"; { [[ -n "${p}" ]] && [[ "${#p}" != 0 ]] && d=" (default = '${p}')"; } || d=""
      echo "       --$(pad "$padSize" "${param}") ${documentation[$param]}${d}"
   done
}

# Function to parse command line arguments
function parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help|-h|help)
                print_usage
                exit 0
                ;;
            --*)
                key="${1/--/}" # Remove '--' prefix
                key="${key//-/_}" # Replace '-' with '_' to match params[key]
                if [[ -n "${2}" && "${2:0:1}" != "-" ]]; then
                    params[$key]="$2"
                    shift 2
                else
                    tcolt_red "Error: Missing value for $1" >&2
                    exit 1
                fi
                ;;
            *)
                tcolt_orange "Unknown option: $1" >&2
                print_usage
                exit 1
                ;;
        esac
    done
}

# Terminal Colors
function error(){ tcolt_red "[ERROR] ${1}"; }
function warning(){ tcolt_orange "[WARNING] ${1}"; }
function info(){ tcolt_yellow "[INFO] ${1}"; }
function debug(){ tcolt_pink "[DEBUG] ${1}"; }
function success(){ tcolt_green "[SUCCESS] ${1}"; }
function rerror(){ replace "$(tcolt_red "[ERROR] ${1}";)"; }
function rwarning(){ replace "$(tcolt_orange "[WARNING] ${1}";)"; }
function rinfo(){ replace "$(tcolt_yellow "[INFO] ${1}";)"; }
function rdebug(){ replace "$(tcolt_pink "[DEBUG] ${1}";)"; }
function rsuccess(){ replace "$(tcolt_green "[SUCCESS] ${1}";)"; }
function tcolt_red() { echo -e "\033[0;31m${1}\033[0m"; }
function tcolt_blue() { echo -e "\033[0;34m${1}\033[0m"; }
function tcolt_green() { echo -e "\033[0;32m${1}\033[0m"; }
function tcolt_purple() { echo -e "\033[0;35m${1}\033[0m"; }
function tcolt_gold() { echo -e "\033[0;33m${1}\033[0m"; }
function tcolt_silver() { echo -e "\033[0;37m${1}\033[0m"; }
function tcolt_yellow() { echo -e "\033[1;33m${1}\033[0m"; }
function tcolt_orange() { echo -e "\033[0;33m${1}\033[0m"; }
function tcolt_orange() { echo -e "\033[0;33m${1}\033[0m"; }
function tcolt_pink() { echo -e "\033[1;35m${1}\033[0m"; }
function tcolt_magenta() { echo -e "\033[0;35m${1}\033[0m"; }

# Helper Functions
function pad() { printf "%-${1}s\n" "${2}"; }
function replace(){ printf "\r%s%s" "${1}" "$(printf "%-$(( $(tput cols) - ${#1} ))s")"; }
function valid_path(){ { [[ "${1}" == /* ]] && [[ ! "${1}" =~ [^[:alnum:]/._-] ]] && return 0; } || return 1; }

# device_uuid "vol###"
function device_uuid(){
   local uuid
   uuid=$(blkid "${params[device],,}" -o value -s UUID)
   [[ -n "${uuid}" ]] && echo "${uuid}" || return 1
}

# device_fs "vol###"
function device_fs(){
   local fs_type;
   fs_type=$(blkid "${params[device],,}" -o value -s TYPE);
   { [[ -z "${fs_type}" ]] && return 1; } || echo "${fs_type}"
}

# device_has_fs "vol###"
function device_has_fs(){
   local fs_type
   fs_type=$(blkid "${params[device],,}" -o value -s TYPE)
   { [[ -z "${fs_type}" ]] && return 1; } || return 0
}

# device_from_volume_id "vol0f9dbad085229e1df"
function device_from_volume_id(){
   local volumeid
   local device
   volumeid="${params[volumeid]/-//}"
   volumeid="${volumeid,,}"
   device=$(lsblk -d -O -J | jq -r --arg VID "$volumeid" '.blockdevices[] | select(.serial == $VID) | .name')
   device="${device,,}"
   if [[ -z "$device" ]]; then
      error "No device found for volume ID: $volumeid"
      return 1
   fi
   echo "/dev/$device"
}

# Core Logic
function validate_runtime(){
   [[ -z "${params[device]}" ]] && [[ -z "${params[volumeid]}" ]] && rerror "Missing param --volumeid or --device" && exit 1
   [[ -z "${params[label]}" ]] && rerror "Missing param --label" && exit 1
   [[ -z "${params[fs]}" ]] && rerror "Missing param --fs" && exit 1
   [[ -z "${params[mount]}" ]] && rerror "Missing param --mount" && exit 1
   ! valid_path "${params[mount]}" && rerror "Invalid path --mount provided: ${params[mount]}" && exit 1
   success "Validated runtime of ${0}!"
}

function create_filesystem(){
   [[ "${params[fs]^^}" =~ ^XFS ]] && sudo mkfs.xfs "${params[device],,}"
   [[ "${params[fs]^^}" =~ ^EXT ]] && sudo mkfs.ext4 "${params[device],,}"
}

function backup_fstab(){
   sudo cp /etc/fstab "/root/fstab.$(date +'%Y%m%d_%H%M')"
}

function patch_fstab(){
   if grep -q "$(device_uuid)" /etc/fstab || grep -q " ${params[mount],,} " /etc/fstab; then
      sed -i.bak "/$(device_uuid)/d" /etc/fstab
      sed -i.bak "\| ${params[mount],,} |d" /etc/fstab
   fi
   echo "UUID=$(device_uuid) ${params[mount],,} ${params[fs],,} defaults,noatime,nofail 0 0" | sudo tee -a /etc/fstab > /dev/null
}

function mount_fs(){
   mkdir -p "${params[mount],,}"
   mount UUID="$(device_uuid)" "${params[mount],,}"
   sudo systemctl daemon-reload
}

function enable_fstrim(){
    if command -v systemctl &> /dev/null; then
        echo -e "[Unit]\nDescription=Run fstrim on ${params[mount],,}\n\n[Service]\nExecStart=/sbin/fstrim ${params[mount],,}" | sudo tee "/etc/systemd/system/fstrim-${params[label],,}.service" > /dev/null
        echo -e "[Unit]\nDescription=Run fstrim-${params[label],,} daily\n\n[Timer]\nOnCalendar=daily\nPersistent=true\n\n[Install]\nWantedBy=timers.target" | sudo tee "/etc/systemd/system/fstrim-${params[label],,}.timer" > /dev/null

        systemctl daemon-reload
        systemctl enable "fstrim-${params[label],,}.timer"
        systemctl start "fstrim-${params[label],,}.timer"
    else
        if ! crontab -l | grep -q "fstrim ${params[mount],,}"; then
            { crontab -l; echo "0 2 * * * /sbin/fstrim ${params[mount],,}"; } | crontab -
        fi
    fi

}

# Main
function main(){
   app_title
   success "Welcome to ${0}!"

   info "Parsing arguments..."
   parse_arguments "$@"
   success "All arguments have been accepted!"

   info "Validating runtime..."
   validate_runtime
   success "Environment has been VALIDATED!"

   info "Creating filesystem..."
   create_filesystem
   success "Filesystem created!"

   info "Creating fstab Backup..."
   backup_fstab
   success "The fstab has been backed up to /root/fstab.bak."

   info "Patching fstab..."
   patch_fstab
   success "The fstab has been patched!"

   if [[ -z "${params[fstrim]}" ]]; then
      info "Enabling fstrim..."
      enable_fstrim
      success "New systemd has been added to routinely run the fstrim functionality against the EBS block volume."
   fi

   info "Mounting the filesystem..."
   mount_fs
   success "Mounted ${params[volumeid]} to ${params[mount]}!"
}

main "$@"

