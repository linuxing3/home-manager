{
  lib,
  stdenv,
  fetchFromGitHub,
}:
  stdenv.mkDerivation {
    pname = "doxx";
    version = "0.1.2";

    src = fetchFromGitHub {
      owner = "bgreenwell";
      repo = "doxx";
      tag = "v0.1.2";
      hash = "sha256-Vrr7KR4yMH+IZ56IUTp9eAhxEtiXx+ppleUd7jSLzxc=";
    };

    meta = {
      homepage = "https://github.com/bgreenwell/doxx";
      description = "CLI utility to view docx";
      license = lib.licenses.mit;
      maintainers = [];
    };
  }
