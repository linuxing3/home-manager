{ lib, stdenv, pkgs, ... }:

let name = "mutt-wizard";
    version = "3.3.1";
in
  stdenv.mkDerivation {
    inherit name version;

    src = fetchTarball {
        url = "https://github.com/LukeSmithxyz/mutt-wizard/archive/master.tar.gz";
        sha256 = "0945zr9vr38jxf8z8n1hynmwsn3lq9h4fa6rkdj3q7r4x258bmb8";
    };

    buildInputs = [ pkgs.gnumake ];

    buildPhase = "
      rm Makefile
    ";

    installPhase = ''
    	mkdir -p $out/bin
    	mkdir -p $out/lib/mutt-wizard
    	mkdir -p $out/share/mutt-wizard
    	cp -f $src/bin/mailsync $out/bin
    	cp -f $src/lib/openfile $out/lib/mutt-wizard
    	chmod 755 $out/share/mutt-wizard
    	for shared in $src/share/*; do
    		cp -f $shared $out/share/mutt-wizard;
    		chmod 644 -R $out/share/mutt-wizard/$(basename $shared);
    	done
    	mkdir -p $out/share/man/man1
    	cp -f mailsync.1 $out/share/man/man1/mailsync.1
    	sed "s:/usr/local:$out:" < $src/share/mutt-wizard.muttrc > $out/share/mutt-wizard/mutt-wizard.muttrc
    	sed "s:/usr/local:$out:" < $src/share/mailcap > $out/share/mutt-wizard/mailcap
    	sed "s:/usr/local:$out:" < $src/bin/mw > $out/bin/mutt-wizard
    	sed "s:/usr/local:$out:" < $src/mw.1 > $out/share/man/man1/mutt-wizard.1
    	chmod 644 $out/share/man/man1/mutt-wizard.1 $out/share/man/man1/mailsync.1
    	chmod 755 $out/bin/mutt-wizard $out/bin/mailsync $out/lib/mutt-wizard/openfile
    	mkdir -p $out/share/zsh/site-functions/
    	chmod 755 $out/share/zsh/site-functions/
    	cp -f completion/_mutt-wizard.zsh $out/share/zsh/site-functions/_mutt-wizard.zsh
    	chmod 644 $out/share/zsh/site-functions/_mutt-wizard.zsh
	'';

    meta = {
      homepage = "https://github.com/LukeSmithxyz/mutt-wizard";
      description = "CLI utility to email system";
      license = lib.licenses.mit;
      maintainers = [];
    };
  }
