{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
}:

let
  # kaldifst depends on a custom OpenFST fork by csukuangfj that is NOT
  # interchangeable with upstream OpenFST or the nixpkgs openfst package.
  # It disables most features, renames output libs with a kaldifst_ prefix,
  # and only enables HAVE_SCRIPT.
  openfst-src = fetchFromGitHub {
    owner = "csukuangfj";
    repo = "openfst";
    tag = "sherpa-onnx-2024-06-13";
    hash = "sha256-tFdt7jVV9UJUVVywHWVgSC5RtfoFABnmks8zec0vpdo=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "kaldifst";
  version = "1.7.17";

  src = fetchFromGitHub {
    owner = "k2-fsa";
    repo = "kaldifst";
    tag = "v${finalAttrs.version}";
    hash = "sha256-tHDkQP9FVgDr9g4mTsgBTfA8RSV+AY8oT8kLiUKd1rg=";
  };

  nativeBuildInputs = [ cmake ];

  # The openfst cmake in kaldifst uses PATCH_COMMAND with sed to disable
  # tests.  When we provide FETCHCONTENT_SOURCE_DIR_OPENFST, the patch
  # step is skipped, so we must apply these patches ourselves.
  # Copy the openfst source to a writable location and patch it.
  #
  # Also fix a bug where fstscript is referenced in install() even when
  # KALDIFST_BUILD_PYTHON is OFF and the target is not built (due to
  # EXCLUDE_FROM_ALL on the openfst subdirectory).
  postPatch = ''
    substituteInPlace cmake/openfst.cmake \
      --replace-fail \
        'install(TARGETS fst fstscript DESTINATION lib)' \
        'install(TARGETS fst DESTINATION lib)
    if(KALDIFST_BUILD_PYTHON)
      install(TARGETS fstscript DESTINATION lib)
    endif()'
  '';

  preConfigure = ''
    local openfst_dir="$NIX_BUILD_TOP/openfst-patched"
    cp -r ${openfst-src} "$openfst_dir"
    chmod -R u+w "$openfst_dir"
    sed -i 's/enable_testing()//g' "$openfst_dir/src/CMakeLists.txt"
    sed -i 's/add_subdirectory(test)//g' "$openfst_dir/src/CMakeLists.txt"
    sed -i '/message/d' "$openfst_dir/src/script/CMakeLists.txt"
    cmakeFlagsArray+=("-DFETCHCONTENT_SOURCE_DIR_OPENFST=$openfst_dir")
  '';

  cmakeFlags = [
    (lib.cmakeBool "KALDIFST_BUILD_PYTHON" false)
    (lib.cmakeBool "KALDIFST_BUILD_TESTS" false)
    (lib.cmakeBool "BUILD_SHARED_LIBS" (!stdenv.hostPlatform.isStatic))
  ];

  meta = {
    description = "FST-based decoder library for Kaldi-compatible speech recognition";
    homepage = "https://github.com/k2-fsa/kaldifst";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ ];
  };
})
