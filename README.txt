To install, just run 'install_as_root.sh' as root, after verifying that default configuration specifics (such as 
file and directory locations) are to your liking. The defaults should work well for a Debian system. I am also 
very interested in making the defaults for other distributions and operating systems workable, as well.

No Clergy requires that mod_ruby and eruby be working on your server. The 'noclergy_http.conf' file can be either 
incorporated into an Apache config file, or used as-is for Apache2. Please email me at kbaird@rubyforge.org with 
any difficulties. If you have trouble getting apache1.3 to interpret *.rhtml files, add the contents of 
add_to_modules.conf to /etc/apache/modules.conf (or equivalent for your system).

Debian packages to have installed:
apache
libapache-mod-ruby
libxml-parser-ruby1.8
lilypond
ruby
ruby1.8

setup.rb is not a part of No Clergy. I include it only for convenience. No Clergy is covered by the General Public 
License, setup.rb is covered by the Lesser General Public License. Refer to the included GPL.txt for the GPL. 
Information about the LGPL is available at http://fsf.org/

setup.rb is written by Minero Aoki and is described in further detail at http://i.loveruby.net/en/projects/setup/
