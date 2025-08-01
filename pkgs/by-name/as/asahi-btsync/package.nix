{
  lib,
  fetchCrate,
  rustPlatform,
}:

rustPlatform.buildRustPackage rec {
  pname = "asahi-btsync";
  version = "0.2.0";

  src = fetchCrate {
    inherit pname version;
    hash = "sha256-jp05WcwY1cWh4mBQj+3jRCZoG32OhDvTB84hOAGemX8=";
  };

  cargoHash = "sha256-gGWhi0T7xDIsbzfw/KL3TSneLvQaiz/2xbpHeZt1i3I=";
  cargoDepsName = pname;

  meta = with lib; {
    description = "Tool to sync Bluetooth pairing keys with macos on ARM Macs";
    homepage = "https://crates.io/crates/asahi-btsync";
    license = licenses.mit;
    maintainers = with maintainers; [ lukaslihotzki ];
    mainProgram = "asahi-btsync";
    platforms = platforms.linux;
  };
}
