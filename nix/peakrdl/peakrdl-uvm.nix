{ buildPythonPackage
, callPackage
, fetchPypi
, jinja2
, lib
, setuptools
, setuptools-scm
}:
let
  pname = "peakrdl-uvm";
  version = "2.3.0";
in
buildPythonPackage {
  inherit pname version;
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-7Bik/IfQIB/gPr4N4lmmt/Ir494daQj4C84eFBa8nPI=";
  };

  propagatedBuildInputs = [
    (callPackage ./systemrdl-compiler.nix { })
    jinja2
  ];

  propagatedNativeBuildInputs = [
    setuptools
    setuptools-scm
  ];

  meta = {
    description = "Generate UVM register model from compiled SystemRDL input";
    changelog = "https://github.com/SystemRDL/${pname}/releases/tag/v${version}";
    homepage = "https://github.com/SystemRDL/${pname}";
    license = lib.licenses.gpl3;
  };
}
