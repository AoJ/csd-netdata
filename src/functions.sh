#!/bin/bash


ROOT="$(cd "${BASH_SOURCE%/*}"/..; pwd)"
SRC="${ROOT}/src"
SRC_EXTERNAL="${ROOT}/src_external"
TARGET_PARCEL="${ROOT}/target/parcel"
TARGET_CSD="${ROOT}/target/csd"

export ROOT SRC SRC_EXTERNAL TARGET TARGET_PARCEL TARGET_CSD


cdate() {
    echo -en "$(date -u +"%Y-%m-%-dT%H-%M-%SZ")"
}

error() {
    >&2 echo -e "$(cdate) ERROR $*"
    return 255
}

info() {
    [[ -z "${*// }" ]] && return
    >&1 echo -e "$(cdate) INFO $*"
}


function init() {
    mkdir -p "$SRC_EXTERNAL" "$TARGET_PARCEL"
}

md5sum="$(
       command -v md5sum 2>/dev/null                        \
    || command -v md5 2>/dev/null                           \
)" || error "Can't find md5sum bin"


sha1sum="$(
       command -v sha1sum 2>/dev/null                       \
    || command -v shasum 2>/dev/null                        \
)" || error "Can't find shasum bin"


function build_cm_ext() {
    dir="${SRC_EXTERNAL}/cm_ext"

    if [[ ! -d "$dir" ]]; then
        git clone --branch "$CM_EXT_BRANCH" "$CM_EXT_GIT_URL" "$dir"
    else
        cd "${dir}"
        git fetch origin
    fi

    if [[ ! -e "${dir}/validator/target/validator.jar" ]]; then
        cd "$dir"
        git checkout "$CM_EXT_BRANCH"

        if [[ ! -x "${SRC_EXTERNAL}/maven/bin/mvn" ]]; then
            download maven "$MAVEN_URL" "$MAVEN_SHA"
            chmod +x "${SRC_EXTERNAL}/maven/bin/mvn"
            cd "$dir"
        fi
        "${SRC_EXTERNAL}/maven/bin/mvn" package
    fi
}


function download() {
    local name="${1}"
    local url="${2}"
    local sha="${3}"
    local tar="${name}.tar.gz"
    local file_path="${SRC_EXTERNAL}/${tar}"
    local dir_path="${SRC_EXTERNAL}/${name}"

    if [ ! -f "${file_path}" ]; then
        info "downloading from $url"
        wget -O "${file_path}.tmp" "${url}"
        mv "${file_path}.tmp" "${file_path}"
    fi

    echo -e "${sha}  ${file_path}" > "${file_path}.sha1"
    $sha1sum -c "${file_path}.sha1" || {
        error "sha1 hash of file '$file_path' does not match '$sha'"
        return 255
    }
    rm -f "${file_path}.sha1"

    # remove all target directory if we just download a new file
    if [[ -d "$dir_path" ]]; then
        info "removing old extracted dir '$dir_path'"
        rm -rf "$dir_path"
    fi

    # extract
    if ! [[ -d "$dir_path" ]]; then
        info extracting file "$tar" to "$dir_path"
        mkdir -p "$dir_path"
        tar --strip 1 -C "$dir_path" -xzf "$file_path"
        
    else
        info dir "$dir_path" already extracted
    fi

    cd "$dir_path"
}


function build_parcel() {
    name="$1"
    name_norm="$(echo "$name" | awk '{print toupper($0)}')"
    version="$2"
    target_dir="${TARGET_PARCEL:?}/${name_norm}-${version}"
    parcel="${target_dir}-el7.parcel"

    # TODO delete only if there is some changes
    if [[ -e "$parcel" ]]; then
        info "deleting old parcel $parcel"
        rm -f "$parcel"
    fi

    if [[ -e "$target_dir" ]]; then
        rm -fr "$target_dir"
    fi

    cp -rp  "${TARGET_PARCEL}/${name}" "$target_dir"
    ##ln -f -s "${target}/${name}" "$target_dir"

    info creating pracel metadata
    cp -f -r "${SRC}/parcel/${name}/meta" "${target_dir}"
    sed -i -e "s/%VERSION%/${version}/"  "${target_dir}/meta/parcel.json"
    java -jar "${SRC_EXTERNAL}/cm_ext/validator/target/validator.jar" -d "${target_dir}"

    info generating parcel
    ##cd "${target}" && tar zcvhf "${parcel}" "${name_norm}-${version}" >/dev/null
    cd "${TARGET_PARCEL}" && tar zcvf "${parcel}" "${name_norm}-${version}" >/dev/null
    java -jar "${SRC_EXTERNAL}/cm_ext/validator/target/validator.jar" -f "${parcel}"

    $sha1sum "${parcel}" | cut -f1 -d " " > "${parcel}.sha"

    rm -rf "$target_dir"
    rm -rf "${TARGET_PARCEL:?}/${name}"
    info "parcel $parcel for $name@$version created"
}


function build_csd() {
    name="$1"
    version="$2"
    csd_version="$3"
    dep="${4:-}"

    if [[ -d "${TARGET_CSD}/${name}-${version}" ]]; then
        info delete old csd working dir
        rm -rf "${TARGET_CSD}/${name}-${version}"
    fi

    mkdir -p "${TARGET_CSD:?}/${name}-${version}"
    cp -f -r "${SRC}/csd/${name}/"* "${TARGET_CSD}/${name}-${version}/"
    sed -i -e "s/%VERSION%/${csd_version}/" "${TARGET_CSD}/${name}-${version}/descriptor/service.sdl"

    info "building and validation csd ${name}@${version}"
    java -jar "${SRC_EXTERNAL}/cm_ext/validator/target/validator.jar" -s "${TARGET_CSD}/${name}-${version}/descriptor/service.sdl" -l "$dep"
    jar -cvf "${TARGET_CSD}/${name}-${version}.jar" -C "${TARGET_CSD}/${name}-${version}" .

    info cleaning csd working dir
    rm -rf "${TARGET_CSD:?}/${name}-${version}"
}


