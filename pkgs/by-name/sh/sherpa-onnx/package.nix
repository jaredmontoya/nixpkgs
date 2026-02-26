{
  lib,
  config,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  cmake,
  python3Packages ? { },
  nix-update-script,

  # dependencies
  alsa-lib,
  eigen,
  gtest,
  hclust-cpp,
  kaldi-decoder,
  kaldi-native-fbank,
  kaldifst,
  kissfft,
  nlohmann_json,
  onnxruntime,
  simple-sentencepiece,

  # optional features
  cudaSupport ? config.cudaSupport,
  websocketSupport ? true,
  pythonSupport ? true,

}:

let
  # csukuangfj's openfst fork — NOT interchangeable with upstream openfst.
  # sherpa-onnx uses a different tag (2024-06-19) than kaldifst (2024-06-13).
  openfst-src = fetchFromGitHub {
    owner = "csukuangfj";
    repo = "openfst";
    tag = "sherpa-onnx-2024-06-19";
    hash = "sha256-EK8ZBmFZKLrOwSXACMMzOAV95cOyigw99VEYHBJnkHI=";
  };

  # Pre-fetched dependencies for cmake FetchContent that have no
  # corresponding nixpkgs package (custom forks, pinned versions, or
  # optional websocket deps).
  cache = [
    {
      name = "espeak-ng-f6fed6c58b5e0998b8e68c6610125e2d07d595a7.zip";
      src = fetchurl {
        url = "https://github.com/csukuangfj/espeak-ng/archive/f6fed6c58b5e0998b8e68c6610125e2d07d595a7.zip";
        hash = "sha256-cMv0BQ56AUquGRQLBeVySdpHIPVhKEWfvjqTvq+XGuY=";
      };
    }
    {
      name = "piper-phonemize-78a788e0b719013401572d70fef372e77bff8e43.zip";
      src = fetchurl {
        url = "https://github.com/csukuangfj/piper-phonemize/archive/78a788e0b719013401572d70fef372e77bff8e43.zip";
        hash = "sha256-iWQaRkiaSJh1RkPOV72pybVLTKRkhf3AK/DchLhmZF0=";
      };
    }
  ]
  ++ lib.optionals websocketSupport [
    {
      name = "asio-asio-1-24-0.tar.gz";
      src = fetchurl {
        url = "https://github.com/chriskohlhoff/asio/archive/refs/tags/asio-1-24-0.tar.gz";
        hash = "sha256-y8qroPZnInh7Gnwzr+G++zoBK1rzrX2n/w9rjJt6ils=";
      };
    }
    {
      name = "websocketpp-b9aeec6eaf3d5610503439b4fae3581d9aff08e8.zip";
      src = fetchurl {
        url = "https://github.com/zaphoyd/websocketpp/archive/b9aeec6eaf3d5610503439b4fae3581d9aff08e8.zip";
        hash = "sha256-E4UTXt6Bkaf7757ICZ48Wmc9SN8MFDlYIWzRaQVn9YM=";
      };
    }
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "sherpa-onnx";
  version = "1.12.25";

  src = fetchFromGitHub {
    owner = "k2-fsa";
    repo = "sherpa-onnx";
    tag = "v${finalAttrs.version}";
    hash = "sha256-NRiqk/YMk3vhlBRrmeMsJ544Xv1b7GCSMQD2ec+xi+k=";
  };

  outputs = [ "out" ] ++ lib.optionals pythonSupport [ "python" ];

  separateDebugInfo = true;

  patches = [
    ./espeak.patch
  ];

  nativeBuildInputs = [
    cmake
  ]
  ++ lib.optionals pythonSupport (
    with python3Packages;
    [
      python
    ]
  );

  buildInputs = [
    onnxruntime
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    alsa-lib
  ];

  nativeCheckInputs = lib.optionals pythonSupport (
    with python3Packages;
    [
      numpy
      soundfile
    ]
  );

  # Copy pre-fetched tarballs so cmake FetchContent finds them locally.
  # Prepare a writable copy of the openfst fork with patches applied
  # (FETCHCONTENT_SOURCE_DIR_* skips PATCH_COMMAND, so we do it here).
  preConfigure = ''
    ${lib.concatMapStringsSep "\n" (s: "cp ${s.src} ./${s.name}") cache}

    local openfst_dir="$NIX_BUILD_TOP/openfst-patched"
    cp -r ${openfst-src} "$openfst_dir"
    chmod -R u+w "$openfst_dir"
    sed -i 's/enable_testing()//g' "$openfst_dir/src/CMakeLists.txt"
    sed -i 's/add_subdirectory(test)//g' "$openfst_dir/src/CMakeLists.txt"
    sed -i '/message/d' "$openfst_dir/src/script/CMakeLists.txt"
    cmakeFlagsArray+=("-DFETCHCONTENT_SOURCE_DIR_OPENFST=$openfst_dir")
  '';

  cmakeFlags = [
    (lib.cmakeBool "FETCHCONTENT_QUIET" false)
    (lib.cmakeBool "BUILD_SHARED_LIBS" true)
    (lib.cmakeBool "SHERPA_ONNX_ENABLE_WEBSOCKET" websocketSupport)
    (lib.cmakeBool "SHERPA_ONNX_ENABLE_PORTAUDIO" false)
    (lib.cmakeBool "SHERPA_ONNX_ENABLE_PYTHON" pythonSupport)
    (lib.cmakeBool "SHERPA_ONNX_BUILD_C_API_EXAMPLES" false)
    (lib.cmakeBool "SHERPA_ONNX_ENABLE_TESTS" true)
    (lib.cmakeFeature "onnxruntime_SOURCE_DIR" "${onnxruntime.dev}")
    (lib.cmakeBool "SHERPA_ONNX_ENABLE_GPU" cudaSupport)
    # Use nixpkgs sources instead of vendored downloads.
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_JSON" "${nlohmann_json.src}")
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_EIGEN" "${eigen.src}")
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_GOOGLETEST" "${gtest.src}")
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_KALDI_DECODER" "${kaldi-decoder.src}")
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_KALDIFST" "${kaldifst.src}")
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_KALDI_NATIVE_FBANK" "${kaldi-native-fbank.src}")
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_SIMPLE-SENTENCEPIECE" "${simple-sentencepiece.src}")
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_HCLUST_CPP" "${hclust-cpp.src}")
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_KISSFFT" "${kissfft.src}")
    "-Wno-dev"
  ]
  ++ lib.optionals pythonSupport [
    (lib.cmakeFeature "PYTHON_EXECUTABLE" (lib.getExe python3Packages.python))
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_PYBIND11" "${python3Packages.pybind11.src}")
  ];

  # Place the native extension alongside the Python source so that both
  # checkPhase and postInstall can find a complete sherpa_onnx package.
  # Upstream's __init__.py imports from sherpa_onnx.lib._sherpa_onnx.
  postBuild = lib.optionalString pythonSupport ''
    mkdir -p ../sherpa-onnx/python/sherpa_onnx/lib
    cp lib/_sherpa_onnx*.so ../sherpa-onnx/python/sherpa_onnx/lib/
  '';

  doCheck = true;

  # Use ctest directly because the default `make check` target includes clang-tidy.
  checkPhase = ''
    runHook preCheck
    ctest --output-on-failure
    runHook postCheck
  '';

  postInstall = lib.optionalString pythonSupport ''
    mkdir -p $python
    cp -r ../sherpa-onnx/python/sherpa_onnx $python/
    rm $out/lib/_sherpa_onnx*.so
  '';

  passthru = {
    updateScript = nix-update-script { };
  };

  meta = {
    description = "Speech-to-text, text-to-speech, and speaker recognition using next-gen Kaldi with onnxruntime";
    homepage = "https://github.com/k2-fsa/sherpa-onnx";
    changelog = "https://github.com/k2-fsa/sherpa-onnx/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ jaredmontoya ];
    mainProgram = "sherpa-onnx";
  };
})
