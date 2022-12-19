#!/bin/zsh

set -o err_return
set -o no_unset
set -o pipefail

TMP_DIR=$(mktemp --directory)
#TMP_DIR=$(mktemp "/tmp/ space test/tmp.XXXXXXXX" --directory)

cleanup() {
	echo
	echo "Cleaning up... ${TMP_DIR}" 
	rm -rf "$TMP_DIR"
}

trap cleanup EXIT

TMP_TAR_FILE="${TMP_DIR}/prezto.tar"
TMP_TAR_GZ_FILE="${TMP_TAR_FILE}.gz"

echo "Archiving current head into ${TMP_TAR_FILE}"
git archive --prefix "prezto/" --output="${TMP_TAR_FILE}" HEAD
git submodule foreach --recursive --quiet \
	"echo \"Archiving appending submodule \$path -> \$sha1.tar -> ${TMP_TAR_FILE}\" && \
	git archive --prefix=prezto/\$path/ --output=\"${TMP_DIR}/\$sha1.tar\" HEAD && \
	tar --concatenate --file=\"${TMP_TAR_FILE}\" \"${TMP_DIR}/\$sha1.tar\""

echo

function fileSize() {
	stat --printf="%s" "$1"
}

echo "Compressing ${TMP_TAR_FILE} -> ${TMP_TAR_GZ_FILE}"
gzip --stdout "${TMP_TAR_FILE}" > "${TMP_TAR_GZ_FILE}"
PRESIZE=$(fileSize "${TMP_TAR_FILE}")
POSTSIZE=$(fileSize "${TMP_TAR_GZ_FILE}")
printf "Compression size change %d -> %d - Size reduction %.1f%%\n" ${PRESIZE} ${POSTSIZE} $(((1-${POSTSIZE}/${PRESIZE}.)*100))

echo

function upload() {
	local SRC="${TMP_TAR_GZ_FILE}"
	local DEST="$1"
	echo "Uploading ${SRC} to ${DEST}"
	rsync --archive --info=progress2 "${SRC}" "${DEST}"
}

upload "root@staging.turninn.appdynamic.com:/var/www/html/prezto/prezto.tar.gz"
upload "root@download.airserver.com:/var/www/download.airserver.com/prezto/prezto.tar.gz"
