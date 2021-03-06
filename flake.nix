{
	description = "video processing tools";
	inputs = {
		ffmpeg = {
			url = "github:FFmpeg/FFmpeg/n4.4";
			flake = false;
		};
	};
	outputs = { self, nixpkgs, ffmpeg }: {
		ffmpeg =
			with import nixpkgs { system = "x86_64-darwin"; };
			stdenv.mkDerivation {
				name = "ffmpeg-4.4";
				src = ffmpeg;
				nativeBuildInputs = [ llvmPackages_latest.clang yasm ];
				buildInputs = [ darwin.apple_sdk.frameworks.OpenCL ];
				configureFlags = "--cc=clang --cpu=corei7-avx --enable-gpl --enable-version3 --enable-nonfree --enable-opencl --enable-static --disable-doc --disable-programs --enable-ffmpeg";
				installPhase = ''
					mkdir -p $out/bin
					cp ffmpeg $out/bin/
				'';
			};
	};
}
