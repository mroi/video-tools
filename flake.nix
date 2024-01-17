{
	description = "video processing tools";
	outputs = { self, nixpkgs }: let
		systems = [ "x86_64-linux" "x86_64-darwin" ];
		lib = import "${nixpkgs}/lib";
		forAll = list: f: lib.genAttrs list f;

	in {
		packages = forAll systems (system: with import nixpkgs { inherit system; }; {

			default = self.outputs.packages.${system}.video-tools;

			atomicparsley = stdenv.mkDerivation rec {
				pname = "atomicparsley";
				version = "20210715";
				src = fetchFromGitHub {
					owner = "wez";
					repo = "atomicparsley";
					rev = "${version}.151551.e7ad03a";
					hash = "sha256-77yWwfdEul4uLsUNX1dLwj8K0ilcuBaTVKMyXDvKVx4=";
				};
				nativeBuildInputs = [ cmake ];
				buildInputs = lib.optionals stdenv.isDarwin [ darwin.apple_sdk.frameworks.Cocoa ];
				cmakeFlags = [ "-DPACKAGE_VERSION=${version}" ];
			};

			ffmpeg = clangStdenv.mkDerivation rec {
				pname = "ffmpeg";
				version = "6.1.1";
				src = fetchFromGitHub {
					owner = "FFmpeg";
					repo = "FFmpeg";
					rev = "n${version}";
					hash = "sha256-Q0c95hbCVUHQWPoh5uC8uzMylmB4BnWg+VhXEgSouzo=";
				};
				nativeBuildInputs = [ yasm ];
				buildInputs = lib.optionals stdenv.isDarwin [ darwin.apple_sdk.frameworks.OpenCL ];
				configureFlags = [
					"--cc=clang --cxx=clang++ --cpu=corei7-avx"
					"--enable-gpl --enable-version3 --enable-nonfree"
					"--disable-doc --disable-programs --enable-ffmpeg"
					"--enable-static --disable-stripping"
					"--enable-opencl"
				];
				enableParallelBuilding = true;
				installPhase = ''
					mkdir -p $out/bin
					cp ffmpeg $out/bin/
				'';
			};

			handbrake = stdenvNoCC.mkDerivation rec {
				pname = "handbrake";
				version = "1.7.2";
				src = fetchurl {
					url = "https://github.com/HandBrake/HandBrake/releases/download/${version}/HandBrakeCLI-${version}.dmg";
					sha256 = "sha256-QhH3BOj6OZaKhbI7iA7lv697V13KH+z8lHiP5EnThmY=";
				};
				# TODO: undmg does not support APFS disk images
				#nativeBuildInputs = [ undmg ];
				__noChroot = true;
				unpackPhase = ''
					mkdir dmg
					/usr/bin/hdiutil attach $src -readonly -mountpoint $PWD/dmg
					cp dmg/HandBrakeCLI ./
					/usr/bin/hdiutil detach $PWD/dmg
				'';
				installPhase = ''
					cd $NIX_BUILD_TOP
					mkdir -p $out/bin
					cp HandBrakeCLI $out/bin/
				'';
			};

			mp4box =
			# TODO: LLVM compilation error fixed in version 18
			# https://github.com/llvm/llvm-project/issues/62254
			assert lib.versionOlder clang.version "18";
			llvmPackages_14.stdenv.mkDerivation rec {
				pname = "mp4box";
				version = "2.0.0";
				src = fetchFromGitHub {
					owner = "gpac";
					repo = "gpac";
					rev = "v${version}";
					hash = "sha256-MIX32lSqf/lrz9240h4wMIQp/heUmwvDJz8WN08yf6c=";
				};
				nativeBuildInputs = [ pkg-config ] ++ lib.optionals stdenv.buildPlatform.isDarwin [ darwin.cctools ];
				buildInputs = [ zlib ] ++ lib.optionals stdenv.isDarwin [ darwin.apple_sdk.frameworks.Carbon ];
				enableParallelBuilding = true;
			};

			subler = stdenvNoCC.mkDerivation rec {
				pname = "subler";
				version = "1.7.3";
				src = fetchurl {
					url = "https://bitbucket.org/galad87/subler/downloads/Subler-${version}.zip";
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
