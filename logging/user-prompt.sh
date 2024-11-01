#!/usr/bin/env bash
# shellcheck disable=SC2086,SC2116,SC2155

set -o errexit
set -o nounset
set -o pipefail

declare DESIRED_LOG_LEVEL
declare LOG_FILE
declare LOG_DIR
declare -A LOG_LEVELS
declare -A LOG_COLORS
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
    DESIRED_LOG_LEVEL="$(prompt_until_set "DEBUG|INFO|WARN|ERROR|FATAL" "Set the desired log level")"
    # prompt the user for
    read -rp "Set the desired path for this log: $(echo $'\n> ')" LOG_FILE
    # get directory of log file
    LOG_DIR="$(dirname ${LOG_FILE})"

    # create log directory if it doesn't exist
    if ! [[ -d "${LOG_DIR}" ]]; then
        mkdir --parents "${LOG_DIR}"
    fi
    # create log file if it doesn't exist
    if ! [[ -f "${LOG_FILE}" ]]; then
        touch "${LOG_FILE}"
    fi
    chmod 644 "${LOG_FILE}"

    LOG_LEVELS=(
        [DEBUG]=0
        [INFO]=1
        [WARN]=2
        [ERROR]=3
        [FATAL]=4
    )
    LOG_COLORS=(
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
        if [[ "${LOG_LEVELS[${log_level}]}" -ge "${LOG_LEVELS[${DESIRED_LOG_LEVEL}]}" ]]; then
            local timestamp="$(date '+%Y-%m-%d %H:%M:%S')" # YYYY-MM-DD HH:MM:SS
            local log_entry="[${timestamp}] [${log_level}]\t${log_message}"

            # output to console (with colors)
            echo -e "${LOG_COLORS[${log_level}]}${log_entry}${LOG_COLORS["RESET"]}"
            # output to file (without colors)
            echo -e "${log_entry}" >> "${LOG_FILE}"
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