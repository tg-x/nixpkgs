{stdenv, fetchurl}:
let
  s = # Generated upstream information
  rec {
    baseName="firejail";
    version="0.9.36";
    name="${baseName}-${version}";
    hash="1mxgkfn2hbacarcp51qwgi7jxxzv69wb4lz78m71zysy3kkqn23k";
    url="mirror://sourceforge/project/firejail/firejail/firejail-0.9.36-rc1.tar.bz2";
    sha256="1mxgkfn2hbacarcp51qwgi7jxxzv69wb4lz78m71zysy3kkqn23k";
  };
  buildInputs = [
  ];
in
stdenv.mkDerivation {
  inherit (s) name version;
  inherit buildInputs;
  src = fetchurl {
    inherit (s) url sha256;
  };

  patches = [ ./bind.patch ];

  preConfigure = ''
    sed -e 's@/bin/bash@${stdenv.shell}@g' -i $( grep -lr /bin/bash .)
    sed -e '/void fs_var_run(/achar *vrcs = get_link("/var/run/current-system")\;' -i ./src/firejail/fs_var.c
    sed -e '/ \/run/iif(vrcs!=NULL){symlink(vrcs, "/var/run/current-system")\;free(vrcs)\;}' -i ./src/firejail/fs_var.c
    sed -e 's@/bin/cp@/run/current-system/sw/bin/cp@g' -i ./src/firejail/fs.c
    sed -e 's/int rv = check_kernel_procs();/int rv = 1;/' -i ./src/firejail/main.c
  '';

  preBuild = ''
    sed -e "s@/etc/@$out/etc/@g" -i Makefile
  '';

  meta = {
    inherit (s) version;
    description = ''Namespace-based sandboxing tool for Linux'';
    license = stdenv.lib.licenses.gpl2Plus ;
    maintainers = [stdenv.lib.maintainers.raskin];
    platforms = stdenv.lib.platforms.linux;
    homepage = "http://l3net.wordpress.com/projects/firejail/";
    downloadPage = "http://sourceforge.net/projects/firejail/files/firejail/";
  };
}
