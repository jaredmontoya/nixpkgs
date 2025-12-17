{
  lib,
  rustPlatform,
  fetchFromGitHub,
  nix-update-script,
}:

rustPlatform.buildRustPackage (finalAttrs: {
  pname = "nbted";
  version = "1.5.1";

  src = fetchFromGitHub {
    owner = "C4K3";
    repo = "nbted";
    tag = finalAttrs.version;
    hash = "sha256-wi3ZzioWej60+MBzMwJ6wnKAX9sLflTYccPaUMSWyPE=";
  };

  patches = [ ./remove_build_script.patch ];

  cargoHash = "sha256-E7jyJC/+xyxLQMPRNcSzrUkC38mflAkQyqznNQhKh/A=";

  passthru.updateScript = nix-update-script { };

  meta = {
    description = "Command-line NBT editor";
    homepage = "https://github.com/C4K3/nbted";
    license = lib.licenses.cc0;
    maintainers = with lib.maintainers; [ jaredmontoya ];
    mainProgram = "nbted";
  };
})
