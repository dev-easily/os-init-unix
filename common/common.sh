ROOT_DIR=$(cd "$(dirname "$0")"/../ && pwd)

function must_run_as_root() {
    if [ $(id -u) -ne 0 ]; then
        echo "Please run as root"
        exit 1
    fi
}

function must_run_as_non_root() {
    if [ $(id -u) -eq 0 ]; then
        echo "Please run as non-root"
        exit 1
    fi
}

function is_macos() {
  [[ "$(uname)" == "Darwin" ]]
}

function is_ubuntu() {
  [[ "$(uname)" == "Linux" ]] && lsb_release -a|grep Ubuntu
}

function is_fedora() {
  [[ "$(uname)" == "Linux" ]] && lsb_release -a|grep Fedora
}