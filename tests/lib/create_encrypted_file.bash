create_encrypted_file() {
    {
        file="${2:-secrets.yaml}"
        case "${3:-${HELM_SECRETS_DRIVER}}" in
        sops)
            # shellcheck disable=SC2059
            printf "$1" >"${TEST_TEMP_DIR}/${file}"
            (cd "${TEST_TEMP_DIR}" && exec sops -e -i "${file}")
            ;;
        vault)
            # Check for multiline
            if echo "$1" | grep -q ': |'; then
                # shellcheck disable=SC2059
                secret_content="$(printf "$1" | tail -n +2 | sed -e 's/^  //g')"
                secret_key="$(printf '%s' "$secret_content" | _shasum | cut -d' ' -f1)"
            else
                # shellcheck disable=SC2059
                secret_content="$(printf "$1" | cut -d: -f2 | tr -d ' ')"
                secret_key="$(printf '%s' "$secret_content" | _shasum | cut -d' ' -f1)"
            fi

            printf '%s: !vault secret/%s#key' "$(echo "$1" | cut -d: -f1)" "${secret_key}" >"${TEST_TEMP_DIR}/${file}"
            printf '%s' "${secret_content}" | vault kv put "secret/${secret_key}" key=-
            ;;
        envsubst)
            # Check for multiline
            if echo "$1" | grep -q ': |'; then
                # shellcheck disable=SC2059
                secret_content="$(printf "$1" | tail -n +2 | sed -e 's/^  //g')"
                secret_key="$(printf '%s' "$secret_content" | _shasum | cut -d' ' -f1)"
            else
                # shellcheck disable=SC2059
                secret_content="$(printf "$1" | cut -d: -f2 | tr -d ' ')"
                secret_key="$(printf '%s' "$secret_content" | _shasum | cut -d' ' -f1)"
            fi

            # shellcheck disable=SC2016
            printf '%s: "${_TEST_%s}"' "$(printf '%s' "$1" | cut -d: -f1)" "${secret_key}" >"${TEST_TEMP_DIR}/${file}"
            export _TEST_"${secret_key}"="${secret_content}"
            ;;
        noop)
            # shellcheck disable=SC2059
            printf "$1" >"${TEST_TEMP_DIR}/${file}"
            ;;
        *)
            echo "Unknown driver ${HELM_SECRETS_DRIVER}"
            ;;
        esac
    } >&2
}
