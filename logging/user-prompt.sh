#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail

main() {
    local desired_log_level
    local log_file
    local log_dir
    local -A log_levels
    local -A log_colors
    init_log() {
        # promt the user until they input an acceptable string
        prompt_until_set() {
            local desired_input="${1}"  # desired input, seperated by "|"; e.g. "DEBUG|INFO|ERROR"
            local prompt_message="${2}" # message in the prompt without ${desired_input}
            local desired_variable      # variable that will be tested for input and then returned
            until ! [[ -z "${desired_variable:-}" ]] &&
                    [[ "${desired_variable^^}" =~ ^(${desired_input})$ ]]; do
                read -rp "${prompt_message} [${desired_input}]: $(echo $'\n> ')" desired_variable
            done
            echo "${desired_variable^^}"
        }

        # prompt the user for the desired log level
        desired_log_level="$(prompt_until_set "DEBUG|INFO|WARN|ERROR|FATAL" "Set the desired log level")"
        # prompt the user for
        read -rp "Set the desired path for this log: $(echo $'\n> ')" log_file
        # get directory of log file
        log_dir="$(dirname ${log_file})"

        # create log directory if it doesn't exist
        if ! [[ -d "${log_dir}" ]]; then
            mkdir --parents "${log_dir}"
        fi
        # create log file if it doesn't exist
        if ! [[ -f "${log_file}" ]]; then
            touch "${log_file}"
        fi
        chmod 644 "${log_file}"

        log_levels=(
            [DEBUG]=0
            [INFO]=1
            [WARN]=2
            [ERROR]=3
            [FATAL]=4
        )
        log_colors=(
            [DEBUG]="\e[1;97m"     # White
            [INFO]="\e[38;5;114m"  # Green
            [WARN]="\e[38;5;228m"  # Yellow
            [ERROR]="\e[38;5;203m" # Red
            [FATAL]="\e[38;5;99m"  # Purple
            [RESET]="\e[0m"        # Reset
        )

        log() {
            local log_level="${1}"
            local log_message="${2}"

            # check if this log level should be logged
            if [[ "${log_levels[${log_level}]}" -ge "${log_levels[${desired_log_level}]}" ]]; then
                local timestamp="$(date '+%Y-%m-%d %H:%M:%S')" # YYYY-MM-DD HH:MM:SS
                local log_entry="[${timestamp}] [${log_level}]\t${log_message}"

                # output to console (with colors)
                echo -e "${log_colors[${log_level}]}${log_entry}${log_colors["RESET"]}"
                # output to file (without colors)
                echo -e "${log_entry}" >> "${log_file}"
            fi
        }

        log_debug() {
            local message="${1}"
            log "DEBUG" "${message}"
        }
        log_info() {
            local message="${1}"
            log "INFO" "${message}"
        }
        log_warn() {
            local message="${1}"
            log "WARN" "${message}"
        }
        log_error() {
            local message="${1}"
            log "ERROR" "${message}"
        }
        log_fatal() {
            local message="${1}"
            log "FATAL" "${message}"
        }
    }
    init_log

    log_debug "test"
    log_info "test"
    log_warn "test"
    log_error "test"
    log_fatal "test"
}

main
