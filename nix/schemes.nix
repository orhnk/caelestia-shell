{
  lib,
  stdenvNoCC,
  python3,
  # Additional scheme *trees* in CLI layout, merged over the ported set in
  # order (later entries win). Each entry holds <scheme>/<flavour>/<mode>.txt
  # files, e.g. extraSchemes = [ ./my-palettes ] with
  # my-palettes/my-scheme/default/dark.txt inside. This is how users add
  # their own palettes without forking:
  #   schemes.override { extraSchemes = [ ./my-palettes ]; }
  extraSchemes ? [],
}:
stdenvNoCC.mkDerivation {
  pname = "caelestia-schemes";
  version = "1.0.0";

  src = lib.fileset.toSource {
    root = ./../schemes;
    fileset = lib.fileset.difference ./../schemes ./../schemes/README.md;
  };

  nativeBuildInputs = [python3];

  # Same format check for ported and user-supplied palettes: mistakes fail
  # the build instead of breaking `caelestia scheme set` at runtime.
  # (Interpolate, don't toString, so user paths land in the store and are
  # visible inside the sandbox.)
  doCheck = true;
  checkPhase = ''
    runHook preCheck
    python3 ${./validate-schemes.py} "$src" ${lib.concatStringsSep " " (map (e: ''"${e}"'') extraSchemes)}
    runHook postCheck
  '';

  installPhase =
    ''
      runHook preInstall
      mkdir -p $out/share/caelestia/schemes
      cp -r "$src"/. $out/share/caelestia/schemes/
    ''
    + lib.concatMapStringsSep "\n" (extra: ''
      cp -r "${extra}"/. $out/share/caelestia/schemes/
    '')
    extraSchemes
    + ''
      runHook postInstall
    '';

  meta = {
    description = "Base16 colour schemes (ported from ifraaH) for the Caelestia CLI";
    homepage = "https://github.com/orhnk/ifraaH";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
