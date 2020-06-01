#!/usr/bin/env bash
#
# This script is based on the template here:
#
#     https://gist.github.com/pcrockett/8e04641f8473081c3a93de744873f787
#
# It was copy/pasted here into this file and then modified extensively.
#
# Useful links when writing a script:
#
# Shellcheck: https://github.com/koalaman/shellcheck
# vscode-shellcheck: https://github.com/timonwong/vscode-shellcheck
#
# I stole many of my ideas here from:
#
# https://blog.yossarian.net/2020/01/23/Anybody-can-write-good-bash-with-a-little-effort
# https://dave.autonoma.ca/blog/2019/05/22/typesetting-markdown-part-1/
#

# https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -Eeuo pipefail

[[ "${BASH_VERSINFO[0]}" -lt 4 ]] && echo "Bash >= 4 required" && exit 1

readonly SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
readonly SCRIPT_NAME=$(basename "$0")
readonly DEPENDENCIES=(pandoc firefox)

function panic() {
    >&2 echo "Fatal: $*"
    exit 1
}

function installed() {
    command -v "$1" >/dev/null 2>&1
}

for dep in "${DEPENDENCIES[@]}"; do
    installed "${dep}" || panic "Missing '${dep}'"
done

function show_usage() {
    printf "Usage: %s [OPTION...]\n" "${SCRIPT_NAME}" >&2
    printf "  -o, --open\t\tOpen the HTML document after build\n" >&2
    printf "  -c, --clean\t\tClean up old built files\n" >&2
    printf "  -h, --help\t\tShow this help message then exit\n" >&2
}

function show_usage_and_exit() {
    show_usage
    exit 1
}

function is_set() {
    # Use this like so:
    #
    #     is_set "${VAR_NAME+x}" || show_usage_and_exit
    #
    # https://stackoverflow.com/a/13864829

    test ! -z "$1"
}

function parse_commandline() {

    while [ "$#" -gt "0" ]; do
        local consume=1

        case "$1" in
            -o|--open)
                ARG_OPEN="true"
            ;;
            -c|--clean)
                ARG_CLEAN="true"
            ;;
            -h|-\?|--help)
                ARG_HELP="true"
            ;;
            *)
                echo "Unrecognized argument: ${1}"
                show_usage_and_exit
            ;;
        esac

        shift ${consume}
    done
}

parse_commandline "$@"

if is_set "${ARG_HELP+x}"; then
    show_usage_and_exit
fi;

OUTPUT_DOCUMENT="${SCRIPT_DIR}/index.html"

if is_set "${ARG_CLEAN+x}"; then

    if is_set "${ARG_OPEN+x}"; then
        panic "--clean and --open arguments cannot be used together"
    fi

    if [ -f "${OUTPUT_DOCUMENT}" ]; then
        rm "${OUTPUT_DOCUMENT}"
    fi

    exit 0
fi

pandoc --self-contained --to html5 \
    --css "${SCRIPT_DIR}/style.css" \
    --output "${OUTPUT_DOCUMENT}" \
    "${SCRIPT_DIR}/index.md"

if is_set "${ARG_OPEN+x}"; then
    firefox "${OUTPUT_DOCUMENT}" &
fi
