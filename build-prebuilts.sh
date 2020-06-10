#!/bin/bash -ex

OUT_DIR=${OUT_DIR:-out}
TOP=$(pwd)
OS=linux

build_soong=1
clean=t
[[ "${1:-}" != '--resume' ]] || clean=''

# Use toybox and other prebuilts even outside of the build (test running, go, etc)
export PATH=${TOP}/prebuilts/build-tools/path/${OS}-x86:$PATH

if [ -n ${build_soong} ]; then
    SOONG_OUT=${OUT_DIR}/soong
    SOONG_HOST_OUT=${OUT_DIR}/soong/host/${OS}-x86
    [[ -z "${clean}" ]] || rm -rf ${SOONG_OUT}
    mkdir -p ${SOONG_OUT}
    cat > ${SOONG_OUT}/soong.variables << EOF
{
    "Allow_missing_dependencies": true,
    "HostArch":"x86_64"
}
EOF
    SOONG_BINARIES=(
        dtc
        lz4
    )

    binaries="${SOONG_BINARIES[@]/#/${SOONG_HOST_OUT}/bin/}"

    # Build everything
    build/soong/soong_ui.bash --make-mode --skip-make ${binaries}

    # Stage binaries
    mkdir -p ${SOONG_OUT}/dist/bin
    cp ${binaries} ${SOONG_OUT}/dist/bin/

    # Package prebuilts
    (
        cd ${SOONG_OUT}/dist
        zip -qryX build-prebuilts.zip *
    )
fi

if [ -n "${DIST_DIR}" ]; then
    mkdir -p ${DIST_DIR} || true

    if [ -n ${build_soong} ]; then
        cp ${SOONG_OUT}/dist/build-prebuilts.zip ${DIST_DIR}/
    fi
fi

exit 0
