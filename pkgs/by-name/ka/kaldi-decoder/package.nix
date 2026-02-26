{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  cmake,
}:

let
  # kaldi-decoder vendors kaldifst v1.7.16 (which itself vendors the
  # csukuangfj openfst fork).  We pre-fetch these sources so the build
  # succeeds in the nix sandbox without network access.
  kaldifst-src = fetchFromGitHub {
    owner = "k2-fsa";
    repo = "kaldifst";
    tag = "v1.7.16";
    hash = "sha256-ngza1Y4/o1PrL37K6+psPFay3FdEUv0qdMLXBYnJjaI=";
  };

  openfst-src = fetchFromGitHub {
    owner = "csukuangfj";
    repo = "openfst";
    tag = "sherpa-onnx-2024-06-13";
    hash = "sha256-tFdt7jVV9UJUVVywHWVgSC5RtfoFABnmks8zec0vpdo=";
  };

  # Must use Eigen 3.4.0 — nixpkgs' 3.4.1 is incompatible.
  eigen-src = fetchurl {
    url = "https://gitlab.com/libeigen/eigen/-/archive/3.4.0/eigen-3.4.0.tar.gz";
    hash = "sha256-hYYIT3H5veVF7n+m0AKIsmSit6w2B7l05U0T5xYsHHI=";
  };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "kaldi-decoder";
  version = "0.2.11";

  src = fetchFromGitHub {
    owner = "k2-fsa";
    repo = "kaldi-decoder";
    tag = "v${finalAttrs.version}";
    hash = "sha256-xQ+N5NSXYk9JfSpkOCRCclj3Y04niAPSh37Nv7X6RHU=";
  };

  nativeBuildInputs = [ cmake ];

  # Prepare writable copies of vendored sources and patch openfst to
  # disable tests (matching upstream's PATCH_COMMAND behavior).
  preConfigure = ''
    local kaldifst_dir="$NIX_BUILD_TOP/kaldifst-src"
    cp -r ${kaldifst-src} "$kaldifst_dir"
    chmod -R u+w "$kaldifst_dir"

    local openfst_dir="$NIX_BUILD_TOP/openfst-src"
    cp -r ${openfst-src} "$openfst_dir"
    chmod -R u+w "$openfst_dir"
    sed -i 's/enable_testing()//g' "$openfst_dir/src/CMakeLists.txt"
    sed -i 's/add_subdirectory(test)//g' "$openfst_dir/src/CMakeLists.txt"
    sed -i '/message/d' "$openfst_dir/src/script/CMakeLists.txt"

    local eigen_dir="$NIX_BUILD_TOP/eigen-src"
    mkdir -p "$eigen_dir"
    tar xzf ${eigen-src} -C "$eigen_dir" --strip-components=1

    cmakeFlagsArray+=(
      "-DFETCHCONTENT_SOURCE_DIR_KALDIFST=$kaldifst_dir"
      "-DFETCHCONTENT_SOURCE_DIR_OPENFST=$openfst_dir"
      "-DFETCHCONTENT_SOURCE_DIR_EIGEN=$eigen_dir"
    )
  '';

  cmakeFlags = [
    (lib.cmakeBool "KALDI_DECODER_BUILD_PYTHON" false)
    (lib.cmakeBool "KALDI_DECODER_ENABLE_TESTS" false)
    # Must be OFF for install targets to work — kaldi-decoder-core is
    # always built as a static library.
    (lib.cmakeBool "BUILD_SHARED_LIBS" false)
  ];

  meta = {
    description = "Kaldi-compatible decoder library for speech recognition";
    homepage = "https://github.com/k2-fsa/kaldi-decoder";
    license = lib.licenses.asl20;
    platforms = lib.platforms.unix;
    maintainers = with lib.maintainers; [ ];
  };
})
