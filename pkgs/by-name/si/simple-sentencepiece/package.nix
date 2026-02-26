{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "simple-sentencepiece";
  version = "0.7";

  src = fetchFromGitHub {
    owner = "pkufool";
    repo = "simple-sentencepiece";
    tag = "v${finalAttrs.version}";
    hash = "sha256-HRi8XsMWD6Tkf1nojzzbafSKTIEhQCRSki/IQrfOB4w=";
  };

  # Upstream installs the library to the prefix root and does not install
  # headers.  Fix both issues.
  postPatch = ''
    substituteInPlace ssentencepiece/csrc/CMakeLists.txt \
      --replace-fail \
        'install(TARGETS ssentencepiece_core DESTINATION ''${CMAKE_INSTALL_PREFIX})' \
        'include(GNUInstallDirs)
    install(TARGETS ssentencepiece_core
      LIBRARY DESTINATION ''${CMAKE_INSTALL_LIBDIR}
      ARCHIVE DESTINATION ''${CMAKE_INSTALL_LIBDIR})
    install(FILES ssentencepiece.h darts.h threadpool.h
      DESTINATION ''${CMAKE_INSTALL_INCLUDEDIR}/ssentencepiece)'
  '';

  nativeBuildInputs = [ cmake ];

  cmakeFlags = [
    (lib.cmakeBool "SBPE_BUILD_PYTHON" false)
    (lib.cmakeBool "SBPE_ENABLE_TESTS" false)
    (lib.cmakeBool "BUILD_SHARED_LIBS" (!stdenv.hostPlatform.isStatic))
  ];

  meta = {
    description = "A simple sentencepiece encoder/decoder library";
    homepage = "https://github.com/pkufool/simple-sentencepiece";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ ];
  };
})
