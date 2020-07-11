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
        abidiff
        abidw
        blk_alloc_to_base_fs
        build_image
        depmod
        dtc
        e2fsck
        e2fsdroid
        lz4
        mkdtboimg.py
        mkuserimg_mke2fs
        pahole
        simg2img
        swig
        tune2fs
        ufdt_apply_overlay
    )

    SOONG_LIBRARIES=(
        libcrypto-host.so
    )

    binaries="${SOONG_BINARIES[@]/#/${SOONG_HOST_OUT}/bin/}"
    libraries="${SOONG_LIBRARIES[@]/#/${SOONG_HOST_OUT}/lib64/}"

    # Build everything
    build/soong/soong_ui.bash --make-mode --skip-make ${binaries} ${libraries}

    # Stage binaries
    mkdir -p ${SOONG_OUT}/dist/bin
    cp ${binaries} ${SOONG_OUT}/dist/bin/
    cp -R ${SOONG_HOST_OUT}/lib* ${SOONG_OUT}/dist/

    # Stage include files
    include_dir=${SOONG_OUT}/dist/include
    mkdir -p ${include_dir}/openssl/
    cp -a ${TOP}/external/boringssl/include/openssl/* ${include_dir}/openssl/

    # Patch dist dir
    (
      cd ${SOONG_OUT}/dist/
      ln -sf libcrypto-host.so lib64/libcrypto.so
    )

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
