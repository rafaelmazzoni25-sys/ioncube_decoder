#!/bin/sh

MKDIR="mkdir -p"

ROOT_DIR=`pwd`
WINDOWS_ROOT="${ROOT_DIR}"
case "${WINDOWS_ROOT}" in
        [A-Za-z]:/*)
                ;;
        /[A-Za-z]/*)
                DRIVE=`printf '%s\n' "${WINDOWS_ROOT}" | cut -c2 | tr '[:lower:]' '[:upper:]'`
                REST=`printf '%s\n' "${WINDOWS_ROOT}" | cut -c4-`
                WINDOWS_ROOT="${DRIVE}:/${REST}"
                ;;
        *)
                ;;
esac

DEFAULT_PHP74_COMMAND="php\\php-cgi.exe -c php\\php.ini"
DEFAULT_PHP74_BIN_POSIX="php/php-cgi.exe"
DEFAULT_PHP54_COMMAND="php54\\php-cgi.exe -c php54\\php.ini"
DEFAULT_PHP54_BIN_POSIX="php54/php-cgi.exe"

DEFAULT_LOADER_WIN="${WINDOWS_ROOT}/ioncube/ioncube_loader_win_7.4.dll"
DEFAULT_LOADER_POSIX="${ROOT_DIR}/ioncube/ioncube_loader_win_7.4.dll"
LEGACY_LOADER_WIN="${WINDOWS_ROOT}/ioncube/ioncube_loader_win_5.4.dll"
LEGACY_LOADER_POSIX="${ROOT_DIR}/ioncube/ioncube_loader_win_5.4.dll"

DEFAULT_ZEND_MANAGER_WIN="${WINDOWS_ROOT}/ioncube/Zend/ZendExtensionManager.dll"
DEFAULT_ZEND_OPTIMIZER_WIN="${WINDOWS_ROOT}/ioncube/Zend/Optimizer"

: "${IONCUBE_LOADER:=${DEFAULT_LOADER_WIN}}"
: "${IONCUBE_ZEND_MANAGER:=${DEFAULT_ZEND_MANAGER_WIN}}"
: "${IONCUBE_ZEND_OPTIMIZER:=${DEFAULT_ZEND_OPTIMIZER_WIN}}"
: "${IONCUBE_DECODER_PHP74:=${DEFAULT_PHP74_COMMAND}}"
: "${IONCUBE_DECODER_PHP54:=${DEFAULT_PHP54_COMMAND}}"
: "${IONCUBE_DECODER_LOADER_54:=${LEGACY_LOADER_WIN}}"
: "${IONCUBE_DECODER_ZEND_MANAGER_54:=${DEFAULT_ZEND_MANAGER_WIN}}"
: "${IONCUBE_DECODER_ZEND_OPTIMIZER_54:=${DEFAULT_ZEND_OPTIMIZER_WIN}}"

export IONCUBE_LOADER IONCUBE_ZEND_MANAGER IONCUBE_ZEND_OPTIMIZER

ENCODED_FOLDER=ENCODED
DECODED_FOLDER=DECODED
DELETE_RAR=DECODED.rar
LOG_FILE=Log_Decoded.txt
NUMBER_DECODED_FILES=0
PHP_CCOMMAND="php\\Php\\php.exe php\\Php\\optimization.php suffix"

CURRENT_RUNTIME_LABEL=""
CURRENT_RUNTIME_TARGET=""
CURRENT_RUNTIME_AVAILABLE=0
CURRENT_RUNTIME_REASON=""
CURRENT_PHP_COMMAND=""
CURRENT_LOADER=""
CURRENT_ZEND_MANAGER=""
CURRENT_ZEND_OPTIMIZER=""

prepare_runtime_for_file() {
        FILE_PATH="$1"

        CURRENT_RUNTIME_LABEL="php74"
        CURRENT_RUNTIME_TARGET=""
        CURRENT_RUNTIME_AVAILABLE=1
        CURRENT_RUNTIME_REASON=""
        CURRENT_PHP_COMMAND="${IONCUBE_DECODER_PHP74}"
        CURRENT_LOADER="${IONCUBE_LOADER}"
        CURRENT_ZEND_MANAGER="${IONCUBE_ZEND_MANAGER}"
        CURRENT_ZEND_OPTIMIZER="${IONCUBE_ZEND_OPTIMIZER}"
        CURRENT_PHP_COMMAND_CHECK=""
        CURRENT_LOADER_CHECK=""

        COMMAND_BIN_RAW=`printf '%s\n' "${CURRENT_PHP_COMMAND}" | awk '{print $1}'`
        if [ "${CURRENT_PHP_COMMAND}" = "${DEFAULT_PHP74_COMMAND}" ]; then
                CURRENT_PHP_COMMAND_CHECK="${DEFAULT_PHP74_BIN_POSIX}"
        else
                case "${COMMAND_BIN_RAW}" in
                        *:/*|*:\\*)
                                CURRENT_PHP_COMMAND_CHECK=""
                                ;;
                        *)
                                CURRENT_PHP_COMMAND_CHECK=`printf '%s\n' "${COMMAND_BIN_RAW}" | tr '\\' '/'`
                                ;;
                esac
        fi

        if [ "${CURRENT_LOADER}" = "${DEFAULT_LOADER_WIN}" ]; then
                CURRENT_LOADER_CHECK="${DEFAULT_LOADER_POSIX}"
        fi

        TARGET_GREP=`grep -ao "ionCube Encoder for PHP [0-9]\.[0-9]" "${FILE_PATH}" 2>/dev/null | head -n 1`
        if [ "${TARGET_GREP}" ]; then
                CURRENT_RUNTIME_TARGET=`printf '%s\n' "${TARGET_GREP}" | awk '{print $5}'`
        else
                CURRENT_RUNTIME_TARGET=""
        fi

        if [ "${CURRENT_RUNTIME_TARGET}" ]; then
                TARGET_MAJOR=`printf '%s\n' "${CURRENT_RUNTIME_TARGET}" | cut -d'.' -f1`
                case "${TARGET_MAJOR}" in
                        '' )
                                ;;
                        0|1|2|3|4|5|6)
                                CURRENT_RUNTIME_LABEL="php54"
                                CURRENT_PHP_COMMAND="${IONCUBE_DECODER_PHP54}"
                                CURRENT_LOADER="${IONCUBE_DECODER_LOADER_54}"
                                CURRENT_ZEND_MANAGER="${IONCUBE_DECODER_ZEND_MANAGER_54}"
                                CURRENT_ZEND_OPTIMIZER="${IONCUBE_DECODER_ZEND_OPTIMIZER_54}"

                                COMMAND_BIN_RAW=`printf '%s\n' "${CURRENT_PHP_COMMAND}" | awk '{print $1}'`
                                if [ "${CURRENT_PHP_COMMAND}" = "${DEFAULT_PHP54_COMMAND}" ]; then
                                        CURRENT_PHP_COMMAND_CHECK="${DEFAULT_PHP54_BIN_POSIX}"
                                else
                                        case "${COMMAND_BIN_RAW}" in
                                                *:/*|*:\\*)
                                                        CURRENT_PHP_COMMAND_CHECK=""
                                                        ;;
                                                *)
                                                        CURRENT_PHP_COMMAND_CHECK=`printf '%s\n' "${COMMAND_BIN_RAW}" | tr '\\' '/'`
                                                        ;;
                                        esac
                                fi

                                if [ "${CURRENT_LOADER}" = "${LEGACY_LOADER_WIN}" ]; then
                                        CURRENT_LOADER_CHECK="${LEGACY_LOADER_POSIX}"
                                else
                                        CURRENT_LOADER_CHECK=""
                                fi
                                ;;
                esac
        fi

        if [ -z "${CURRENT_PHP_COMMAND}" ]; then
                CURRENT_RUNTIME_AVAILABLE=0
                if [ "${CURRENT_RUNTIME_LABEL}" = "php54" ]; then
                        CURRENT_RUNTIME_REASON="nenhum runtime configurado para arquivos protegidos que exigem PHP 5.x (defina IONCUBE_DECODER_PHP54)"
                else
                        CURRENT_RUNTIME_REASON="comando PHP padrão ausente (defina IONCUBE_DECODER_PHP74)"
                fi
        fi

        if [ "${CURRENT_RUNTIME_AVAILABLE}" -eq 1 ] && [ "${CURRENT_PHP_COMMAND_CHECK}" ]; then
                if [ ! -f "${CURRENT_PHP_COMMAND_CHECK}" ]; then
                        CURRENT_RUNTIME_AVAILABLE=0
                        if [ "${CURRENT_RUNTIME_LABEL}" = "php54" ]; then
                                CURRENT_RUNTIME_REASON="runtime PHP 5 não encontrado em ${CURRENT_PHP_COMMAND_CHECK}"
                        else
                                CURRENT_RUNTIME_REASON="runtime PHP padrão não encontrado em ${CURRENT_PHP_COMMAND_CHECK}"
                        fi
                fi
        fi

        if [ "${CURRENT_RUNTIME_AVAILABLE}" -eq 1 ] && [ "${CURRENT_LOADER_CHECK}" ]; then
                if [ ! -f "${CURRENT_LOADER_CHECK}" ]; then
                        CURRENT_RUNTIME_AVAILABLE=0
                        if [ "${CURRENT_RUNTIME_LABEL}" = "php54" ]; then
                                CURRENT_RUNTIME_REASON="ionCube Loader para PHP 5 ausente em ${CURRENT_LOADER_CHECK}"
                        else
                                CURRENT_RUNTIME_REASON="ionCube Loader padrão ausente em ${CURRENT_LOADER_CHECK}"
                        fi
                fi
        fi
}

if [ -d "${DECODED_FOLDER}" ]; then
        rm -rf "${DECODED_FOLDER}"
        rm -rf "${DELETE_RAR}"
fi

${MKDIR} "${DECODED_FOLDER}"

if [ -d "${ENCODED_FOLDER}" ] && [ -d "${DECODED_FOLDER}" ]; then
        printf '### EasyToYou.eu Log Files - Decoded ###\n\n' > "${DECODED_FOLDER}/${LOG_FILE}"

        find "${ENCODED_FOLDER}" | while read FILE; do {
                IS_DECODED=0
                SKIP_MESSAGE=""
                FILENAME=`printf '%s\n' "${FILE}" | awk -F '/' '{print $NF}'`
                DESTINATION=`printf '%s\n' "${FILE}" | sed -e "s/^${ENCODED_FOLDER}/${DECODED_FOLDER}/;"`
                DESTINATION_FOLDER=`dirname "${DESTINATION}"`

                if [ ! -d "${DESTINATION_FOLDER}" ]; then
                        ${MKDIR} "${DESTINATION_FOLDER}"
                fi

                if [ -f "${FILE}" ]; then
                        FILENAME_EXTENSION=`printf '%s\n' "${FILE}" | awk -F '.' '{print $NF}'`

                        IS_COMPILED=`cat "${FILE}" | grep "requires the ionCube PHP Loader\|extension_loaded('ionCube Loader'))\|function_exists('_il_exec'))\|<?php @Zend;\|^Zend\|!extension_loaded('Php Express')\|is_callable(\"eaccelerator_load\")\|sg_load\|phpshield_load"`

                        if [ "${IS_COMPILED}" ]; then
                                prepare_runtime_for_file "${FILE}"

                                if [ "${CURRENT_RUNTIME_AVAILABLE}" -eq 1 ]; then
                                        COMMAND_PREFIX="./"
                                        case "${CURRENT_PHP_COMMAND}" in
                                                [A-Za-z]:/*|*:\\*|/*)
                                                        COMMAND_PREFIX=""
                                                        ;;
                                        esac
                                        printf '# Command %s%s "%s" > "%s"\n' "${COMMAND_PREFIX}" "${CURRENT_PHP_COMMAND}" "${FILE}" "${DESTINATION}"
                                        TMP_STDERR="${DESTINATION}.stderr"
                                        if IONCUBE_LOADER="${CURRENT_LOADER}" IONCUBE_ZEND_MANAGER="${CURRENT_ZEND_MANAGER}" IONCUBE_ZEND_OPTIMIZER="${CURRENT_ZEND_OPTIMIZER}" ${COMMAND_PREFIX}${CURRENT_PHP_COMMAND} "${FILE}" > "${DESTINATION}" 2> "${TMP_STDERR}"; then
                                                rm -f "${TMP_STDERR}"
                                                printf '%s\n' "${DESTINATION}" >> "${DECODED_FOLDER}/${LOG_FILE}"
                                                IS_DECODED=1
                                                NUMBER_DECODED_FILES=$((${NUMBER_DECODED_FILES} + 1))
                                                ./${PHP_CCOMMAND} "${DESTINATION}" > "php\\Php\\log\\log.log"
                                        else
                                                STATUS=$?
                                                RUNTIME_FAILURE_MESSAGE=`head -n 1 "${TMP_STDERR}" 2>/dev/null | tr -d '\r'`
                                                rm -f "${TMP_STDERR}"
                                                if [ -z "${RUNTIME_FAILURE_MESSAGE}" ]; then
                                                        if [ "${CURRENT_RUNTIME_TARGET}" ]; then
                                                                RUNTIME_FAILURE_MESSAGE="falha ao executar runtime ${CURRENT_RUNTIME_LABEL} para alvo PHP ${CURRENT_RUNTIME_TARGET} (status ${STATUS})"
                                                        else
                                                                RUNTIME_FAILURE_MESSAGE="falha ao executar runtime ${CURRENT_RUNTIME_LABEL} (status ${STATUS})"
                                                        fi
                                                fi
                                                SKIP_MESSAGE="${RUNTIME_FAILURE_MESSAGE}"
                                                rm -f "${DESTINATION}"
                                        fi
                                else
                                        SKIP_MESSAGE="${CURRENT_RUNTIME_REASON}"
                                fi

                                if [ "${IS_DECODED}" != "1" ] && [ "${SKIP_MESSAGE}" ]; then
                                        if [ "${CURRENT_RUNTIME_TARGET}" ]; then
                                                printf '# Skipped %s (alvo PHP %s): %s\n' "${FILE}" "${CURRENT_RUNTIME_TARGET}" "${SKIP_MESSAGE}" >&2
                                                printf 'SKIPPED: %s (alvo PHP %s) - %s\n' "${DESTINATION}" "${CURRENT_RUNTIME_TARGET}" "${SKIP_MESSAGE}" >> "${DECODED_FOLDER}/${LOG_FILE}"
                                        else
                                                printf '# Skipped %s: %s\n' "${FILE}" "${SKIP_MESSAGE}" >&2
                                                printf 'SKIPPED: %s - %s\n' "${DESTINATION}" "${SKIP_MESSAGE}" >> "${DECODED_FOLDER}/${LOG_FILE}"
                                        fi
                                fi
                        fi
                fi

                if [ -f "${FILE}" ] && [ "${IS_DECODED}" = "0" ]; then
                        cp -f "${FILE}" "${DESTINATION}"
                fi
        } done

        printf '\n' >> "${DECODED_FOLDER}/${LOG_FILE}"
        printf ' Number Of Decoded Files = "%s"\n' "${NUMBER_DECODED_FILES}" >> "${DECODED_FOLDER}/${LOG_FILE}"
fi

exit 0
