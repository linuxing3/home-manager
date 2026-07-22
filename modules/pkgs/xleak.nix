{ lib, stdenv, fetchFromGitHub, ... }:

  stdenv.mkDerivation {
    pname = "xleak";
    version = "0.1.2";

    src = fetchFromGitHub {
      owner = "bgreenwell";
      repo = "xleak";
      tag = "v0.1.2";
      hash = "sha256-Vrr7KR4yMH+IZ56IUTp9eAhxEtiXx+ppleUd7jSLzxc=";
    };

    meta = {
      homepage = "https://github.com/bgreenwell/xleak";
      description = "CLI utility to view excel";
      license = lib.licenses.mit;
      maintainers = [];
    };
  }
