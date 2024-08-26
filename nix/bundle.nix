{ bashInteractive
, coreutils-full
, diffutils
, findutils
, gnugrep
, lib
, name
, shell
, symlinkJoin
, writeShellScriptBin
}:
with lib; let
  bundleName = "bundle-${name}";
  makeInputs = inputs: escapeShellArg (concatMapStringsSep " " toString inputs);

  path = symlinkJoin {
    name = "bundle-${name}-path";

    paths = [
      bashInteractive
      coreutils-full
      diffutils
      findutils
      gnugrep
    ];
  };
in
writeShellScriptBin bundleName ''
  if [ -z "''${__IN_INTERACTIVE:-}" ]; then
    __IN_INTERACTIVE=1 exec ${getExe bashInteractive} --init-file ${placeholder "out"}/bin/${bundleName} -i
  fi

  unset __IN_INTERACTIVE

  if [ -n "$APPIMAGE" ]; then
    export PATH="${makeBinPath [ path ]}"
    cd

    if [ "$PWD" != "$APPIMAGE.home" ]; then
      echo "$(basename "$APPIMAGE"): error: you need to mkdir $APPIMAGE.home"
      exit 1
    fi
  fi

  NIX_BUILD_TOP="$(mktemp --tmpdir -d run-bundle.XXXXXX)"
  trap 'rm -df -- "$NIX_BUILD_TOP"' EXIT

  out="$PWD/outputs/out"
  buildInputs=${makeInputs shell.buildInputs}
  nativeBuildInputs=${makeInputs shell.nativeBuildInputs}
  source ${shell.stdenv}/setup

  ${shell.shellHook}
''
