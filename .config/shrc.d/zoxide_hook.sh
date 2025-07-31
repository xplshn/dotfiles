# shellcheck shell=sh

# =============================================================================
#
# Utility functions for zoxide.
#

# pwd based on the value of _ZO_RESOLVE_SYMLINKS.
__zoxide_pwd() {
    \command pwd -L
}

# cd + custom logic based on the value of _ZO_ECHO.
__zoxide_cd() {
    # shellcheck disable=SC2164
    \command cd "$@"
}

# =============================================================================
#
# Hook configuration for zoxide.
#

# Hook to add new entries to the database.
__zoxide_hook() {
    \command zoxide add -- "$(__zoxide_pwd || \builtin true)"
}

# Initialize hook.
if [ "${PS1:=}" = "${PS1#*\$(__zoxide_hook)}" ]; then
    PS1="${PS1}\$(__zoxide_hook)"
fi

# Report common issues.
__zoxide_doctor() {
    [ "${_ZO_DOCTOR:-1}" -eq 0 ] && return 0
    case "${PS1:-}" in
    *__zoxide_hook*) return 0 ;;
    *) ;;
    esac

    _ZO_DOCTOR=0
    \command printf '%s\n' \
        'zoxide: detected a possible configuration issue.' \
        'Please ensure that zoxide is initialized right at the end of your shell configuration file.' \
        '' \
        'If the issue persists, consider filing an issue at:' \
        'https://github.com/ajeetdsouza/zoxide/issues' \
        '' \
        'Disable this message by setting _ZO_DOCTOR=0.' \
        '' >&2
}

# =============================================================================
#
# When using zoxide with --no-cmd, alias these internal functions as desired.
#

# Jump to a directory using only keywords.
__zoxide_z() {
    __zoxide_doctor

    if [ "$#" -eq 0 ]; then
        __zoxide_cd ~
    elif [ "$#" -eq 1 ] && [ "$1" = '-' ]; then
        if [ -n "${OLDPWD}" ]; then
            __zoxide_cd "${OLDPWD}"
        else
            # shellcheck disable=SC2016
            \command printf 'zoxide: $OLDPWD is not set'
            return 1
        fi
    elif [ "$#" -eq 1 ] && [ -d "$1" ]; then
        __zoxide_cd "$1"
    else
        __zoxide_result="$(\command zoxide query --exclude "$(__zoxide_pwd || \builtin true)" -- "$@")" &&
            __zoxide_cd "${__zoxide_result}"
    fi
}

# Jump to a directory using interactive search.
__zoxide_zi() {
    __zoxide_doctor
    __zoxide_result="$(\command zoxide query --interactive -- "$@")" && __zoxide_cd "${__zoxide_result}"
}

# =============================================================================
#
# Commands for zoxide. Disable these using --no-cmd.
#

\command unalias z >/dev/null 2>&1 || \true
z() {
    __zoxide_z "$@"
}

\command unalias zi >/dev/null 2>&1 || \true
zi() {
    __zoxide_zi "$@"
}

# =============================================================================
#
# To initialize zoxide, add this to your configuration:
#
# eval "$(zoxide init posix --hook prompt)"
