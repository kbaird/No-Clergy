#!/bin/bash
# uninstall_as_root.sh

CGI_BIN_DIR=/usr/lib/cgi-bin # change as in install_as_root.sh if not Debian

uninstall_bin() {
  rm $@/bin/noclergy
}

uninstall_cgi_bin() {
  rm $CGI_BIN_DIR/nc_feedback.cgi
}

uninstall_data() {
  rm -rf $@/share/noclergy
}

uninstall_libs() {
  rm -rf /usr/local/lib/site_ruby/1.6/noclergy
  rm -rf /usr/local/lib/site_ruby/1.8/noclergy
  rm -rf /usr/lib/ruby/1.6/noclergy
  rm -rf /usr/lib/ruby/1.8/noclergy
}

uninstall_man() {
  rm $@/share/man/man1/noclergy.1.gz
}

uninstall_mass() {
  uninstall_bin $@
  uninstall_data $@
  uninstall_libs $@
  uninstall_man $@
}

uninstall_all() {
  uninstall_var
  uninstall_mass /usr
  uninstall_mass /usr/local
  uninstall_cgi_bin
  rm -rf /etc/noclergy
  rm -rf /var/lib/noclergy
  rm -rf /var/spool/noclergy
  rm -rf /var/noclergy
  rm /etc/apache2/mods*/noclergy*
}

###

#mount /usr -o remount,rw
uninstall_all 2> /dev/null
#mount /usr -o remount,ro
