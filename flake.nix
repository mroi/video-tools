{
	description = "video processing tools";
	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
		ffmpeg = {
			url = "github:FFmpeg/FFmpeg/n5.0";
			flake = false;
		};
	};
	outputs = { self, nixpkgs, ffmpeg }: {
		packages.x86_64-darwin.ffmpeg = let
			pkgs = import nixpkgs { system = "x86_64-darwin"; };
		in pkgs.stdenv.mkDerivation {
			name = "ffmpeg-5.0";
			src = ffmpeg;
			nativeBuildInputs = [ pkgs.llvmPackages_latest.clang pkgs.yasm ];
			buildInputs = [ pkgs.darwin.apple_sdk.frameworks.OpenCL ];
			configureFlags = "--cc=clang --cpu=corei7-avx --enable-gpl --enable-version3 --enable-nonfree --enable-opencl --enable-static --disable-doc --disable-programs --enable-ffmpeg";
			installPhase = ''
				mkdir -p $out/bin
				cp ffmpeg $out/bin/
			'';
		};
	};
}
