{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchYarnDeps,
  yarnConfigHook,
  yarnBuildHook,
  makeWrapper,
  nodejs,
  node-gyp,
  python3,
  srcOnly,
  removeReferencesTo,
  montserrat,
}:

let
  pin = lib.importJSON ./pin.json;
  nodeSources = srcOnly nodejs;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "vane";
  inherit (pin) version;

  src = fetchFromGitHub {
    owner = "ItzCrazyKns";
    repo = "Vane";
    tag = "v${finalAttrs.version}";
    hash = pin.srcHash;
  };

  yarnOfflineCache = fetchYarnDeps {
    yarnLock = "${finalAttrs.src}/yarn.lock";
    hash = pin.yarnHash;
  };

  nativeBuildInputs = [
    yarnConfigHook
    yarnBuildHook
    makeWrapper
    nodejs
    node-gyp
    python3
  ];

  # Patch Google Font to use a local copy (sandbox blocks network access)
  postPatch = ''
        substituteInPlace src/app/layout.tsx \
          --replace-fail "import { Montserrat } from 'next/font/google';" \
                         "import localFont from 'next/font/local';" \
          --replace-fail "const montserrat = Montserrat({
      weight: ['300', '400', '500', '700'],
      subsets: ['latin'],
      display: 'swap',
      fallback: ['Arial', 'sans-serif'],
    });" \
                         "const montserrat = localFont({
      src: './Montserrat.ttf',
      weight: '100 900',
      display: 'swap',
      fallback: ['Arial', 'sans-serif'],
    });"

        cp "${montserrat}/share/fonts/variable/Montserrat[wght].ttf" src/app/Montserrat.ttf

        # Ensure the data directory exists for build (drizzle config references it)
        mkdir -p data
  '';

  # Build the native better-sqlite3 module before the Next.js build
  preBuild = ''
    pushd node_modules/better-sqlite3
    npm run build-release --offline --nodedir="${nodeSources}"
    find build -type f -exec \
      ${removeReferencesTo}/bin/remove-references-to \
      -t "${nodeSources}" {} \;
    popd
  '';

  # Next.js standalone output produces .next/standalone with server.js
  installPhase = ''
    runHook preInstall

    mkdir -p $out/{share/vane/.next,bin}

    # Copy the standalone server (includes minimal node_modules)
    cp -r .next/standalone/. $out/share/vane/

    # Copy static assets as required by Next.js standalone mode
    cp -r .next/static $out/share/vane/.next/static

    # Copy public directory
    cp -r public $out/share/vane/public

    # Copy drizzle migrations (needed at runtime for DB setup)
    cp -r drizzle $out/share/vane/drizzle

    # Create a symlink for the Next.js cache to a writable location
    ln -s /var/cache/vane $out/share/vane/.next/cache

    makeWrapper "${lib.getExe nodejs}" "$out/bin/vane" \
      --set-default PORT 3000 \
      --set-default HOSTNAME 0.0.0.0 \
      --chdir "$out/share/vane" \
      --add-flags "$out/share/vane/server.js"

    runHook postInstall
  '';

  # Don't try to produce a yarn dist tarball
  doDist = false;

  passthru.updateScript = ./update.sh;

  meta = {
    description = "AI-powered search engine, an open source alternative to Perplexity AI";
    homepage = "https://github.com/ItzCrazyKns/Vane";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ happysalada ];
    mainProgram = "vane";
    platforms = lib.platforms.linux;
  };
})
