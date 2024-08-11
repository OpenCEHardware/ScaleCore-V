{ buildPythonPackage
, callPackage
, fetchPypi
, lib
, setuptools
, setuptools-scm
}:
let
  pname = "peakrdl-ipxact";
  version = "3.4.4";
in
buildPythonPackage {
  inherit pname version;
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-K6FDGy7vIeMBKOLPouUhOZDauy4Mg2uCm2a4QfEoO5c=";
  };

  propagatedBuildInputs = [
    (callPackage ./systemrdl-compiler.nix { })
  ];

  propagatedNativeBuildInputs = [
    setuptools
    setuptools-scm
  ];

  meta = {
    description = "Import and export IP-XACT XML to/from the systemrdl-compiler register model";
    changelog = "https://github.com/SystemRDL/${pname}/releases/tag/v${version}";
    homepage = "https://github.com/SystemRDL/${pname}";
    license = lib.licenses.gpl3;
  };
}
