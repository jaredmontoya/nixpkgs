{
  lib,
  stdenv,
  fetchFromGitHub,
  cmake,
  kissfft,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "kaldi-native-fbank";
  version = "1.22.3";

  src = fetchFromGitHub {
    owner = "csukuangfj";
    repo = "kaldi-native-fbank";
    tag = "v${finalAttrs.version}";
    hash = "sha256-Wu4wM52T6NoQ1t5/iAyPtkEGnZki5P0jx0eYMFZMb5o=";
  };

  nativeBuildInputs = [ cmake ];

  cmakeFlags = [
    (lib.cmakeBool "KALDI_NATIVE_FBANK_BUILD_PYTHON" false)
    (lib.cmakeBool "KALDI_NATIVE_FBANK_BUILD_TESTS" false)
    (lib.cmakeBool "KALDI_NATIVE_FBANK_ENABLE_CHECK" false)
    (lib.cmakeBool "BUILD_SHARED_LIBS" (!stdenv.hostPlatform.isStatic))
    # Use nixpkgs kissfft source instead of FetchContent download.
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_KISSFFT" "${kissfft.src}")
  ];

  meta = {
    description = "Kaldi-compatible online & offline feature extraction with C++ and Python APIs";
    homepage = "https://github.com/csukuangfj/kaldi-native-fbank";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ ];
  };
})
