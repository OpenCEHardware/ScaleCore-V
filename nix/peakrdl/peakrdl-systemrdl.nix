{ buildPythonPackage
, callPackage
, fetchPypi
, lib
, setuptools
, setuptools-scm
}:
let
  pname = "peakrdl-systemrdl";
  version = "0.3.0";
in
buildPythonPackage {
  inherit pname version;
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-ogNptwsAkgoTIyf55J6qtnMqbs1wHpjstuy/KrVwRX4=";
  };

  propagatedBuildInputs = [
    (callPackage ./systemrdl-compiler.nix { })
  ];

  propagatedNativeBuildInputs = [
    setuptools
    setuptools-scm
  ];

  meta = {
    description = "Export a compiled register model into SystemRDL code";
    changelog = "https://github.com/SystemRDL/${pname}/releases/tag/v${version}";
    homepage = "https://github.com/SystemRDL/${pname}";
    license = lib.licenses.gpl3;
  };
}
