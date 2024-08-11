{ buildPythonPackage
, callPackage
, fetchPypi
, jinja2
, lib
, markdown
, python-markdown-math
, setuptools
, setuptools-scm
}:
let
  pname = "peakrdl-html";
  version = "2.10.1";
in
buildPythonPackage {
  inherit pname version;
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-lV6xxXUwjTUpNiLfOq7CY1XOjlzfbIj7ao/eIWrILxw=";
  };

  propagatedBuildInputs = [
    (callPackage ./systemrdl-compiler.nix { })
    (callPackage ./git-me-the-url.nix { })
    jinja2
    markdown
    python-markdown-math
  ];

  propagatedNativeBuildInputs = [
    setuptools
    setuptools-scm
  ];

  meta = {
    description = "Generate address space documentation HTML from compiled SystemRDL input";
    changelog = "https://github.com/SystemRDL/${pname}/releases/tag/v${version}";
    homepage = "https://github.com/SystemRDL/${pname}";
    license = lib.licenses.gpl3;
  };
}
