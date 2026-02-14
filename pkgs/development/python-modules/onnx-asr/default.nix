{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  pythonOlder,

  # build-system
  hatchling,
  hatch-vcs,

  # build-time deps for the custom hatch build hook that generates
  # ONNX preprocessor models (listed in pyproject.toml [dependency-groups] build)
  numpy,
  onnx,
  onnxscript,
  torch,
  torchaudio,

  # dependencies
  onnxruntime,
  typing-extensions,

  # optional-dependencies
  huggingface-hub,
}:

buildPythonPackage (finalAttrs: {
  pname = "onnx-asr";
  version = "0.10.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "istupakov";
    repo = "onnx-asr";
    tag = "v${finalAttrs.version}";
    hash = "sha256-KumdelY9oNMAEBSGVdvbBH6SYi93n2cA/eEqaE8MmIU=";
  };

  build-system = [
    hatchling
    hatch-vcs
    # The custom hatch build hook (hatch_build.py) generates ONNX preprocessor
    # models at build time using these dependencies.
    numpy
    onnx
    onnxscript
    torch
    torchaudio
  ];

  dependencies = [
    numpy
    onnxruntime
  ]
  ++ lib.optionals (pythonOlder "3.11") [
    typing-extensions
  ];

  optional-dependencies = {
    cpu = [
      onnxruntime
    ];
    hub = [
      huggingface-hub
    ];
    # gpu extra installs onnxruntime-gpu; in nixpkgs users should use
    # onnxruntime built with cudaSupport instead
    gpu = [
      onnxruntime
    ];
  };

  # Most tests require downloading models from Hugging Face
  doCheck = false;

  pythonImportsCheck = [
    "onnx_asr"
  ];

  meta = {
    description = "Lightweight Python package for Automatic Speech Recognition using ONNX models";
    homepage = "https://github.com/istupakov/onnx-asr";
    changelog = "https://github.com/istupakov/onnx-asr/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.mit;
    mainProgram = "onnx-asr";
    maintainers = with lib.maintainers; [ jaredmontoya ];
  };
})
