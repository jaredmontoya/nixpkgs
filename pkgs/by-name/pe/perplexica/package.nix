{
  lib,
  mkYarnPackage,
  fetchYarnDeps,
  fetchFromGitHub,
  makeWrapper,
  nodejs_22,
  patchelf,
  srcOnly,
  python3,
  removeReferencesTo,
  stdenv,
  cctools,
  montserrat,
}:

let
  pin = lib.importJSON ./pin.json;
  inherit (pin) version;
  pname = "perplexica-backend";
  nodeSources = srcOnly nodejs_22;

  src = fetchFromGitHub {
    owner = "ItzCrazyKns";
    repo = "Perplexica";
    rev = "v${version}";
    hash = pin.srcHash;
  };

  passthru = {
    nodeAppDir = "libexec/${pname}/deps/${pname}";
    updateScript = ./update.sh;
  };
in
mkYarnPackage {
  inherit
    version
    pname
    src
    passthru
    ;

  packageJSON = ./package.json;
  offlineCache = fetchYarnDeps {
    yarnLock = "${src}/yarn.lock";
    sha256 = pin.yarnSha256;
  };

  nodejs = nodejs_22;

  nativeBuildInputs = [
    makeWrapper
  ];

  buildPhase = ''
    runHook preBuild

    yarn --offline build

    runHook postBuild
  '';

  pkgConfig = {
    better-sqlite3 = {
      nativeBuildInputs = [
        python3
        patchelf
        nodejs_22
      ]
      ++ lib.optionals stdenv.isDarwin [ cctools ];
      postInstall = ''
        # build native sqlite bindings
        npm run build-release --offline --nodedir="${nodeSources}"
        find build -type f -exec \
          ${removeReferencesTo}/bin/remove-references-to \
          -t "${nodeSources}" {} \;
      '';
    };
  };

  doCheck = false;

  postInstall = ''
    OUT_JS_DIR="$out/${passthru.nodeAppDir}/dist"

    # server wrapper
    makeWrapper '${nodejs_22}/bin/node' "$out/bin/${pname}" \
      --add-flags "$OUT_JS_DIR/app.js"
  '';

  postPatch = ''
    substituteInPlace src/app/layout.tsx --replace-fail \
      "{ Montserrat } from 'next/font/google'" \
      "localFont from 'next/font/local'"

    substituteInPlace src/app/layout.tsx --replace-fail \
      "Montserrat({" \
      "localFont({"

    substituteInPlace src/app/layout.tsx --replace-fail \
      "subsets: ['latin']" \
      "src: './Montserrat.woff2'"

    substituteInPlace src/app/layout.tsx --replace-fail \
      "weight: ['300', '400', '500', '700']" \
      "weight: '100 900'"

    cp "${montserrat}/share/fonts/woff2/Montserrat-Regular.woff2" src/app/Montserrat.woff2
  '';

  # don't generate the dist tarball
  doDist = false;

  meta = {
    description = "Perplexica is an AI-powered search engine. It is an Open source alternative to Perplexity AI";
    homepage = "https://github.com/ItzCrazyKns/Perplexica";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ happysalada ];
    platforms = lib.platforms.all;
    mainProgram = pname;
  };
}
