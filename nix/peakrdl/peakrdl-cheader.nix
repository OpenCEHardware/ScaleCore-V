{ buildPythonPackage
, callPackage
, fetchPypi
, jinja2
, lib
, setuptools
, setuptools-scm
}:
let
  pname = "peakrdl-cheader";
  version = "1.0.0";
in
buildPythonPackage {
  inherit pname version;
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-wKJ5UPMLvlNwG1mWOALe8Urodu2kQVJ4rTWEEaVj5Mg=";
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
    description = "Generate C Header files from a SystemRDL register model";
    changelog = "https://github.com/SystemRDL/${pname}/releases/tag/v${version}";
    homepage = "https://github.com/SystemRDL/${pname}";
    license = lib.licenses.gpl3;
  };
}
