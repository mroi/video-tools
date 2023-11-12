{
	description = "video processing tools";
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
		atomicparsley = {
			url = "github:wez/atomicparsley/20210715.151551.e7ad03a";
			flake = false;
		};
		ffmpeg = {
			url = "github:FFmpeg/FFmpeg/n6.1";
			flake = false;
		};
		mp4box = {
			url = "github:gpac/gpac/v2.0.0";
			flake = false;
		};
	};
	outputs = { self, nixpkgs, atomicparsley, ffmpeg, mp4box }: let
		systems = [ "x86_64-linux" "x86_64-darwin" ];
		lib = import "${nixpkgs}/lib";
		forAll = list: f: lib.genAttrs list f;

	in {
		packages = forAll systems (system: with import nixpkgs { inherit system; }; {

			default = self.outputs.packages.${system}.video-tools;

			atomicparsley = stdenv.mkDerivation {
				name = "atomicparsley-${lib.substring 0 8 self.inputs.atomicparsley.lastModifiedDate}";
				src = atomicparsley;
				nativeBuildInputs = [ cmake ];
				buildInputs = lib.optionals stdenv.isDarwin [ darwin.apple_sdk.frameworks.Cocoa ];
				cmakeFlags = [ "-DPACKAGE_VERSION=${lib.substring 0 8 self.inputs.atomicparsley.lastModifiedDate}" ];
			};

			ffmpeg = clangStdenv.mkDerivation {
				name = "ffmpeg";
				src = ffmpeg;
				nativeBuildInputs = [ yasm ];
				buildInputs = lib.optionals stdenv.isDarwin [ darwin.apple_sdk.frameworks.OpenCL ];
				configureFlags = [
					"--cc=clang --cpu=corei7-avx"
					"--enable-gpl --enable-version3 --enable-nonfree"
					"--enable-opencl --enable-static --disable-doc"
					"--disable-programs --enable-ffmpeg"
				];
				installPhase = ''
					mkdir -p $out/bin
					cp ffmpeg $out/bin/
				'';
			};

			# TODO: HandBrake cannot be built with Nix’ 10.12 platform, download prebuilt release instead
			#handbrake = handbrake.override { useGtk = false; };
			handbrake = stdenvNoCC.mkDerivation {
				name = "handbrake-1.5.1";
				src = fetchurl {
					url = "https://github.com/HandBrake/HandBrake/releases/download/1.5.1/HandBrakeCLI-1.5.1.dmg";
					sha256 = "sha256-MorR+6y4VbZEtjiZRQwATLGOXoGa1RlUnExLyGOmD5A=";
				};
				nativeBuildInputs = [ undmg ];
				installPhase = ''
					cd $NIX_BUILD_TOP
					mkdir -p $out/bin
					cp HandBrakeCLI $out/bin/
				'';
			};

			mp4box = stdenv.mkDerivation {
				name = "mp4box-2.0.0";
				src = mp4box;
				nativeBuildInputs = [ pkg-config ] ++ lib.optionals stdenv.isDarwin [ darwin.cctools ];
				buildInputs = [ zlib ] ++ lib.optionals stdenv.isDarwin [ darwin.apple_sdk.frameworks.Carbon ];
			};

			subler = stdenvNoCC.mkDerivation {
				name = "subler-1.7.3";
				src = fetchurl {
					url = "https://bitbucket.org/galad87/subler/downloads/Subler-1.7.3.zip";
					sha256 = "sha256-VmxoTUUDYYNrJYyzBKw3QIrLHbtlUuh2cfm9ObJKAS0=";
				};
				nativeBuildInputs = [ unzip ];
				installPhase = ''
					cd $NIX_BUILD_TOP
					mkdir -p $out/Applications
					cp -r Subler.app $out/Applications/
				'';
			};

			video-tools = stdenvNoCC.mkDerivation {
				name = "video-tools";
				src = ./.;
				dontBuild = true;
				installPhase = ''
					mkdir -p $out/libexec
					cp compare.sh encode.sh $out/libexec/
					ln -s ${self.outputs.packages.${system}.atomicparsley}/bin/AtomicParsley $out/libexec/
					ln -s ${self.outputs.packages.${system}.handbrake}/bin/HandBrakeCLI $out/libexec/
					ln -s ${self.outputs.packages.${system}.mp4box}/bin/MP4Box $out/libexec/
					mkdir -p $out/bin
					cat <<- EOF > $out/bin/mp4cmp
						#!/bin/sh
						exec $out/libexec/compare.sh "\$@"
					EOF
					cat <<- EOF > $out/bin/mp4enc
						#!/bin/sh
						exec $out/libexec/encode.sh "\$@"
					EOF
					chmod a+x $out/bin/*
				'';
			};
		});
	};
}
