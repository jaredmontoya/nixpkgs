{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  cmake,
  pkg-config,
  python3Packages ? { },
  nix-update-script,

  # dependencies
  alsa-lib,
  eigen,
  gtest,
  nlohmann_json,
  onnxruntime,

  # optional CUDA support
  config,
  cudaSupport ? config.cudaSupport,
  cudaPackages ? { },

  # optional features
  websocketSupport ? true,
  pythonSupport ? false,

}:

let
  effectiveStdenv = if cudaSupport then cudaPackages.backendStdenv else stdenv;

  # Pre-fetched dependencies for cmake FetchContent.
  # These are copied into the source tree so cmake finds them locally
  # instead of trying to download them (which fails in the sandbox).
  cache = [
    {
      name = "espeak-ng-f6fed6c58b5e0998b8e68c6610125e2d07d595a7.zip";
      src = fetchurl {
        url = "https://github.com/csukuangfj/espeak-ng/archive/f6fed6c58b5e0998b8e68c6610125e2d07d595a7.zip";
        hash = "sha256-cMv0BQ56AUquGRQLBeVySdpHIPVhKEWfvjqTvq+XGuY=";
      };
    }
    {
      name = "kaldi-native-fbank-1.22.3.tar.gz";
      src = fetchurl {
        url = "https://github.com/csukuangfj/kaldi-native-fbank/archive/refs/tags/v1.22.3.tar.gz";
        hash = "sha256-kXbMZvx84e34XPNVsG4yDFfbYpffdCd/V1GDRoiTz2E=";
      };
    }
    {
      name = "simple-sentencepiece-0.7.tar.gz";
      src = fetchurl {
        url = "https://github.com/pkufool/simple-sentencepiece/archive/refs/tags/v0.7.tar.gz";
        hash = "sha256-F0ioIgYKNbqp9mCfhO/I61TcDnS57OPYI2e3EZ/cda8=";
      };
    }
    {
      name = "kaldifst-1.7.17.tar.gz";
      src = fetchurl {
        url = "https://github.com/k2-fsa/kaldifst/archive/refs/tags/v1.7.17.tar.gz";
        hash = "sha256-xLcBojpAC9qAMlhrAsfg1egTp2WDLfYMI+bfnmKwEPQ=";
      };
    }
    {
      name = "kaldi-decoder-0.2.11.tar.gz";
      src = fetchurl {
        url = "https://github.com/k2-fsa/kaldi-decoder/archive/refs/tags/v0.2.11.tar.gz";
        hash = "sha256-hcpGJTVZJUHrW6bSGEMAnPNHOPUbKLcfhIgqNpS1KL8=";
      };
    }
    {
      name = "cargs-1.0.3.tar.gz";
      src = fetchurl {
        url = "https://github.com/likle/cargs/archive/refs/tags/v1.0.3.tar.gz";
        hash = "sha256-3bolvTXpxsdbxwbBJgAbjOjghNQO83BQ5qppY+g264s=";
      };
    }
    {
      name = "piper-phonemize-78a788e0b719013401572d70fef372e77bff8e43.zip";
      src = fetchurl {
        url = "https://github.com/csukuangfj/piper-phonemize/archive/78a788e0b719013401572d70fef372e77bff8e43.zip";
        hash = "sha256-iWQaRkiaSJh1RkPOV72pybVLTKRkhf3AK/DchLhmZF0=";
      };
    }
    {
      name = "openfst-sherpa-onnx-2024-06-19.tar.gz";
      src = fetchurl {
        url = "https://github.com/csukuangfj/openfst/archive/refs/tags/sherpa-onnx-2024-06-19.tar.gz";
        hash = "sha256-XJjoLMUJxWGFAt3khguOoE2EOFDtV+bWtZC2RLJohT0=";
      };
    }
    {
      name = "hclust-cpp-2024-09-29.tar.gz";
      src = fetchurl {
        url = "https://github.com/csukuangfj/hclust-cpp/archive/refs/tags/2024-09-29.tar.gz";
        hash = "sha256-q6tRRIo8tUJyquB1IpcDBuCyzGR51Z17Geeu5NbO3TM=";
      };
    }
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
    {
      name = "kissfft-febd4caeed32e33ad8b2e0bb5ea77542c40f18ec.zip";
      src = fetchurl {
        url = "https://github.com/mborgerding/kissfft/archive/febd4caeed32e33ad8b2e0bb5ea77542c40f18ec.zip";
        hash = "sha256-SXED5mQWjr45WAt1etvmFvbPhaFlcq9YHKe8QtCrE/0=";
      };
    }
  ];
in
effectiveStdenv.mkDerivation (finalAttrs: {
  pname = "sherpa-onnx";
  version = "1.12.25";

  src = fetchFromGitHub {
    owner = "k2-fsa";
    repo = "sherpa-onnx";
    tag = "v${finalAttrs.version}";
    hash = "sha256-NRiqk/YMk3vhlBRrmeMsJ544Xv1b7GCSMQD2ec+xi+k=";
    fetchSubmodules = true;
  };

  outputs = [
    "out"
  ]
  ++ lib.optionals pythonSupport [ "python" ];

  separateDebugInfo = true;

  patches = [
    ./espeak.patch
  ];
  nativeBuildInputs = [
    cmake
    pkg-config
  ]
  ++ lib.optionals pythonSupport (
    with python3Packages;
    [
      python
      pybind11
      numpy
    ]
  )
  ++ lib.optionals cudaSupport [
    cudaPackages.cuda_nvcc
  ];

  buildInputs = [
    onnxruntime
  ]
  ++ lib.optionals effectiveStdenv.hostPlatform.isLinux [
    alsa-lib
  ]
  ++ lib.optionals cudaSupport (
    with cudaPackages;
    [
      cuda_cccl
      libcublas
      libcurand
      libcusparse
      libcufft
      cudnn
      cuda_cudart
      nccl
    ]
  );

  propagatedBuildInputs = lib.optionals pythonSupport [
    python3Packages.numpy
  ];

  cmakeDir = "..";

  # Populate pre-fetched dependencies so cmake FetchContent finds them
  # locally instead of attempting network downloads.
  preConfigure = ''
    ${lib.concatMapStringsSep "\n" (s: "cp ${s.src} ./${s.name}") cache}
  '';

  cmakeFlags = [
    (lib.cmakeBool "FETCHCONTENT_QUIET" false)
    (lib.cmakeBool "BUILD_SHARED_LIBS" true)
    (lib.cmakeBool "SHERPA_ONNX_ENABLE_WEBSOCKET" websocketSupport)
    (lib.cmakeBool "SHERPA_ONNX_ENABLE_PORTAUDIO" false)
    (lib.cmakeBool "SHERPA_ONNX_ENABLE_PYTHON" pythonSupport)
    (lib.cmakeBool "SHERPA_ONNX_BUILD_C_API_EXAMPLES" false)
    (lib.cmakeBool "SHERPA_ONNX_ENABLE_CHECK" false)
    (lib.cmakeBool "SHERPA_ONNX_ENABLE_C_API" true)
    (lib.cmakeBool "SHERPA_ONNX_ENABLE_TESTS" true)
    (lib.cmakeFeature "onnxruntime_SOURCE_DIR" "${onnxruntime.dev}")
    (lib.cmakeBool "SHERPA_ONNX_ENABLE_GPU" cudaSupport)
    # Use nixpkgs sources instead of vendored downloads where possible.
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_JSON" "${nlohmann_json.src}")
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_EIGEN" "${eigen.src}")
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_GOOGLETEST" "${gtest.src}")
    "-Wno-dev"
  ]
  ++ lib.optionals pythonSupport [
    (lib.cmakeFeature "PYTHON_EXECUTABLE" (lib.getExe python3Packages.python))
    (lib.cmakeFeature "FETCHCONTENT_SOURCE_DIR_PYBIND11" "${python3Packages.pybind11.src}")
  ]
  ++ lib.optionals cudaSupport [
    (lib.cmakeFeature "onnxruntime_CUDNN_HOME" "${cudaPackages.cudnn}")
    (lib.cmakeFeature "CMAKE_CUDA_ARCHITECTURES" cudaPackages.flags.cmakeCudaArchitecturesString)
  ];

  # Assemble the Python package in the `python` output.
  # The __init__.py imports from sherpa_onnx.lib._sherpa_onnx, so the
  # native extension must be placed in a `lib/` subdirectory.
  postInstall = lib.optionalString pythonSupport ''
    local site="$python/${python3Packages.python.sitePackages}"
    mkdir -p "$site/sherpa_onnx/lib"

    cp -r $src/sherpa-onnx/python/sherpa_onnx/*.py "$site/sherpa_onnx/"
    mv $out/lib/_sherpa_onnx*.so "$site/sherpa_onnx/lib/"
    touch "$site/sherpa_onnx/lib/__init__.py"
  '';

  doCheck = true;

  # The default `make check` target includes a clang-tidy step.
  # Use ctest directly to run the unit tests.
  # When pythonSupport is enabled, create a `sherpa_onnx/lib/` subpackage
  # containing the native extension so that Python tests can resolve
  # `from sherpa_onnx.lib._sherpa_onnx import ...`.
  # test_fast_clustering_py is excluded because it requires soundfile.
  checkPhase = ''
    runHook preCheck

    ${lib.optionalString pythonSupport ''
      mkdir -p ../sherpa-onnx/python/sherpa_onnx/lib

      local so_file
      so_file="$(find . -name '_sherpa_onnx*.so' -not -path '*/sherpa_onnx/*' -print -quit)"
      if [[ -z "$so_file" ]]; then
        echo "ERROR: could not find _sherpa_onnx*.so for Python tests" >&2
        exit 1
      fi
      ln -sf "$(realpath "$so_file")" ../sherpa-onnx/python/sherpa_onnx/lib/

      : > ../sherpa-onnx/python/sherpa_onnx/lib/__init__.py
    ''}

    ctest --output-on-failure \
      ${lib.optionalString pythonSupport "--exclude-regex 'test_fast_clustering_py'"}
    runHook postCheck
  '';

  env = lib.optionalAttrs effectiveStdenv.cc.isClang {
    NIX_CFLAGS_COMPILE = toString [
      "-Wno-error=deprecated-declarations"
    ];
  };

  requiredSystemFeatures = lib.optionals cudaSupport [ "big-parallel" ];

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
