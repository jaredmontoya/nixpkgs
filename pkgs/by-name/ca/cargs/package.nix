{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "cargs";
  version = "1.0.3";

  src = fetchFromGitHub {
    owner = "likle";
    repo = "cargs";
    tag = "v${finalAttrs.version}";
    hash = "sha256-iQHZRYcCzdW+Jlkv0tmPRF05HnJ/7LrEdkoR6vJk6iM=";
  };

  nativeBuildInputs = [ cmake ];

  cmakeFlags = [
    (lib.cmakeBool "BUILD_SHARED_LIBS" (!stdenv.hostPlatform.isStatic))
    (lib.cmakeBool "ENABLE_TESTS" false)
  ];

  meta = {
    description = "A lightweight argument parser library for C";
    homepage = "https://github.com/likle/cargs";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ ];
  };
})
