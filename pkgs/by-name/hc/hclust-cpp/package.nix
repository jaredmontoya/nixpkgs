{
  lib,
  stdenv,
  fetchFromGitHub,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "hclust-cpp";
  version = "0-unstable-2024-09-29";

  src = fetchFromGitHub {
    owner = "csukuangfj";
    repo = "hclust-cpp";
    tag = "2024-09-29";
    hash = "sha256-vAZ52UPm2fJNDp9+Ko/b1ir+C+6/8rypLVsT8uBdgfQ=";
  };

  # No build system upstream — this is a header/source library.
  # Install headers for downstream consumers to compile from source.
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    install -Dm644 fastcluster.h "$out/include/hclust-cpp/fastcluster.h"
    install -Dm644 fastcluster.cpp "$out/include/hclust-cpp/fastcluster.cpp"
    install -Dm644 fastcluster_dm.cpp "$out/include/hclust-cpp/fastcluster_dm.cpp"
    install -Dm644 fastcluster_R_dm.cpp "$out/include/hclust-cpp/fastcluster_R_dm.cpp"
    install -Dm644 fastcluster-all-in-one.h "$out/include/hclust-cpp/fastcluster-all-in-one.h"

    runHook postInstall
  '';

  meta = {
    description = "C++ library for fast hierarchical clustering";
    homepage = "https://github.com/csukuangfj/hclust-cpp";
    license = lib.licenses.bsd2;
    platforms = lib.platforms.all;
    maintainers = with lib.maintainers; [ ];
  };
})
