#!/bin/bash
UNAME="$(uname -r)"
DIR="$(dirname "$(readlink -f ${BASH_SOURCE[0]})")"
TMPDIR=/tmp/tmp.$(($RANDOM * 19318203981230 + 40))
PLUGIN="aquacomputer_d5next"
RELEASE="${DIR}/release"
PLG_FILE="${DIR}/plugin/${PLUGIN}.plg"
VERSION=$(date +"%Y.%m.%d")
ARCH="-x86_64"
PACKAGE="${RELEASE}/${PLUGIN}-${VERSION}${ARCH}.txz"
MD5="${RELEASE}/${PLUGIN}-${VERSION}${ARCH}.txz.md5"

mkdir -p "${RELEASE}"

#Compress modules
if [[ -f "${DIR}/source/aquacomputer_d5next.ko" ]]; then
    xz --check=crc32 --lzma2 "${DIR}/source/aquacomputer_d5next.ko"
fi
if [[ ! -f "${DIR}/source/aquacomputer_d5next.ko.xz" ]]; then
    echo "Module not found"
    exit
fi

for x in '' a b c d e d f g h; do
    PKG="${RELEASE}/${PLUGIN}-plugin-${VERSION}${x}${ARCH}.txz"
    if [[ ! -f $PKG ]]; then
        PACKAGE=$PKG
        VERSION="${VERSION}${x}"
        MD5="${RELEASE}/${PLUGIN}-plugin-${VERSION}${ARCH}.txz.md5"
        break
    fi
done

sed -i -e "s#\(ENTITY\s*version[^\"]*\).*#\1\"${VERSION}\">#" "$PLG_FILE"
sed -i "/##&name/a\###${VERSION}" "$PLG_FILE"

mkdir -p "${TMPDIR}/install/"
mkdir -p "${TMPDIR}/lib/modules/${UNAME}/extra/"
cp "${DIR}/plugin/slack-desc" "${TMPDIR}/install/"
cp "${DIR}/source/aquacomputer_d5next.ko.xz" "${TMPDIR}/lib/modules/${UNAME}/extra/"

cd "$TMPDIR/"
makepkg -l y -c y "${PACKAGE}"
cd "$RELEASE/"
md5sum $(basename "$PACKAGE") >"$MD5"
rm -rf "$TMPDIR"

# Verify and install plugin package
sum1=$(md5sum "${PACKAGE}")
sum2=$(cat "$MD5")
if [ "${sum1:0:32}" != "${sum2:0:32}" ]; then
    echo "Checksum mismatched."
    rm "$MD5" "${PACKAGE}"
else
    echo "Checksum matched."
fi
