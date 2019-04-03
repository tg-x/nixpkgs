{ stdenv, lib, fetchurl, makeWrapper, getconf,
  ocaml, unzip, ncurses, curl, aspcud, bubblewrap
}:

assert lib.versionAtLeast ocaml.version "4.02.3";

let
  srcs = {
    cmdliner = fetchurl {
      url = "http://erratique.ch/software/cmdliner/releases/cmdliner-1.0.2.tbz";
      sha256 = "18jqphjiifljlh9jg8zpl6310p3iwyaqphdkmf89acyaix0s4kj1";
    };
    cppo = fetchurl {
      url = "https://github.com/mjambon/cppo/archive/v1.6.5.tar.gz";
      sha256 = "1dkm3d5h6h56y937gcdk2wixlpzl59vv5pmiafglr89p20kf7gqf";
    };
    cudf = fetchurl {
      url = "https://gforge.inria.fr/frs/download.php/36602/cudf-0.9.tar.gz";
      sha256 = "0771lwljqwwn3cryl0plny5a5dyyrj4z6bw66ha5n8yfbpcy8clr";
    };
    dose3 = fetchurl {
      url = "https://gforge.inria.fr/frs/download.php/file/36063/dose3-5.0.1.tar.gz";
      sha256 = "00yvyfm4j423zqndvgc1ycnmiffaa2l9ab40cyg23pf51qmzk2jm";
    };
    dune-local = fetchurl {
      url = "https://github.com/ocaml/dune/releases/download/1.2.1/dune-1.2.1.tbz";
      sha256 = "00c5dbm4hkdapc2i7pg07b2lj8sv6ly38qr7zid58cdmbmzq21z9";
    };
    extlib = fetchurl {
      url = "http://ygrek.org.ua/p/release/ocaml-extlib/extlib-1.7.5.tar.gz";
      sha256 = "19slqf5bdj0rrph2w41giwmn6df2qm07942jn058pjkjrnk30d4s";
    };
    mccs = fetchurl {
      url = "https://github.com/AltGr/ocaml-mccs/archive/1.1+9.tar.gz";
      sha256 = "0gf86c65jdxxcwd96kcmrqxrmnnzc0570gb9ad6c57rl3fyy8yhv";
    };
    ocamlgraph = fetchurl {
      url = "http://ocamlgraph.lri.fr/download/ocamlgraph-1.8.8.tar.gz";
      sha256 = "0m9g16wrrr86gw4fz2fazrh8nkqms0n863w7ndcvrmyafgxvxsnr";
    };
    opam-file-format = fetchurl {
      url = "https://github.com/ocaml/opam-file-format/archive/2.0.0.tar.gz";
      sha256 = "0cjw69r7iilidi7b6arr92kjnjspchvwnmwr1b1gyaxqxpr2s98m";
    };
    re = fetchurl {
      url = "https://github.com/ocaml/ocaml-re/releases/download/1.8.0/re-1.8.0.tbz";
      sha256 = "0qkv42a4hpqpxvqa4kdkkcbhbg7aym9kv4mqgm3m51vxbd0pq0lv";
    };
    result = fetchurl {
      url = "https://github.com/janestreet/result/releases/download/1.3/result-1.3.tbz";
      sha256 = "1lrnbxdq80gbhnp85mqp1kfk0bkh6q1c93sfz2qgnq2qyz60w4sk";
    };
    seq = fetchurl {
      url = "https://github.com/c-cube/seq/archive/0.1.tar.gz";
      sha256 = "02lb2d9i12bxrz2ba5wygk2bycan316skqlyri0597q7j9210g8r";
    };
    opam = fetchurl {
      url = "https://github.com/ocaml/opam/archive/2.0.2.zip";
      sha256 = "0hxf0ns3si03rl7dxix7i30limbl50ffyvdyk9bqqms4ir8dcza6";
    };
  };
in stdenv.mkDerivation rec {
  name = "opam-${version}";
  version = "2.0.2";

  buildInputs = [ unzip curl ncurses ocaml makeWrapper getconf ] ++ lib.optional stdenv.isLinux bubblewrap;

  src = srcs.opam;

  postUnpack = ''
    ln -sv ${srcs.cmdliner} $sourceRoot/src_ext/cmdliner.tbz
    ln -sv ${srcs.cppo} $sourceRoot/src_ext/cppo.tar.gz
    ln -sv ${srcs.cudf} $sourceRoot/src_ext/cudf.tar.gz
    ln -sv ${srcs.dose3} $sourceRoot/src_ext/dose3.tar.gz
    ln -sv ${srcs.dune-local} $sourceRoot/src_ext/dune-local.tbz
    ln -sv ${srcs.extlib} $sourceRoot/src_ext/extlib.tar.gz
    ln -sv ${srcs.mccs} $sourceRoot/src_ext/mccs.tar.gz
    ln -sv ${srcs.ocamlgraph} $sourceRoot/src_ext/ocamlgraph.tar.gz
    ln -sv ${srcs.opam-file-format} $sourceRoot/src_ext/opam-file-format.tar.gz
    ln -sv ${srcs.re} $sourceRoot/src_ext/re.tbz
    ln -sv ${srcs.result} $sourceRoot/src_ext/result.tbz
    ln -sv ${srcs.seq} $sourceRoot/src_ext/seq.tar.gz
  '';

  patches = [ ./opam-shebangs.patch ];

  preConfigure = ''
    substituteInPlace ./src_ext/Makefile --replace "%.stamp: %.download" "%.stamp:"
    patchShebangs src/state/shellscripts
  '';

  postConfigure = "make lib-ext";

  # Dirty, but apparently ocp-build requires a TERM
  makeFlags = ["TERM=screen"];

  outputs = [ "out" "installer" ];
  setOutputFlags = false;

  # change argv0 to "opam" as a workaround for
  # https://github.com/ocaml/opam/issues/2142
  postInstall = ''
    mv $out/bin/opam $out/bin/.opam-wrapped
    makeWrapper $out/bin/.opam-wrapped $out/bin/opam \
      --argv0 "opam" \
      --suffix PATH : ${aspcud}/bin:${unzip}/bin:${curl}/bin:${lib.optionalString stdenv.isLinux "${bubblewrap}/bin:"}${getconf}/bin \
      --set OPAM_USER_PATH_RO /run/current-system/sw:/nix
    $out/bin/opam-installer --prefix=$installer opam-installer.install
  '';

  doCheck = false;

  meta = with stdenv.lib; {
    description = "A package manager for OCaml";
    homepage = http://opam.ocamlpro.com/;
    maintainers = [ maintainers.henrytill ];
    platforms = platforms.all;
  };
}
# Generated by: ./opam.nix.pl -v 2.0.2 -p opam-shebangs.patch
