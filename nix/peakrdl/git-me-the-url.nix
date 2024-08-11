{ buildPythonPackage
, callPackage
, fetchPypi
, gitpython
, lib
, setuptools
, setuptools-scm
}:
let
  pname = "git-me-the-url";
  version = "2.1.0";
in
buildPythonPackage {
  inherit pname version;
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-q/j0sQ3jk/6GkiXgzWb0DeGGSAbNHaKXQCa56RESwDg=";
  };

  propagatedBuildInputs = [
    gitpython
  ];

  propagatedNativeBuildInputs = [
    setuptools
    setuptools-scm
  ];

  meta = {
    description = " Create shareable URLs to your Git files";
    changelog = "https://github.com/amykyta3/git-me-the-url/releases/tag/v${version}";
    homepage = "https://github.com/amykyta3/git-me-the-url";
    license = lib.licenses.gpl3;
  };
}
