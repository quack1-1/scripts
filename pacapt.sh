#!/usr/bin/env sh
#
# Purpose: A wrapper for all Unix package managers

_print_duck_version() {
  cat <<_EOF_
duck version '3.0.5'


DISCLAIMER: THE WORKS ARE WITHOUT WARRANTY.
_EOF_
}

export PACAPT_VERSION='3.0.5'

_help() {
  cat <<'EOF'
NAME
  duck - Quack's package manager. A quick, synonymous package manager for all distributions!

SYNTAX

  $ duck <option(s)> <operation(s)> <package(s)>

BASIC OPTIONS

    -h or --help    print this help message
    -P              print supported operations
    -V              print version information

PACMAN STYLE OPERATIONS

  Query
    -Q              list all installed packages
    -Qc <package>   show package's changelog
    -Qe [<package>] only list explicitly installed packages
    -Qi <package>   print package status
    -Ql <package>   list package's files
    -Qm             list installed packages that aren't available
                    in any installation source
    -Qo <file>      query package that provides <file>
    -Qp <file>      query a package file (don't use package database)
    -Qs <package>   search for installed package

  Synchronize
    -S <package>    install package(s)
    -Sg             list groups
    -Sg <group>     list packages in group
    -Ss <package>   search for packages
    -Su             upgrade the system
    -Sy             update package database
    -Suy            update package database, then upgrade the system

  Remove / Clean up
    -R <packages>   remove some packages
    autoremove	    delete unused packages
    -Sccc           clean variant files.
                    (debian) See also http://dragula.viettug.org/blogs/646

  Upgrade
    -U              upgrade or add package from local file path (or remote uri)

OPTIONS

    -w              download packages but don't install them
    --noconfirm     don't wait for user's confirmation

EXAMPLES

  1. To install a package from Debian's backports repository
      $ duck -S foobar -t lenny-backports
      $ duck -S -- -t lenny-backports foobar

  2. To update package database and then update your system
      $ duck -Syu

  3. To download a package without installing it
      $ duck -Sw foobar


ENVIRONMENT

 DUCK_DEBUG

    This is useful for debugging purpose. The variable can be set to `auto`
    or any valid packager. For example, on `Debian` system the two following
    commands are the same and they will print out what the script would do:

       DUCK_DEBUG=auto pacman -Su
        DUCK_DEBUG=dpkg pacman -Su

NOTES

  When being executed on Arch-based system, the tool simply invokes
  the system package manager (`/usr/bin/pacman`).

  Though you can specify option by its own word, for example,
      $ duck -S -y -u

  it's always the best to combine them
      $ duck -Syu

EOF

}




_error() {
  echo >&2 ":: Error: $*"
  return 1
}

_warn() {
  echo >&2 ":: Warning: $*"
  return 0
}

_die() {
  echo >&2 ":: $*"
  exit 1
}

_debug() {
  if [ -n "${PACAPT_DEBUG:-}" ]; then
    >&2 echo ":: [debug] $*"
  fi
}

_not_implemented() {
  # shellcheck disable=2153
  echo >&2 "${_PACMAN}: '${_POPT}:${_SOPT}:${_TOPT}' operation is invalid or not implemented."
  return 1
}

_removing_is_dangerous() {
  echo >&2 "${_PACMAN}: removing with '$*' is too dangerous"
  return 1
}

_require_programs() {
  for cmd in "$@"; do
    if ! command -v "$cmd" >/dev/null; then
      _die "pacapt(${_PACMAN:-_init}) requires '$cmd' but the tool is not found."
    fi
  done
}

_issue2pacman() {
  local_pacman="$1"; shift

  # The following line is added by Daniel YC Lin to support SunOS.
  #
  #   [ `uname` = "$1" ] && _PACMAN="$_pacman" && return
  #
  # This is quite tricky and fast, however I don't think it works
  # on Linux/BSD systems. To avoid extra check, I slightly modify
  # the code to make sure it's only applicable on SunOS.
  #
  [ "$(uname)" = "SunOS" ] && _PACMAN="$local_pacman" && return

  $GREP -qis "$@" /etc/issue \
  && _PACMAN="$local_pacman" && return

  $GREP -qis "$@" /etc/os-release \
  && _PACMAN="$local_pacman" && return
}

_PACMAN_detect() {
  _PACMAN_found_from_script_name && return

  _issue2pacman sun_tools "SunOS" && return
  _issue2pacman pacman "Arch Linux" && return
  _issue2pacman dpkg "Debian GNU/Linux" && return
  _issue2pacman dpkg "Ubuntu" && return
  _issue2pacman cave "Exherbo Linux" && return
  _issue2pacman yum "CentOS" && return
  _issue2pacman yum "Red Hat" && return
  #
  # FIXME: The multiple package issue.
  #
  # On #63, Huy commented out this line. This is because new generation
  # of Fedora uses `dnf`, and `yum` becomes a legacy tool. On old Fedora
  # system, `yum` is still detectable by looking up `yum` binary.
  #
  # I'm not sure how to support this case easily. Let's wait, e.g, 5 years
  # from now to make `dnf` becomes a default? Oh no!
  #
  # And here why `pacman` is still smart. Debian has a set of tools.
  # Fedora has `yum` (and a set of add-ons). Now Fedora moves to `dnf`.
  # This means that a package manager is not a heart of a system ;)
  #
  # _issue2pacman yum "Fedora" && return
  _issue2pacman zypper "SUSE" && return
  _issue2pacman pkg_tools "OpenBSD" && return
  _issue2pacman pkg_tools "Bitrig" && return
  _issue2pacman apk "Alpine Linux" && return
  _issue2pacman opkg "OpenWrt" && return

  [ -z "$_PACMAN" ] || return

  # Prevent a loop when this script is installed on non-standard system
  if [ -x "/usr/bin/pacman" ]; then
    $GREP -q "_PACMAN_detect" '/usr/bin/pacman' >/dev/null 2>&1
    [ $? -ge 1 ] && _PACMAN="pacman" \
    && return
  fi

  if uname -a | "$GREP" -q Cygwin; then
    command -v "apt-cyg" >/dev/null && _PACMAN="apt_cyg" && return
  fi
  [ -x "/usr/bin/apt-get" ] && _PACMAN="dpkg" && return
  [ -x "/data/data/com.termux/files/usr/bin/apt-get" ] && _PACMAN="dpkg" && return
  [ -x "/usr/bin/cave" ] && _PACMAN="cave" && return
  [ -x "/usr/bin/dnf" ] && _PACMAN="dnf" && return
  [ -x "/usr/bin/yum" ] && _PACMAN="yum" && return
  [ -x "/opt/local/bin/port" ] && _PACMAN="macports" && return
  [ -x "/usr/bin/emerge" ] && _PACMAN="portage" && return
  [ -x "/usr/bin/zypper" ] && _PACMAN="zypper" && return
  [ -x "/usr/sbin/pkg" ] && _PACMAN="pkgng" && return
  # make sure pkg_add is after pkgng, FreeBSD base comes with it until converted
  [ -x "/usr/sbin/pkg_add" ] && _PACMAN="pkg_tools" && return
  [ -x "/usr/sbin/pkgadd" ] && _PACMAN="sun_tools" && return
  [ -x "/sbin/apk" ] && _PACMAN="apk" && return
  [ -x "/bin/opkg" ] && _PACMAN="opkg" && return
  [ -x "/usr/bin/tazpkg" ] && _PACMAN="tazpkg" && return
  [ -x "/usr/bin/swupd" ] && _PACMAN="swupd" && return

  command -v brew >/dev/null && _PACMAN="homebrew" && return

  return 1
}

_translate_w() {

  echo "$_EOPT" | $GREP -q ":w:" || return 0

  local_opt=
  local_ret=0

  case "$_PACMAN" in
  "dpkg")     local_opt="-d";;
  "cave")     local_opt="-f";;
  "dnf")      local_opt="--downloadonly";;
  "macports") local_opt="fetch";;
  "portage")  local_opt="--fetchonly";;
  "zypper")   local_opt="--download-only";;
  "pkgng")    local_opt="fetch";;
  "yum")      local_opt="--downloadonly";
    if ! rpm -q 'yum-downloadonly' >/dev/null 2>&1; then
      _error "'yum-downloadonly' package is required when '-w' is used."
      local_ret=1
    fi
    ;;
  "tazpkg")
    _error "$_PACMAN: Use '$_PACMAN get' to download and save packages to current directory."
    local_ret=1
    ;;
  "apk")      local_opt="fetch";;
  "opkg")     local_opt="--download-only";;
  *)
    local_opt=""
    local_ret=1

    _error "$_PACMAN: Option '-w' is not supported/implemented."
    ;;
  esac

  echo "$local_opt"
  return "$local_ret"
}

_translate_debug() {
  echo "$_EOPT" | $GREP -q ":v:" || return 0

  case "$_PACMAN" in
  "tazpkg")
    _error "$_PACMAN: Option '-v' (debug) is not supported/implemented by tazpkg"
    return 1
    ;;
  esac

  echo "-v"
}

_translate_noconfirm() {
  echo "$_EOPT" | $GREP -q ":noconfirm:" || return 0

  local_opt=
  local_ret=0

  case "$_PACMAN" in
  # FIXME: Update environment DEBIAN_FRONTEND=noninteractive
  # FIXME: There is also --force-yes for a stronger case
  "dpkg")   local_opt="--yes";;
  "dnf")    local_opt="--assumeyes";;
  "yum")    local_opt="--assumeyes";;
  # FIXME: pacman has 'assume-yes' and 'assume-no'
  # FIXME: zypper has better mode. Similar to dpkg (Debian).
  "zypper") local_opt="--no-confirm";;
  "pkgng")  local_opt="-y";;
  "tazpkg") local_opt="--auto";;
  "apk")    local_opt="";;
  *)
    local_opt=""
    local_ret=1
    _error "$_PACMAN: Option '--noconfirm' is not supported/implemented."
    ;;
  esac

  echo "$local_opt"
  return "$local_ret"
}

_translate_all() {
  local_args=""
  local_debug=
  local_noconfirm=

  local_debug="$(_translate_debug)" || return 1
  local_noconfirm="$(_translate_noconfirm)" || return 1
  local_args="$(_translate_w)" || return 1

  local_args="${local_args}${local_noconfirm:+ }${local_noconfirm}"
  local_args="${local_args}${local_debug:+ }${local_debug}"

  export _EOPT="${local_args# }"
}

_print_supported_operations() {
  local_pacman="$1"
  printf "pacapt(%s): available operations:" "$local_pacman"
  # shellcheck disable=2016
  $GREP -E "^(#_!_POSIX_# )?${local_pacman}_[^ \\t]+\\(\\)" "$0" \
  | $AWK -F '(' '{print $1}' \
  | sed -e "s/.*${local_pacman}_//g" \
  | while read -r O; do
      printf " %s" "$O"
    done
  echo
}

_quiet_field1() {
  if [ -z "${_TOPT}" ]; then
    cat
  else
    awk '{print $1}'
  fi
}

_string_nth() {
  local_idx="${1}"; shift
  local_args="${*}"

  local_args="${local_args}" local_idx="${local_idx}" \
  "$AWK" 'BEGIN{printf("%s",substr(ENVIRON["local_args"],ENVIRON["local_idx"],1))}'
}

_string_less_than() {
  a="${1}" b="${2}" "$AWK" 'BEGIN {exit !(ENVIRON["a"] < ENVIRON["b"]) }'
}


export _SUPPORTED_EXTERNALS="
  :conda
  :tlmgr
  :texlive
  :gem
  :npm
  :pip
"
readonly _SUPPORTED_EXTERNALS

_PACMAN_found_from_script_name() {
  local_tmp_name=
  local_pacman=

  local_tmp_name="${0}"
  # https://github.com/icy/pacapt/pull/161/files#r654800412
  case "$local_tmp_name" in
    *-*) : ;;
    *) return 1 ;;
  esac

  local_tmp_name="${local_tmp_name##*/}" # base name (remove everything before the last `/`)
  local_tmp_name="${local_tmp_name%.*}"  # remove extension if any (remove everything from the last `.`)
  local_pacman="${local_tmp_name##*-}"   # remove every thing before the last `-`

  if echo "$_SUPPORTED_EXTERNALS" \
    | "$GREP" -Eq -e ":${local_pacman}[[:space:]]*";
  then
    export _PACMAN="$local_pacman"
    return 0
  else
    export _PACMAN=""
    _die "Unable to guess non-system package manager ($local_pacman) from script name '$0'."
  fi
}



_apk_init() {
  :
}

apk_Q() {
  case "$_TOPT" in
  "")
    apk list --installed "$@"
    ;;
  "q")
    apk info
    ;;
  *)
    _not_implemented
    ;;
  esac
}

apk_Qe() {
  apk info | grep -x -f /etc/apk/world
}

apk_Qi() {
  if [ "$#" -eq 0 ]; then
    # shellcheck disable=SC2046
    apk info --all $(apk info)
    return
  fi

  # shellcheck disable=2086
  if apk info --installed $_TOPT "$@"; then
    # shellcheck disable=2086
    apk info --all $_TOPT "$@"
  else
    >&2 echo ":: Error: Package not installed: '${*}'"
  fi
}

apk_Ql() {
  if [ "$#" -eq 0 ]; then
    packages="$(apk info)"
  else
    packages="$*"
  fi

  for pkg in ${packages:-}; do
    apk info --contents "$pkg" \
    | awk -v pkg="$pkg" '/\// {printf("%s %s\n", pkg, $0)}'
  done \
  | {
    case $_TOPT in
    "q") awk '{print $NF}';;
    "")  cat ;;
    *)   _not_implemented ; exit 1;;
    esac
  }
}

apk_Qo() {
  if cmd="$(command -v -- "$@")"; then
    apk info --who-owns -- "$cmd"
  else
    apk info --who-owns -- "$@"
  fi
}

apk_Qs() {
  # shellcheck disable=2086
  apk list --installed $_TOPT "*${*}*"
}

apk_Qu() {
  apk version -l '<'
}

apk_R() {
  # shellcheck disable=2086
  apk del $_TOPT -- "$@"
}

apk_Rn() {
  # shellcheck disable=2086
  apk del --purge $_TOPT -- "$@"
}

apk_Rns() {
  # shellcheck disable=2086
  apk del --purge -r $_TOPT -- "$@"
}

apk_Rs() {
  # shellcheck disable=2086
  apk del -r $_TOPT -- "$@"
}

apk_S() {
  # shellcheck disable=2086
  case ${_EOPT} in
    # Download only
    ("fetch") shift
              apk fetch $_TOPT -- "$@" ;;
          (*) apk add   $_TOPT -- "$@" ;;
  esac
}

apk_Sc() {
  apk cache -v clean
}

apk_Scc() {
  rm -rf /var/cache/apk/*
}

apk_Sccc() {
  apk_Scc
}

apk_Si() {
  # shellcheck disable=2086
  apk info $_TOPT "$@"
}

apk_Sii() {
  apk info -r -- "$@"
}

apk_Sl() {
  apk search -v -- "$@"
}

apk_Ss() {
  apk_Sl "$@"
}

apk_Su() {
  apk upgrade
}

apk_Suy() {
  if [ "$#" -gt 0 ]; then
    apk add -U -u -- "$@"
  else
    apk upgrade -U -a
  fi
}

apk_Sy() {
  apk update
}

apk_U() {
  # shellcheck disable=2086
  apk add --allow-untrusted $_TOPT -- "$@"
}


_apt_cyg_init() {
  :
}

apt_cyg_Ss() {
  apt-cyg search "$@"
}

apt_cyg_S() {
  apt-cyg install "$@"
}

apt_cyg_Sy() {
  apt-cyg update "$@"
}

apt_cyg_Q() {
  apt-cyg list "$@"
}

apt_cyg_Qi() {
  apt-cyg show "$@"
}

apt_cyg_Ql() {
  for pkg in "$@"; do
    if [ "$_TOPT" = "q" ]; then
      apt-cyg listfiles "$pkg"
    else
       apt-cyg listfiles "$pkg" \
       | pkg="$pkg" \
         awk '{printf("%s %s\n", ENVIRON["pkg"], $0)}'
    fi
  done
}

apt_cyg_R() {
  apt-cyg remove "$@"
}
#_!_POSIX_# 
#_!_POSIX_# 
#_!_POSIX_# 
#_!_POSIX_# _cave_init() {
#_!_POSIX_#   shopt -u globstar
#_!_POSIX_# }
#_!_POSIX_# 
#_!_POSIX_# cave_Q() {
#_!_POSIX_#   if [ "$_TOPT" = "q" ]; then
#_!_POSIX_#     cave show -f "${@:-world}" \
#_!_POSIX_#     | grep -v '^$'
#_!_POSIX_#   else
#_!_POSIX_#     cave show -f "${@:-world}"
#_!_POSIX_#   fi
#_!_POSIX_# }
#_!_POSIX_# 
#_!_POSIX_# cave_Qi() {
#_!_POSIX_#   cave show "$@"
#_!_POSIX_# }
#_!_POSIX_# 
#_!_POSIX_# cave_Ql() {
#_!_POSIX_#   if [ $# -ge 1 ]; then
#_!_POSIX_#     cave contents "$@"
#_!_POSIX_#     return
#_!_POSIX_#   fi
#_!_POSIX_# 
#_!_POSIX_#   cave show -f "${@:-world}" \
#_!_POSIX_#   | grep -v '^$' \
#_!_POSIX_#   | while read -r _pkg; do
#_!_POSIX_#       if [ "$_TOPT" = "q" ]; then
#_!_POSIX_#         cave --color no contents "$_pkg"
#_!_POSIX_#       else
#_!_POSIX_#         cave contents "$_pkg"
#_!_POSIX_#       fi
#_!_POSIX_#     done
#_!_POSIX_# }
#_!_POSIX_# 
#_!_POSIX_# cave_Qo() {
#_!_POSIX_#   if cmd="$(command -v -- "$@")"; then
#_!_POSIX_#     cave owner "$cmd"
#_!_POSIX_#   else
#_!_POSIX_#     cave owner "$@"
#_!_POSIX_#   fi
#_!_POSIX_# }
#_!_POSIX_# 
#_!_POSIX_# cave_Qp() {
#_!_POSIX_#   _not_implemented
#_!_POSIX_# }
#_!_POSIX_# 
#_!_POSIX_# cave_Qu() {
#_!_POSIX_#   if [ $# -eq 0 ];then
#_!_POSIX_#     cave resolve -c world \
#_!_POSIX_#     | grep '^u.*' \
#_!_POSIX_#     | while read -r _pkg; do
#_!_POSIX_#         echo "$_pkg" | cut -d'u' -f2-
#_!_POSIX_#       done
#_!_POSIX_#   else
#_!_POSIX_#     cave resolve -c world \
#_!_POSIX_#     | grep '^u.*' \
#_!_POSIX_#     | grep -- "$@"
#_!_POSIX_#   fi
#_!_POSIX_# }
#_!_POSIX_# 
#_!_POSIX_# cave_Qs() {
#_!_POSIX_#   cave show -f world | grep -- "$@"
#_!_POSIX_# }
#_!_POSIX_# 
#_!_POSIX_# cave_Rs() {
#_!_POSIX_#   if [ -z "$_TOPT" ]; then
#_!_POSIX_#     cave uninstall -r "$@" \
#_!_POSIX_#     && echo "Control-C to stop uninstalling..." \
#_!_POSIX_#     && sleep 2s \
#_!_POSIX_#     && cave uninstall -xr "$@"
#_!_POSIX_#   else
#_!_POSIX_#     cave purge "$@" \
#_!_POSIX_#     && echo "Control-C to stop uninstalling (+ dependencies)..." \
#_!_POSIX_#     && sleep 2s \
#_!_POSIX_#     && cave purge -x "$@"
#_!_POSIX_#   fi
#_!_POSIX_# }
#_!_POSIX_# 
#_!_POSIX_# cave_Rn() {
#_!_POSIX_#   _not_implemented
#_!_POSIX_# }
#_!_POSIX_# 
#_!_POSIX_# cave_Rns() {
#_!_POSIX_#   _not_implemented
#_!_POSIX_# }
#_!_POSIX_# 
#_!_POSIX_# cave_R() {
#_!_POSIX_#   cave uninstall "$@" \
#_!_POSIX_#   && echo "Control-C to stop uninstalling..." \
#_!_POSIX_#   && sleep 2s \
#_!_POSIX_#   && cave uninstall -x "$@"
#_!_POSIX_# }
#_!_POSIX_# 
#_!_POSIX_# cave_Si() {
#_!_POSIX_#   cave show "$@"
#_!_POSIX_# }
#_!_POSIX_# 
#_!_POSIX_# cave_Suy() {
#_!_POSIX_#   cave sync && cave resolve -c "${@:-world}" \
#_!_POSIX_#   && echo "Control-C to stop upgrading..." \
#_!_POSIX_#   && sleep 2s \
#_!_POSIX_#   && cave resolve -cx "${@:-world}"
#_!_POSIX_# }
#_!_POSIX_# 
#_!_POSIX_# cave_Su() {
#_!_POSIX_#   cave resolve -c "$@" \
#_!_POSIX_#   && echo "Control-C to stop upgrading..." \
#_!_POSIX_#   && sleep 2s \
#_!_POSIX_#   && cave resolve -cx "$@"
#_!_POSIX_# }
#_!_POSIX_# 
#_!_POSIX_# cave_Sy() {
#_!_POSIX_#   cave sync "$@"
#_!_POSIX_# }
#_!_POSIX_# 
#_!_POSIX_# cave_Ss() {
#_!_POSIX_#   cave search "$@"
#_!_POSIX_# }
#_!_POSIX_# 
#_!_POSIX_# cave_Sc() {
#_!_POSIX_#   cave fix-cache "$@"
#_!_POSIX_# }
#_!_POSIX_# 
#_!_POSIX_# cave_Scc() {
#_!_POSIX_#   cave fix-cache "$@"
#_!_POSIX_# }
#_!_POSIX_# 
#_!_POSIX_# cave_Sccc() {
#_!_POSIX_#   #rm -fv /var/cache/paludis/*
#_!_POSIX_#   _not_implemented
#_!_POSIX_# }
#_!_POSIX_# 
#_!_POSIX_# cave_S() {
#_!_POSIX_#   # shellcheck disable=SC2086
#_!_POSIX_#   cave resolve $_TOPT "$@" \
#_!_POSIX_#   && echo "Control-C to stop installing..." \
#_!_POSIX_#   && sleep 2s \
#_!_POSIX_#   && cave resolve -x $_TOPT "$@"
#_!_POSIX_# }
#_!_POSIX_# 
#_!_POSIX_# cave_U() {
#_!_POSIX_#   _not_implemented
#_!_POSIX_# }



_conda_init() {
  :
}

conda_Q() {
  if [ $# -gt 0 ]; then
    conda list "$(python -c 'import sys; print("^" + "|".join(sys.argv[1:]) + "$")' "$@")"
  else
    conda list
  fi
}

conda_Qo() {
  conda package --which "$@"
}

conda_R() {
  conda remove "$@"
}

conda_S() {
  conda install "$@"
}

conda_Sc() {
  conda clean --all "$@"
}

conda_Si() {
  conda search "$@" --info
}

conda_Ss() {
  conda search "*${*}*"
}

conda_Suy() {
  conda update --all "$@"
}



_dnf_init() {
  :
}

dnf_S() {
  # shellcheck disable=SC2086
  dnf install $_TOPT "$@"
}

dnf_Sc() {
  dnf clean expire-cache "$@"
}

dnf_Scc() {
  dnf clean packages "$@"
}

dnf_Sccc() {
  dnf clean all "$@"
}

dnf_Si() {
  dnf repoquery --requires --resolve "$@"
}

dnf_Sii() {
  dnf repoquery --installed --whatrequires "$@"
}

dnf_Sg() {
  if [ $# -gt 0 ]; then
    dnf group info "$@"
  else
    dnf group list
  fi
}

dnf_Sl() {
  dnf list available "$@"
}

dnf_Ss() {
  dnf search "$@"
}

dnf_Su() {
  dnf upgrade "$@"
}

dnf_Suy() {
  dnf upgrade "$@"
}

dnf_Sy() {
  dnf clean expire-cache && dnf check-update
}

dnf_Q() {
  if [ "$_TOPT" = "q" ]; then
    rpm -qa --qf "%{NAME}\\n"
  elif [ -z "$_TOPT" ]; then
    rpm -qa --qf "%{NAME} %{VERSION}\\n"
  else
    _not_implemented
  fi
}

dnf_Qc() {
  rpm -q --changelog "$@"
}

dnf_Qe() {
  dnf repoquery --userinstalled "$@"
}

dnf_Qi() {
  dnf info --installed "$@" && dnf repoquery --deplist "$@"
}

dnf_Ql() {
  rpm -ql "$@"
}

dnf_Qm() {
  dnf list extras
}

dnf_Qo() {
  if cmd="$(command -v -- "$@")"; then
    rpm -qf "$cmd"
  else
    rpm -qf "$@"
  fi
}

dnf_Qp() {
  rpm -qp "$@"
}

dnf_Qs() {
  rpm -qa "*${*}*"
}

dnf_Qu() {
  dnf list updates "$@"
}

dnf_R() {
  dnf remove "$@"
}

dnf_U() {
  dnf install "$@"
}



_dpkg_init() {
  :
}

dpkg_Q() {
  if [ "$_TOPT" = "q" ]; then
    dpkg -l \
    | grep -E '^[hi]i' \
    | awk '{print $2}'
  elif [ -z "$_TOPT" ]; then
    dpkg -l "$@" \
    | grep -E '^[hi]i'
  else
    _not_implemented
  fi
}

dpkg_Qc() {
  apt-get changelog "$@"
}

dpkg_Qi() {
  dpkg-query -s "$@"
}

dpkg_Qe() {
  apt-mark showmanual "$@"
}

dpkg_Qk() {
  _require_programs debsums
  debsums "$@"
}

dpkg_Ql() {
  if [ $# -ge 1 ]; then
    dpkg-query -L "$@"
    return
  fi

  dpkg -l \
  | grep -E '^[hi]i' \
  | awk '{print $2}' \
  | while read -r _pkg; do
      if [ "$_TOPT" = "q" ]; then
        dpkg-query -L "$_pkg"
      else
        dpkg-query -L "$_pkg" \
        | while read -r _line; do
            echo "$_pkg $_line"
          done
      fi
    done
}

dpkg_Qo() {
  if cmd="$(command -v -- "$@")"; then
    dpkg-query -S "$cmd"
  else
    dpkg-query -S "$@"
  fi
}

dpkg_Qp() {
  dpkg-deb -I "$@"
}

dpkg_Qu() {
  apt-fast upgrade --trivial-only "$@"
}

dpkg_Qs() {
  # dpkg >= 1.16.2 dpkg-query -W -f='${db:Status-Abbrev} ${binary:Package}\t${Version}\t${binary:Summary}\n'
  dpkg-query -W -f='${Status} ${Package}\t${Version}\t${Description}\n' \
  | grep -E '^((hold)|(install)|(deinstall))' \
  | sed -r -e 's#^(\w+ ){3}##g' \
  | grep -Ei "${@:-.}" \
  | _quiet_field1
}

dpkg_Rs() {
  if [ -z "$_TOPT" ]; then
    apt-get autoremove "$@"
  else
    _not_implemented
  fi
}

dpkg_Rn() {
  apt-fast purge "$@"
}

dpkg_Rns() {
  apt-fast --purge autoremove "$@"
}

dpkg_R() {
  apt-fast remove "$@"
}

dpkg_Sg() {
  _require_programs tasksel
  
  if [ $# -gt 0 ]; then
    tasksel --task-packages "$@"
  else
    tasksel --list-task
  fi
}

dpkg_Si() {
  apt-cache show "$@"
}

dpkg_Suy() {
  apt-fast update \
  && apt-fast upgrade "$@" \
  && apt-fast dist-upgrade "$@"
}

dpkg_Su() {
  apt-fast upgrade "$@" \
  && apt-fast dist-upgrade "$@"
}


dpkg_Sy() {
  apt-fast update "$@"
}

dpkg_Ss() {
  apt-cache search "${@:-.}" \
  | while read -r name _ desc; do
      if ! dpkg-query -W "$name" > /dev/null 2>&1; then
        printf "package/%s \n    %s\n" \
          "$name" "$desc"
      else
        dpkg-query -W -f='package/${binary:Package} ${Version}\n    ${binary:Summary}\n' "$name"
      fi
  done
}

dpkg_Sc() {
  apt-fast clean "$@"
}

dpkg_Scc() {
  apt-fast autoclean "$@"
}

dpkg_S() {
  # shellcheck disable=SC2086
  apt-fast install $_TOPT "$@"
}

dpkg_U() {
  dpkg -i "$@"
}

dpkg_Sii() {
  apt-cache rdepends "$@"
}

dpkg_Sccc() {
  rm -fv /var/cache/apt/*.bin
  rm -fv /var/cache/apt/archives/*.*
  rm -fv /var/lib/apt/lists/*.*
  apt-fast autoclean
}



_homebrew_init() {
  :
}

homebrew_Qi() {
  brew info "$@"
}

homebrew_Ql() {
  local_casks=
  local_forumlas=

  if [ $# -eq 0 ]; then
    local_casks="$(brew list --casks)"
    local_forumlas="$(brew list --formula)"
  else
    # FIXME: this awk is not perfect!
    local_casks="$(brew list --casks | LIST="$*" awk '$0 ~ ENVIRON["LIST"]')"
    local_forumlas="$(brew list --formula | LIST="$*" awk '$0 ~ ENVIRON["LIST"]')"
  fi

  if [ -z "$_TOPT" ]; then
    for package in $local_casks; do
      brew list --cask "$package" \
      | grep ^/ \
      | PACKAGE="$package" awk '{printf("%s %s\n", ENVIRON["PACKAGE"], $0)}'
    done
    for package in $local_forumlas; do
      brew list --formula "$package" \
      | PACKAGE="$package" awk '{printf("%s %s\n", ENVIRON["PACKAGE"], $0)}'
    done
  elif [ "$_TOPT" = "q" ]; then
    for package in $local_casks; do
      brew list --cask "$package" \
      | grep ^/
    done
    for package in $local_forumlas; do
      brew list --formula "$package"
    done
  fi
}

homebrew_Qs() {
  if [ -z "$_TOPT" ]; then
    local_flags="--versions"
  else
    local_flags=""
  fi
  # shellcheck disable=SC2086
  brew list $local_flags | grep "${@:-.}"
}


homebrew_Qc() {
  brew log "$@"
}

homebrew_Qu() {
  brew outdated "$@"
}

homebrew_Q() {
  if [ -z "$_TOPT" ]; then
    local_flags="--versions"
  else
    local_flags=""
  fi
  # shellcheck disable=SC2086
  brew list $local_flags --formula "$@"
  # shellcheck disable=SC2086
  brew list $local_flags --cask "$@"
}


homebrew_R() {
  brew remove "$@"
}

homebrew_Si() {
  brew info "$@"
}

homebrew_Suy() {
  brew update \
  && brew upgrade "$@"
}

homebrew_Su() {
  brew upgrade "$@"
}

homebrew_Sy() {
  brew update "$@"
}

homebrew_Ss() {
  brew search "$@"
}

homebrew_Sc() {
  brew cleanup "$@"
}

homebrew_Scc() {
  brew cleanup -s "$@"
}

homebrew_Sccc() {
  # See more discussion in
  #   https://github.com/icy/pacapt/issues/47
  local_dcache="$(brew --cache)"
  case "$local_dcache" in
  ""|"/"|" ")
    _error "pacapt(homebrew_Sccc): Unable to delete '$local_dcache'."
    ;;

  *)
    # FIXME: This can be wrong. But it's an easy way
    # FIXME: to avoid some warning from #shellcheck.
    # FIXME: Please note that, $_dcache is not empty now.
    rm -rf "${local_dcache:-/x/x/x/x/x/x/x/x/x/x/x//x/x/x/x/x/}/"
    ;;
  esac
}

homebrew_S() {
  # shellcheck disable=SC2086
  2>&1 brew install $_TOPT "$@" \
  | awk '{print; if ($0 ~ /brew cask install/) { exit(126); }}'
  if [ "${?}" = 126 ]; then
    _warn "Failed to install package, now trying with 'brew cask' as suggested..."
    # shellcheck disable=SC2086
    brew cask install $_TOPT "$@"
  fi
}



_macports_init() {
  :
}

macports_Ql() {
  port contents "$@"
}

macports_Qo() {
  if cmd="$(command -v -- "$@")"; then
    port provides "$cmd"
  else
    port provides "$@"
  fi
}

macports_Qc() {
  port log "$@"
}

macports_Qu() {
  port outdated "$@"
}

macports_Rs() {
  if [ -z "$_TOPT" ]; then
    port uninstall --follow-dependencies "$@"
  else
    _not_implemented
  fi
}

macports_R() {
  port uninstall "$@"
}

macports_Si() {
  port info "$@"
}

macports_Suy() {
  port selfupdate \
  && port upgrade outdated "$@"
}

macports_Su() {
  port upgrade outdate "$@"
}

macports_Sy() {
  port selfupdate "$@"
}

macports_Ss() {
  port search "$@"
}

macports_Sc() {
  port clean --all inactive "$@"
}

macports_Scc() {
  port clean --all installed "$@"
}

macports_S() {
  if [ "$_TOPT" = "fetch" ]; then
    port patch "$@"
  else
    port install "$@"
  fi
}



_opkg_init() {
  :
}

opkg_Sy() {
  opkg update
}

opkg_Q() {
  # shellcheck disable=SC2016
  case "$_TOPT" in
  "q")
    opkg list-installed "$@" | "$AWK" '{print $1}'
    ;;
  "")
    opkg list-installed "$@"
    ;;
  *)
    _not_implemented
    ;;
  esac
}

opkg_Qi() {
  for  pkg in $(opkg__get_local_pkgs "$@"); do
    opkg info "$pkg"
  done
}

opkg__get_local_pkgs() {
  if [ "$#" -eq 0 ]; then
    # shellcheck disable=SC2016
    opkg list-installed | "$AWK" '{print $1}'
  else
    # `opkg status` returns empty if package is not installed/removed.
    # shellcheck disable=SC2016
    for pkg in "$@"; do
      opkg status "$pkg"
    done \
    | "$AWK" '/^Package: / {print $NF}'
  fi
}

opkg_Ql() {
  for pkg in $(opkg__get_local_pkgs "$@"); do
    # shellcheck disable=SC2016
    opkg files "$pkg" \
    | PKG="$pkg" "$AWK" \
        '{ if (NR>1) {printf("%s %s\n", ENVIRON["PKG"], $0)} }'
  done
}

opkg_Qo() {
  if cmd="$(command -v -- "$@")"; then
    opkg search "$cmd"
  else
    opkg search "$@"
  fi
}

opkg_Qs() {
  if command -v sort >/dev/null; then
    local_filter="sort -u"
  else
    local_filter="cat"
  fi

  # FIXME: opkg doesn't work with wildcard by default.
  case "$@" in
  *\**) local_pattern="$*" ;;
  *)    local_pattern="*${*}*" ;;
  esac

  opkg search "$local_pattern" \
  | ${local_filter} \
  | _quiet_field1
}

opkg_Qu() {
  opkg list-upgradable
}

opkg_R() {
  opkg remove "$@"
}

opkg_S() {
  opkg install "$@"
}

opkg_Si() {
  # shellcheck disable=2086
  opkg list $_TOPT "$@"
}

opkg_Sii() {
  # shellcheck disable=2086
  opkg list $_TOPT "$@"
  opkg whatdepends "$@"
}

opkg_Ss() {
  opkg list "$@"
}

opkg_Su() {
  opkg upgrade "$@"
}

opkg_U() {
  opkg install "$@"
}



_pkgng_init() {
  :
}

pkgng_Qi() {
  pkg info "$@"
}

pkgng_Ql() {
  pkg info -l "$@"
}

pkgng_Qo() {
  if cmd="$(command -v -- "$@")"; then
    pkg which "$cmd"
  else
    pkg which "$@"
  fi
}

pkgng_Qp() {
  pkg query -F "$@" '%n %v'
}

pkgng_Qu() {
  pkg upgrade -n "$@"
}

pkgng_Q() {
  if [ "$_TOPT" = "q" ]; then
    pkg query '%n' "$@"
  elif [ -z "$_TOPT" ]; then
    pkg query '%n %v' "$@"
  else
    _not_implemented
  fi
}

pkgng_Rs() {
  if [ -z "$_TOPT" ]; then
    pkg remove "$@"
    pkg autoremove
  else
    _not_implemented
  fi
}

pkgng_R() {
  pkg remove "$@"
}

pkgng_Si() {
  pkg search -S name -ef "$@"
}

pkgng_Suy() {
  pkg upgrade "$@"
}

pkgng_Su() {
  pkg upgrade -U "$@"
}

pkgng_Sy() {
  pkg update "$@"
}

pkgng_Ss() {
  pkg search "$@"
}

pkgng_Sc() {
  pkg clean "$@"
}

pkgng_Scc() {
  pkg clean -a "$@"
}

pkgng_S() {
  # shellcheck disable=SC2153
  if [ "$_EOPT" = "fetch" ]; then
    pkg fetch "$@"
  else
    pkg install "$@"
  fi
}



_pkg_tools_init() {
  :
}

pkg_tools_Qi() {
  # disable searching mirrors for packages
  export PKG_PATH=
  pkg_info "$@"
}

pkg_tools_Ql() {
  export PKG_PATH=
  pkg_info -L "$@"
}

pkg_tools_Qo() {
  export PKG_PATH=
  if cmd="$(command -v -- "$@")"; then
    pkg_info -E "$cmd"
  else
    pkg_info -E "$@"
  fi
}

pkg_tools_Qp() {
  _not_implemented
}

pkg_tools_Qu() {
  export PKG_PATH=
  pkg_add -u "$@"
}

pkg_tools_Q() {
  export PKG_PATH=
  # the dash after the pkg name is so we don't catch partial matches
  # because all packages in openbsd have the format 'pkgname-pkgver'
  if [ "$_TOPT" = "q" ] && [ -n "$*" ]; then
    pkg_info -q | grep "^${*}-"
  elif [ "$_TOPT" = "q" ] && [ -z "$*" ];then
    pkg_info -q
  elif [ "$_TOPT" = "" ] && [ -n "$*" ]; then
    pkg_info | grep "^${*}-"
  elif [ "$_TOPT" = "" ] && [ -z "$*" ];then
    pkg_info
  else
    _not_implemented
  fi
}

pkg_tools_Rs() {
  if [ -z "$_TOPT" ]; then
    pkg_delete -D dependencies "$@"
  else
    _not_implemented
  fi
}

pkg_tools_Rn() {
  if [ -z "$_TOPT" ];then
    pkg_delete -c "$@"
  else
    _not_implemented
  fi
}

pkg_tools_Rns() {
  _not_implemented
}

pkg_tools_R() {
  pkg_delete "$@"
}

pkg_tools_Si() {
  pkg_info "$@"
}

pkg_tools_Sl() {
  pkg_info -L "$@"
}

pkg_tools_Suy() {
  # pkg_tools doesn't really have any concept of a database
  # there's actually not really any database to update, so
  # this function is mostly just for convenience since on arch
  # doing -Su is normally a bad thing to do since it's a partial upgrade

  pkg_tools_Su "$@"
}

pkg_tools_Su() {
  pkg_add -u "$@"
}

pkg_tools_Sy() {
  _not_implemented
}

pkg_tools_Ss() {
  if [ -z "$*" ];then
    _not_implemented
  else
    pkg_info -Q "$@"
  fi
}

pkg_tools_Sc() {
  # by default no cache directory is used
  if [ -z "$PKG_CACHE" ];then
    echo "You have no cache directory set, set \$PKG_CACHE for a cache directory."
  elif [ ! -d "$PKG_CACHE" ];then
    echo "You have a cache directory set, but it does not exist. Create \"$PKG_CACHE\"."
  else
    _removing_is_dangerous "rm -rf $PKG_CACHE/*"
  fi
}

pkg_tools_Scc() {
  _not_implemented
}

pkg_tools_S() {
  pkg_add "$@"
}



_portage_init() {
  :
}

portage_Qi() {
  emerge --info "$@"
}

portage_Ql() {
  if [ -x '/usr/bin/qlist' ]; then
    qlist "$@"
  elif [ -x '/usr/bin/equery' ]; then
    equery files "$@"
  else
    _error "'portage-utils' or 'gentoolkit' package is required to perform this operation."
  fi
}

portage_Qo() {
  if [ -x '/usr/bin/equery' ]; then
    if cmd="$(command -v -- "$@")"; then
      equery belongs "$cmd"
    else
      equery belongs "$@"
    fi
  else
    _error "'gentoolkit' package is required to perform this operation."
  fi
}

portage_Qc() {
  emerge -p --changelog "$@"
}

portage_Qu() {
  emerge -uvN "$@"
}

portage_Q() {
  if [ -z "$_TOPT" ]; then
    if [ -x '/usr/bin/eix' ]; then
      eix -I "$@"
    elif [ -x '/usr/bin/equery' ]; then
      equery list -i "$@"
    else
      LS_COLORS="never" \
      ls -1 -d /var/db/pkg/*/*
    fi
  else
    _not_implemented
  fi
}

portage_Rs() {
  if [ -z "$_TOPT" ]; then
    emerge --depclean world "$@"
  else
    _not_implemented
  fi
}

portage_R() {
  emerge --depclean "@"
}

portage_Si() {
  emerge --info "$@"
}

portage_Suy() {
  if [ -x '/usr/bin/layman' ]; then
    layman --sync-all \
    && emerge --sync \
    && emerge -auND world "$@"
  else
    emerge --sync \
    && emerge -uND world "$@"
  fi
}

portage_Su() {
  emerge -uND world "$@"
}

portage_Sy() {
  if [ -x "/usr/bin/layman" ]; then
    layman --sync-all \
    && emerge --sync "$@"
  else
    emerge --sync "$@"
  fi
}

portage_Ss() {
  if [ -x "/usr/bin/eix" ]; then
    eix "$@"
  else
    emerge --search "$@"
  fi
}

portage_Sc() {
  if [ -x "/usr/bin/eclean-dist" ]; then
    eclean-dist -d -t1m -s50 -f "$@"
  else
    _error "'gentoolkit' package is required to perform this operation."
  fi
}

portage_Scc() {
  if [ -x "/usr/bin/eclean" ]; then
    eclean -i distfiles "$@"
  else
    _error "'gentoolkit' package is required to perform this operation."
  fi
}

portage_Sccc() {
  rm -fv /usr/portage/distfiles/*.*
}

portage_S() {
  emerge "$@"
}



_sun_tools_init() {
  # The purpose of `if` is to make sure this function
  # can be invoked on other system (Linux, BSD).
  if [ "$(uname)" = "SunOS" ]; then
    export GREP=/usr/xpg4/bin/grep
    export AWK=nawk
    return 0
  fi
  return 1
}

sun_tools_Qi() {
  pkginfo -l "$@"
}

sun_tools_Ql() {
  pkginfo -l "$@"
}

sun_tools_Qo() {
  if cmd="$(command -v -- "$@")"; then
    $GREP "$cmd" /var/sadm/install/contents
  else
    $GREP "$@" /var/sadm/install/contents
  fi
}

sun_tools_Qs() {
  pkginfo | $GREP -i "$@"
}

sun_tools_Q() {
  # the dash after the pkg name is so we don't catch partial matches
  # because all packages in openbsd have the format 'pkgname-pkgver'
  if [ "$_TOPT" = "q" ] && [ -n "$*" ]; then
    pkginfo | $GREP "$@"
  elif [ "$_TOPT" = "q" ] && [ -z "$*" ]; then
    pkginfo
  else
    pkginfo "$@"
  fi
}

sun_tools_R() {
  pkgrm "$@"
}

sun_tools_U() {
  pkgadd "$@"
}



_swupd_init() {
  :
}

swupd_Q() {
  swupd bundle-list "$@"
}

swupd_Qi() {
  swupd bundle-info "$@"
}

swupd_Qk() {
  swupd verify "$@"
}

swupd_Qo() {
  if cmd="$(command -v -- "$@")"; then
    swupd search "$cmd"
  else
    swupd search "$@"
  fi
}

swupd_Qs() {
  swupd search "$@"
}

swupd_R() {
  swupd bundle-remove "$@"
}

swupd_Sc() {
  swupd clean "$@"
}

swupd_Scc() {
  swupd clean --all "$@"
}

swupd_Suy() {
  swupd update
}

swupd_Su() {
  swupd update
}

swupd_Sy() {
  swupd update
}

swupd_Ss() {
  swupd search "$@"
}

swupd_S() {
  swupd bundle-add "$@"
}


_tazpkg_init() {
  :
}

tazpkg_Q() {
  if [ "$_TOPT" = "q" ]; then
    tazpkg list "$@" \
    | awk '{ if (NF == 2 || NF == 3) { print $1; }}'
  elif [ -z "$_TOPT" ]; then
    tazpkg list "$@"
  else
    _not_implemented
  fi
}

tazpkg_Qi() {
  tazpkg info "$@"
}

tazpkg_Ql() {
  if [ "$#" -eq 0 ]; then
    _not_implemented
    return
  fi

  if [ "$_TOPT" = "q" ]; then
    {
      tazpkg list-files "$@"
      tazpkg list-config "$@"
    } \
    | grep "^/"
  else
    tazpkg list-files "$@"
    tazpkg list-config "$@"
  fi
}

tazpkg_Sy() {
  tazpkg recharge
}

tazpkg_Su() {
  tazpkg up
}

tazpkg_Suy() {
  tazpkg_Sy \
  && tazpkg_Su
}

tazpkg_S() {
  local_forced=""

  if echo "$*" | grep -qs -- "--forced"; then
    local_forced="--forced"
  fi

  while [ $# -gt 0 ]; do
    if [ "$1" = "--forced" ]; then
      local_forced="--forced"
      shift
      continue
    fi

    tazpkg get-install "$1" $local_forced
    shift
  done
}

tazpkg_R() {
  local_auto=""

  if echo "*" | grep -sq -- "--auto"; then
    local_auto="--auto"
  fi

  while [ $# -ge 1 ]; do
    if [ "$1" = "--auto" ]; then
      local_auto="--auto"
      shift
      continue
    fi

    tazpkg remove "$1" $local_auto
    shift
  done
}

tazpkg_Sc() {
  tazpkg clean-cache
}

tazpkg_Scc() {
  tazpkg clean-cache
  cd /var/lib/tazpkg/ \
  && {
    rm -fv \
      ./*.bak \
      ID \
      packages.* \
      files.list.*
  }
}

tazpkg_Ss() {
  tazpkg search "$@"
}

tazpkg_Qo() {
  if cmd="$(command -v -- "$@")"; then
    tazpkg search-pkgname "$cmd"
  else
    tazpkg search-pkgname "$@"
  fi
}

tazpkg_U() {
  local_forced=""

  if echo "*" | grep -sq -- "--forced"; then
    local_forced="--forced"
  fi

  while [ $# -ge 1 ]; do
    if [ "$1" = "--forced" ]; then
      local_forced="--forced"
      shift
      continue
    fi

    tazpkg install "$1" $local_forced
    shift
  done
}



_tlmgr_init() {
  :
}

tlmgr_Qi() {
  tlmgr info --only-installed "$@"
}

tlmgr_Qk() {
  tlmgr check files
}

tlmgr_Ql() {
  tlmgr info --only-installed --list "$@"
}

tlmgr_R() {
  tlmgr remove "$@"
}

tlmgr_S() {
  tlmgr install "$@"
}

tlmgr_Si() {
  tlmgr info "$@"
}

tlmgr_Sl() {
  tlmgr info
}

tlmgr_Ss() {
  tlmgr search --global "$@"
}

tlmgr_Suy() {
  tlmgr update --all
}

tlmgr_U() {
  tlmgr install --file "$@"
}



_yum_init() {
  :
}

yum_Q() {
  if [ "$_TOPT" = "q" ]; then
    rpm -qa --qf "%{NAME}\\n"
  elif [ -z "$_TOPT" ]; then
    rpm -qa --qf "%{NAME} %{VERSION}\\n"
  else
    _not_implemented
  fi
}

yum_Qe() {
  # in Centos8, repoquery takes 'reason' as format placeholder
  centos_version="$($GREP -ohP '(?<=VERSION_ID=")([^"]+)(?=")' /etc/*elease)"
  [ "$centos_version" -eq "8" ] && reason="reason" || reason="yumdb_info.reason"

  repoquery --installed --qf "%{name} - %{$reason}" --all \
    | $GREP 'user$' | cut -d' ' -f1
}

yum_Qi() {
  yum info "$@"
}

yum_Qs() {
  if [ "$_TOPT" = "q" ]; then
    rpm -qa --qf "%{NAME}\\n" "*${*}*"
  elif [ -z "$_TOPT" ]; then
    rpm -qa --qf "%{NAME} %{VERSION}\\n" "*${*}*"
  else
    _not_implemented
  fi
}

yum_Ql() {
  rpm -ql "$@"
}

yum_Qo() {
  if cmd="$(command -v -- "$@")"; then
    rpm -qf "$cmd"
  else
    rpm -qf "$@"
  fi
}

yum_Qp() {
  rpm -qp "$@"
}

yum_Qc() {
  rpm -q --changelog "$@"
}

yum_Qu() {
  yum list updates "$@"
}

yum_Qm() {
  yum list extras "$@"
}

yum_Rs() {
  if [ -z "$_TOPT" ]; then
    yum erase "$@"
  else
    _not_implemented
  fi
}

yum_R() {
  yum erase "$@"
}

yum_Sg() {
  if [ $# -eq 0 ]; then
    yum grouplist hidden
  else
    yum groups info "$@"
  fi
}

yum_Si() {
  _require_programs repoquery
  repoquery --requires --resolve "$@"
}

yum_Suy() {
  yum update "$@"
}

yum_Su() {
  yum update "$@"
}

yum_Sy() {
  yum check-update "$@"
}

yum_Ss() {
  yum -C search "$@"
}

yum_Sc() {
  yum clean expire-cache "$@"
}

yum_Scc() {
  yum clean packages "$@"
}

yum_Sccc() {
  yum clean all "$@"
}

yum_S() {
  # shellcheck disable=SC2086
  yum install $_TOPT "$@"
}

yum_U() {
  yum localinstall "$@"
}

yum_Sii() {
  _require_programs repoquery
  repoquery --installed --whatrequires "$@"
}



_zypper_init() {
  :
}

zypper_Qc() {
  rpm -q --changelog "$@"
}

zypper_Qi() {
  zypper info "$@"
}

zypper_Ql() {
  rpm -ql "$@"
}

zypper_Qu() {
  zypper list-updates "$@"
}

zypper_Qm() {
  zypper search -si "$@" \
  | grep 'System Packages'
}

zypper_Qo() {
  if cmd="$(command -v -- "$@")"; then
    rpm -qf "$cmd"
  else
    rpm -qf "$@"
  fi
}

zypper_Qp() {
  rpm -qip "$@"
}

zypper_Qs() {
  zypper search --search-descriptions --installed-only "$@" \
  | {
    if [ "$_TOPT" = "q" ]; then
      awk -F ' *| *' '/^[a-z]/ {print $3}'
    else
      cat
    fi
  }
}

zypper_Q() {
  if [ "$_TOPT" = "q" ]; then
    zypper search -i "$@" \
    | grep ^i \
    | awk '{print $3}'
  elif [ -z "$_TOPT" ]; then
    zypper search -i "$@"
  else
    _not_implemented
  fi
}

zypper_Rs() {
  if [ "$_TOPT" = "s" ]; then
    zypper remove "$@" --clean-deps
  else
    _not_implemented
  fi
}

zypper_R() {
  zypper remove "$@"
}

zypper_Rn() {
  # Remove configuration files
  rpm -ql "$@" \
  | while read -r file; do
    if [ -f "$file" ]; then
      rm -fv "$file"
    fi
  done

  # Now remove the package per-se
  zypper remove "$@"
}

zypper_Rns() {
  # Remove configuration files
  rpm -ql "$@" \
  | while read -r file; do
    if [ -f "$file" ]; then
      rm -fv "$file"
    fi
  done

  zypper remove "$@" --clean-deps
}

zypper_Suy() {
  zypper dup "$@"
}

zypper_Sy() {
  zypper refresh "$@"
}

zypper_Sl() {
  if [ $# -eq 0 ]; then
    zypper pa -R
  else
    zypper pa -r "$@"
  fi
}

zypper_Sg() {
  if [ $# -gt 0 ]; then
    zypper info "$@"
  else
    zypper patterns
  fi
}

zypper_Ss() {
  zypper search "$@"
}

zypper_Su() {
  zypper --no-refresh dup "$@"
}

zypper_Sc() {
  zypper clean "$@"
}

zypper_Scc() {
  zypper clean "$@"
}

zypper_Sccc() {
  # Not way to do this in zypper
  _not_implemented
}

zypper_Si() {
  zypper info --requires "$@"
}

zypper_Sii() {
  if [ $# -eq 0 ]; then
    _error "Missing some package name."
    return 1
  fi
  _not_implemented
  return

  # TOO SLOW ! # # Ugly and slow, but does the trick
  # TOO SLOW ! # local_packages="$( \
  # TOO SLOW ! #   zypper pa --installed-only -R \
  # TOO SLOW ! #   | grep -E '^[a-z]' \
  # TOO SLOW ! #   | cut -d \| -f 3 | sort -u)"
  # TOO SLOW ! #
  # TOO SLOW ! # for package in $local_packages; do
  # TOO SLOW ! #   zypper info --requires "$package" \
  # TOO SLOW ! #   | grep -q "$@" && echo "$package"
  # TOO SLOW ! # done
}

zypper_S() {
  # shellcheck disable=SC2086
  zypper install $_TOPT "$@"
}

zypper_U() {
  zypper install "$@"
}
_validate_operation() {
  case "$1" in
  "apk_Q") ;;
  "apk_Qe") ;;
  "apk_Qi") ;;
  "apk_Ql") ;;
  "apk_Qo") ;;
  "apk_Qs") ;;
  "apk_Qu") ;;
  "apk_R") ;;
  "apk_Rn") ;;
  "apk_Rns") ;;
  "apk_Rs") ;;
  "apk_S") ;;
  "apk_Sc") ;;
  "apk_Scc") ;;
  "apk_Sccc") ;;
  "apk_Si") ;;
  "apk_Sii") ;;
  "apk_Sl") ;;
  "apk_Ss") ;;
  "apk_Su") ;;
  "apk_Suy") ;;
  "apk_Sy") ;;
  "apk_U") ;;
  "apt_cyg_Ss") ;;
  "apt_cyg_S") ;;
  "apt_cyg_Sy") ;;
  "apt_cyg_Q") ;;
  "apt_cyg_Qi") ;;
  "apt_cyg_Ql") ;;
  "apt_cyg_R") ;;
  "cave_Q") ;;
  "cave_Qi") ;;
  "cave_Ql") ;;
  "cave_Qo") ;;
  "cave_Qp") ;;
  "cave_Qu") ;;
  "cave_Qs") ;;
  "cave_Rs") ;;
  "cave_Rn") ;;
  "cave_Rns") ;;
  "cave_R") ;;
  "cave_Si") ;;
  "cave_Suy") ;;
  "cave_Su") ;;
  "cave_Sy") ;;
  "cave_Ss") ;;
  "cave_Sc") ;;
  "cave_Scc") ;;
  "cave_Sccc") ;;
  "cave_S") ;;
  "cave_U") ;;
  "conda_Q") ;;
  "conda_Qo") ;;
  "conda_R") ;;
  "conda_S") ;;
  "conda_Sc") ;;
  "conda_Si") ;;
  "conda_Ss") ;;
  "conda_Suy") ;;
  "dnf_S") ;;
  "dnf_Sc") ;;
  "dnf_Scc") ;;
  "dnf_Sccc") ;;
  "dnf_Si") ;;
  "dnf_Sii") ;;
  "dnf_Sg") ;;
  "dnf_Sl") ;;
  "dnf_Ss") ;;
  "dnf_Su") ;;
  "dnf_Suy") ;;
  "dnf_Sy") ;;
  "dnf_Q") ;;
  "dnf_Qc") ;;
  "dnf_Qe") ;;
  "dnf_Qi") ;;
  "dnf_Ql") ;;
  "dnf_Qm") ;;
  "dnf_Qo") ;;
  "dnf_Qp") ;;
  "dnf_Qs") ;;
  "dnf_Qu") ;;
  "dnf_R") ;;
  "dnf_U") ;;
  "dpkg_Q") ;;
  "dpkg_Qc") ;;
  "dpkg_Qi") ;;
  "dpkg_Qe") ;;
  "dpkg_Qk") ;;
  "dpkg_Ql") ;;
  "dpkg_Qo") ;;
  "dpkg_Qp") ;;
  "dpkg_Qu") ;;
  "dpkg_Qs") ;;
  "dpkg_Rs") ;;
  "dpkg_Rn") ;;
  "dpkg_Rns") ;;
  "dpkg_R") ;;
  "dpkg_Sg") ;;
  "dpkg_Si") ;;
  "dpkg_Suy") ;;
  "dpkg_Su") ;;
  "dpkg_Sy") ;;
  "dpkg_Ss") ;;
  "dpkg_Sc") ;;
  "dpkg_Scc") ;;
  "dpkg_S") ;;
  "dpkg_U") ;;
  "dpkg_Sii") ;;
  "dpkg_Sccc") ;;
  "homebrew_Qi") ;;
  "homebrew_Ql") ;;
  "homebrew_Qs") ;;
  "homebrew_Qc") ;;
  "homebrew_Qu") ;;
  "homebrew_Q") ;;
  "homebrew_R") ;;
  "homebrew_Si") ;;
  "homebrew_Suy") ;;
  "homebrew_Su") ;;
  "homebrew_Sy") ;;
  "homebrew_Ss") ;;
  "homebrew_Sc") ;;
  "homebrew_Scc") ;;
  "homebrew_Sccc") ;;
  "homebrew_S") ;;
  "macports_Ql") ;;
  "macports_Qo") ;;
  "macports_Qc") ;;
  "macports_Qu") ;;
  "macports_Rs") ;;
  "macports_R") ;;
  "macports_Si") ;;
  "macports_Suy") ;;
  "macports_Su") ;;
  "macports_Sy") ;;
  "macports_Ss") ;;
  "macports_Sc") ;;
  "macports_Scc") ;;
  "macports_S") ;;
  "opkg_Sy") ;;
  "opkg_Q") ;;
  "opkg_Qi") ;;
  "opkg_Ql") ;;
  "opkg_Qo") ;;
  "opkg_Qs") ;;
  "opkg_Qu") ;;
  "opkg_R") ;;
  "opkg_S") ;;
  "opkg_Si") ;;
  "opkg_Sii") ;;
  "opkg_Ss") ;;
  "opkg_Su") ;;
  "opkg_U") ;;
  "pkgng_Qi") ;;
  "pkgng_Ql") ;;
  "pkgng_Qo") ;;
  "pkgng_Qp") ;;
  "pkgng_Qu") ;;
  "pkgng_Q") ;;
  "pkgng_Rs") ;;
  "pkgng_R") ;;
  "pkgng_Si") ;;
  "pkgng_Suy") ;;
  "pkgng_Su") ;;
  "pkgng_Sy") ;;
  "pkgng_Ss") ;;
  "pkgng_Sc") ;;
  "pkgng_Scc") ;;
  "pkgng_S") ;;
  "pkg_tools_Qi") ;;
  "pkg_tools_Ql") ;;
  "pkg_tools_Qo") ;;
  "pkg_tools_Qp") ;;
  "pkg_tools_Qu") ;;
  "pkg_tools_Q") ;;
  "pkg_tools_Rs") ;;
  "pkg_tools_Rn") ;;
  "pkg_tools_Rns") ;;
  "pkg_tools_R") ;;
  "pkg_tools_Si") ;;
  "pkg_tools_Sl") ;;
  "pkg_tools_Suy") ;;
  "pkg_tools_Su") ;;
  "pkg_tools_Sy") ;;
  "pkg_tools_Ss") ;;
  "pkg_tools_Sc") ;;
  "pkg_tools_Scc") ;;
  "pkg_tools_S") ;;
  "portage_Qi") ;;
  "portage_Ql") ;;
  "portage_Qo") ;;
  "portage_Qc") ;;
  "portage_Qu") ;;
  "portage_Q") ;;
  "portage_Rs") ;;
  "portage_R") ;;
  "portage_Si") ;;
  "portage_Suy") ;;
  "portage_Su") ;;
  "portage_Sy") ;;
  "portage_Ss") ;;
  "portage_Sc") ;;
  "portage_Scc") ;;
  "portage_Sccc") ;;
  "portage_S") ;;
  "sun_tools_Qi") ;;
  "sun_tools_Ql") ;;
  "sun_tools_Qo") ;;
  "sun_tools_Qs") ;;
  "sun_tools_Q") ;;
  "sun_tools_R") ;;
  "sun_tools_U") ;;
  "swupd_Q") ;;
  "swupd_Qi") ;;
  "swupd_Qk") ;;
  "swupd_Qo") ;;
  "swupd_Qs") ;;
  "swupd_R") ;;
  "swupd_Sc") ;;
  "swupd_Scc") ;;
  "swupd_Suy") ;;
  "swupd_Su") ;;
  "swupd_Sy") ;;
  "swupd_Ss") ;;
  "swupd_S") ;;
  "tazpkg_Q") ;;
  "tazpkg_Qi") ;;
  "tazpkg_Ql") ;;
  "tazpkg_Sy") ;;
  "tazpkg_Su") ;;
  "tazpkg_Suy") ;;
  "tazpkg_S") ;;
  "tazpkg_R") ;;
  "tazpkg_Sc") ;;
  "tazpkg_Scc") ;;
  "tazpkg_Ss") ;;
  "tazpkg_Qo") ;;
  "tazpkg_U") ;;
  "tlmgr_Qi") ;;
  "tlmgr_Qk") ;;
  "tlmgr_Ql") ;;
  "tlmgr_R") ;;
  "tlmgr_S") ;;
  "tlmgr_Si") ;;
  "tlmgr_Sl") ;;
  "tlmgr_Ss") ;;
  "tlmgr_Suy") ;;
  "tlmgr_U") ;;
  "yum_Q") ;;
  "yum_Qe") ;;
  "yum_Qi") ;;
  "yum_Qs") ;;
  "yum_Ql") ;;
  "yum_Qo") ;;
  "yum_Qp") ;;
  "yum_Qc") ;;
  "yum_Qu") ;;
  "yum_Qm") ;;
  "yum_Rs") ;;
  "yum_R") ;;
  "yum_Sg") ;;
  "yum_Si") ;;
  "yum_Suy") ;;
  "yum_Su") ;;
  "yum_Sy") ;;
  "yum_Ss") ;;
  "yum_Sc") ;;
  "yum_Scc") ;;
  "yum_Sccc") ;;
  "yum_S") ;;
  "yum_U") ;;
  "yum_Sii") ;;
  "zypper_Qc") ;;
  "zypper_Qi") ;;
  "zypper_Ql") ;;
  "zypper_Qu") ;;
  "zypper_Qm") ;;
  "zypper_Qo") ;;
  "zypper_Qp") ;;
  "zypper_Qs") ;;
  "zypper_Q") ;;
  "zypper_Rs") ;;
  "zypper_R") ;;
  "zypper_Rn") ;;
  "zypper_Rns") ;;
  "zypper_Suy") ;;
  "zypper_Sy") ;;
  "zypper_Sl") ;;
  "zypper_Sg") ;;
  "zypper_Ss") ;;
  "zypper_Su") ;;
  "zypper_Sc") ;;
  "zypper_Scc") ;;
  "zypper_Sccc") ;;
  "zypper_Si") ;;
  "zypper_Sii") ;;
  "zypper_S") ;;
  "zypper_U") ;;
  *) return 1 ;;
  esac
}



set -u

unset GREP_OPTIONS

: "${PACAPT_DEBUG=}"  # Show what will be going
: "${GREP:=grep}"     # Need to update in, e.g, _sun_tools_init
: "${AWK:=awk}"       # Need to update in, e.g, _sun_tools_init

local_requirements="$GREP $AWK"
if ! _sun_tools_init; then
  local_requirements="${local_requirements} sed"
fi

_require_programs $local_requirements

export PACAPT_DEBUG GREP AWK

if [ -z "${__PACAPT_FORKED__:-}" ]; then
  if command -v bash >/dev/null \
      && bash -c 'echo ${BASH_VERSION[*]}' \
        | "$GREP" -Ee "^[4-9]." >/dev/null 2>&1 \
    ; then

    _debug "Switching to Bash shell"
    export __PACAPT_FORKED__="yes"
    readonly __PACAPT_FORKED__

    exec bash -- "$0" "$@"
  fi
else
  # Hey, this is very awesome strick to avoid syntax issue.
  # Note: in `bocker` (github.com/icy/bocker/) we use `base64`.
  # FIXME: `source /dev/stdin` doesn't work without Bash >=4
  eval 'source /dev/stdin < <("$GREP" '^#_!_POSIX_#' "$0" | sed -e 's/^#_!_POSIX_#//')' \
  || _die "$0: Unable to load non-POSIX definitions".
fi


_POPT=""    # primary operation
_SOPT=""    # secondary operation
_TOPT=""    # options for operations
_EOPT=""    # extra options (directly given to package manager)
            # these options will be translated by (_translate_all) method.
_PACMAN=""  # name of the package manager

_PACMAN_detect \
|| _die "'pacapt' doesn't support your package manager."

if [ -z "${__PACAPT_FORKED__:-}" ]; then
  case "$_PACMAN" in
  "cave")
    _die "pacapt($_PACMAN) library is not ready for pure-POSIX features (or your Bash version is not >= 4)."
    ;;
  *)
    ;;
  esac
fi

if [ -z "$PACAPT_DEBUG" ]; then
  [ "$_PACMAN" != "pacman" ] \
  || exec "/usr/bin/pacman" "$@"
elif [ "$PACAPT_DEBUG" != "auto" ]; then
  _PACMAN="$PACAPT_DEBUG"
fi

case "${1:-}" in
"update")     shift; set -- -Sy   "$@" ;;
"upgrade")    shift; set -- -Su   "$@" ;;
"install")    shift; set -- -S    "$@" ;;
"search")     shift; set -- -Ss   "$@" ;;
"remove")     shift; set -- -R    "$@" ;;
"autoremove") shift; set -- -Rs   "$@" ;;
"clean")      shift; set -- -Scc  "$@" ;;
esac

while :; do
  _args="${1-}"

  [ "$(printf "%.1s" "$_args")" = "-" ] || break

  case "${_args}" in
  "--help")
    _help
    exit 0
    ;;

  "--noconfirm")
    shift
    _EOPT="$_EOPT:noconfirm:"
    continue
    ;;

  "-"|"--")
    shift
    break
    ;;
  esac

  i=1
  while [ "$i" -lt "${#_args}" ]; do
    i=$(( i + 1))
    _opt="$(_string_nth "$i" "$_args")"

    case "$_opt" in
    h)
      _help
      exit 0
      ;;
    V)
      _print_pacapt_version;
      exit 0
      ;;
    P)
      _print_supported_operations "$_PACMAN"
      exit 0
      ;;

    Q|S|R|U)
      if [ -n "$_POPT" ] && [ "$_POPT" != "$_opt" ]; then
        _error "Only one operation may be used at a time"
        exit 1
      fi
      _POPT="$_opt"
      ;;

    # Comment 2015 May 26th: This part deals with the 2nd option.
    # Most of the time, there is only one 2nd option. But some
    # operation may need extra and/or duplicate (e.g, Sy <> Syy).
    #
    # See also
    #
    # * https://github.com/icy/pacapt/issues/13
    #
    #   This implementation works, but with a bug. #Rsn works
    #   but #Rns is translated to #Rn (incorrectly.)
    #   Thanks Huy-Ngo for this nice catch.
    #
    # FIXME: Please check pacman(8) to see if they are really 2nd operation
    #
    e|g|i|l|m|n|o|p|s|k)
      if [ -z "$_SOPT" ]; then
        _SOPT="$_opt"
        continue
      fi

      # Understand it:
      # If there is already an option recorded, the incoming option
      # will come and compare itself with known one.
      # We have a table
      #
      #     known one vs. incoming ? | result
      #                <             | one-new
      #                =             | one-one
      #                >             | new-one
      #
      # Let's say, after this step, the 3rd option comes (named X),
      # and the current result is "a-b". We have a table
      #
      #    a(b) vs. X  | result
      #         <      | aX (b dropped)
      #         =      | aa (b dropped)
      #         >      | Xa (b dropped)
      #
      # In any case, the first one matters.
      #
      f_SOPT="$(printf "%.1s" "$_SOPT")"
      if _string_less_than "$f_SOPT" "$_opt"; then
        _SOPT="${f_SOPT}$_opt"
      elif [ "${f_SOPT}" = "$_opt" ]; then
        _SOPT="$_opt$_opt"
      else
        _SOPT="$_opt${f_SOPT}"
      fi

      ;;

    q)
      _TOPT="$_opt" ;; # Thanks to James Pearson

    u)
      f_SOPT="$(printf "%.1s" "$_SOPT")"
      if [ "$f_SOPT" = "y" ]; then
        _SOPT="uy"
      else
        _SOPT="u"
      fi
      ;;

    y)
      f_SOPT="$(printf "%.1s" "$_SOPT")"
      if [ "${f_SOPT}" = "y" ]; then
        _SOPT="uy"
      else
        _SOPT="y"
      fi
      ;;

    c)
      if [ "$(printf "%.2s" "$_SOPT")" = "cc" ]; then
        _SOPT="ccc"
      elif [ "$(printf "%.1s" "$_SOPT")" = "c" ]; then
        _SOPT="cc"
      else
        _SOPT="$_opt"
      fi
      ;;

    w|v)
      _EOPT="$_EOPT:$_opt:"
      ;;

    *)
      # FIXME: If option is unknown, we will break the loop
      # FIXME: and this option will be used by the native program.
      # FIXME: break 2
      _die "$0: Unknown option '$_opt'."
      ;;
    esac
  done

  shift

  # If the primary option and the secondary are known
  # we would break the argument detection, but for sure we will look
  # forward to see there is anything interesting...
  if [ -n "$_POPT" ] && [ -n "$_SOPT" ]; then
    case "${1:-}" in
    "-w"|"--noconfirm") ;;
    *) break;;
    esac

  # Don't have anything from the **first** argument. Something wrong.
  # FIXME: This means that user must enter at least primary action
  # FIXME: or secondary action in the very first part...
  elif [ -z "${_POPT}${_SOPT}${_TOPT}" ]; then
    break
  fi
done

[ -n "$_POPT" ] \
|| _die "Usage: $0 <options>   # -h for help, -P list supported functions"

_validate_operation "${_PACMAN}_${_POPT}${_SOPT}" \
|| {
  _not_implemented
  exit 1
}

_translate_all || exit

if [ -n "$*" ]; then
  case "${_POPT}${_SOPT}" in
  "Su"|"Sy"|"Suy")
    if ! echo "$*" | $GREP -Eq -e '(^|\s)-' -e '-+\w+\s+[^-]'; then
      echo 1>&2 "WARNING ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
      echo 1>&2 "  The -Sy/u options refresh and/or upgrade all packages."
      echo 1>&2 "  To install packages as well, use separate commands:"
      echo 1>&2
      echo 1>&2 "    $0 -S$_SOPT; $0 -S ${*:-}"
      echo 1>&2 "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
    fi;
  esac
fi

if [ -n "$PACAPT_DEBUG" ]; then
  echo "pacapt: $_PACMAN, p=$_POPT, s=$_SOPT, t=$_TOPT, e=$_EOPT"
  echo "pacapt: execute '${_PACMAN}_${_POPT}${_SOPT} $_EOPT ${*:-}'"
  if command -v declare >/dev/null; then
    # shellcheck disable=SC3044
    declare -f "${_PACMAN}_${_POPT}${_SOPT}"
  else
    _error "Attempted to print the definition of the method '${_PACMAN}_${_POPT}${_SOPT}'."
    _error "However, unable to find method ('declare'). Maybe your shell is purely POSIX?"
  fi
else
  "_${_PACMAN}_init" || exit
  # shellcheck disable=SC2086
  "${_PACMAN}_${_POPT}${_SOPT}" $_EOPT "$@"
fi
