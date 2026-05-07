{
  description = "TomoTexture — Tomodachi Life save texture editor";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        pythonDeps = ps: with ps; [
          pillow
          numpy
          zstandard
          customtkinter
          tkinter
        ];

        pythonWithDeps = pkgs.python313.withPackages pythonDeps;
      in
      {
        packages.default = pkgs.python313.pkgs.buildPythonApplication rec {
          pname = "TomoTexture";
          version = "1.0.3";
          pyproject = false;

          src = ./.;

          propagatedBuildInputs = [ pythonWithDeps ];

          installPhase = ''
            mkdir -p $out/bin $out/lib/TomoTexture
            cp -r *.py safezone.png safezone.ico $out/lib/TomoTexture/
            makeWrapper ${pythonWithDeps}/bin/python3 $out/bin/TomoTexture \
              --add-flags "$out/lib/TomoTexture/app.py" \
              --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath [
                pkgs.stdenv.cc.cc.lib
                pkgs.tk
                pkgs.tcl
                pkgs.libGL
                pkgs.zlib
              ]}"
          '';

          meta = with pkgs.lib; {
            description = "Save canvas editor for Tomodachi Life";
            license = licenses.mit;
            platforms = platforms.linux;
          };
        };

        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            pythonWithDeps
            stdenv.cc.cc.lib
            tk
            tcl
            libGL
            zlib
          ];

          LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
            pkgs.stdenv.cc.cc.lib
            pkgs.tk
            pkgs.tcl
            pkgs.libGL
            pkgs.zlib
          ];

          shellHook = ''
            echo "TomoTexture dev shell ready"
            echo "Python: $(python3 --version)"
            echo ""
            echo "Run the app directly:"
            echo "  python3 app.py"
          '';
        };
      });
}
