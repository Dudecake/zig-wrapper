#!/bin/bash

set -e

if [[ ! -f build.zig ]]; then
  echo "No 'build.zig' file present" >&2
  if [[ "${1}" = "-f" || "${1}" = "--force" ]]; then
    echo "'force' given, setting up wrapper anyway." >&1
  else
    exit 1
  fi
fi

if [[ -f zigw ]]; then
  echo "Wrapper already installed" >&2
  [[ "$(basename $PWD)" = "zig-wrapper" ]] || exit 0
fi

[[ -d .zig/wrapper ]] || mkdir -p .zig/wrapper
cat << EOF > .zig/wrapper/zig-wrapper.properties
zig_version=0.13.0
EOF

wrapper_version="0.0.5"
cat << EOF > zigw
#!/bin/sh

set -e

script_dir=\$( cd -- "\$( dirname -- "\${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. ${script_dir}/.zig/wrapper/zig-wrapper.properties
wrapper_directory="\${HOME}/.cache/zig/wrapper/\${zig_version}"
if [[ "\${1}" = "wrapper" ]]; then
  case "\${2}" in
    version)
      cat << EOV >&2
Zig version:      \${zig_version}
Zig home:         \${wrapper_directory}
Wrapper version:  ${wrapper_version}
EOV
      ;;
    # update)
    #   ;;
    *)
      cat << EOH >&2
info: Usage: \${0} wrapper [command]

Commands:
  version     Print version number and exit
EOH
      ;;
  esac
else
  if [[ ! -f \${wrapper_directory}/zig || "\$(sh -c "\${wrapper_directory}/zig version" 2> /dev/null)" != "\${zig_version}" ]]; then
    [[ -d \${wrapper_directory} ]] || mkdir -p \${wrapper_directory}
    arch="\$(uname -m)"
    curl -L https://ziglang.org/download/\${zig_version}/zig-linux-\${arch}-\${zig_version}.tar.xz | bsdtar -C \${wrapper_directory} --strip-components 1 -xf -
  fi

  exec \${wrapper_directory}/zig "\$@"
fi
EOF
chmod +x ./zigw

cat << EOF > zlsw
#!/bin/sh

set -e

script_dir=\$( cd -- "\$( dirname -- "\${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

. ${script_dir}/.zig/wrapper/zig-wrapper.properties
wrapper_directory="\${HOME}/.cache/zig/wrapper/\${zig_version}"
if [[ "\${1}" = "wrapper" ]]; then
  case "\${2}" in
    version)
      cat << EOV >&2
Zig version:      \${zig_version}
Zig home:         \${wrapper_directory}
Wrapper version:  ${wrapper_version}
EOV
      ;;
    # update)
    #   ;;
    *)
      cat << EOH >&2
info: Usage: \${0} wrapper [command]

Commands:
  version     Print version number and exit
EOH
      ;;
  esac
else
  if [[ ! -f \${wrapper_directory}/zls || "\$(sh -c "\${wrapper_directory}/zls version" 2> /dev/null)" != "\${zig_version}" ]]; then
    [[ -d \${wrapper_directory} ]] || mkdir -p \${wrapper_directory}
    arch="\$(uname -m)"
    curl -L https://github.com/zigtools/zls/releases/download/\${zig_version}/zls-\${arch}-linux.tar.xz | bsdtar -C \${wrapper_directory} -xf - zls
  fi

  exec \${wrapper_directory}/zls "\$@"
EOF
chmod +x ./zlsw
