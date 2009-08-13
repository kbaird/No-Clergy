#!/bin/bash
# install_as_root.sh

# check for lilypond
if [ ! $(which lilypond) ]; then
  echo 'Please install lilypond' >&2
  exit 1
fi

# check for ruby
if [ ! $(which ruby) ]; then
  echo 'Please install ruby' >&2
  exit 1
fi

# check for xml/dom/builder.rb
legal_ruby_versions=(1.8)
for version in "${legal_ruby_versions[@]}"; do
  if [ -f "/usr/lib/ruby/$version/xml/dom/builder.rb" ]; then
    legal_ruby_version_found=0 # true in bash
  elif [ -f "/usr/local/lib/site-ruby/$version/xml/dom/builder.rb" ]; then
    legal_ruby_version_found=0 # true in bash
  else
    legal_ruby_version_found=1 # false in bash
  fi
done

if [ $legal_ruby_version_found -eq 1 ]; then
  echo "You are missing the 'xml/dom/builder' library for Ruby." >&2
  echo "Please install the 'libxml-parser-ruby1.8' package or similar" >&2
  echo "equivalent for your operating system version." >&2
  exit 1
fi

# deal with cgi-bin
isDebian=$(egrep -q 'Debian|Ubuntu' /etc/issue)
if [ $isDebian==0 ]; then
  CGI_BIN_DIR=/usr/lib/cgi-bin  # Default for Debian
else
  CGI_BIN_DIR=/var/www/cgi-bin # Another popular location
fi
#CGI_BIN_DIR=/var/www/cgi-bin # Set it manually yourself

if [ ! -d $CGI_BIN_DIR ]; then
  echo "I can not find your cgi-bin/ directory. Please install a web server or edit this script." >&2
  exit 1
fi

if [ -d /etc/apache2/mods-available ]; then
  cp ./noclergy_apache.conf /etc/apache2/mods-available/
  ln -s /etc/apache2/mods-available/noclergy_apache.conf /etc/apache2/mods-enabled/noclergy_apache.conf
  /etc/init.d/apache2 restart
else
  echo "I don't know how to add noclergy_apache.conf to your Apache setup. "
  echo "Please do so manually and restart apache." >&2
fi

# start the installation proper
INSTALLDIRS=site
PREFIX=/usr/local
LOCALSTATEDIR=/var/lib

ruby setup.rb all --installdirs=$INSTALLDIRS --prefix=$PREFIX --localstatedir=$LOCALSTATEDIR 2> install_log.txt

mkdir -p /etc/noclergy
chown -R root:root /etc/noclergy
chmod -R 2775 /etc/noclergy

mkdir -p $LOCALSTATEDIR/noclergy/ly
mkdir -p $LOCALSTATEDIR/noclergy/pdf
mkdir -p $LOCALSTATEDIR/noclergy/png
mkdir -p $LOCALSTATEDIR/noclergy/web
cp -r web/noclergy/* $LOCALSTATEDIR/noclergy/web/
mkdir -p $LOCALSTATEDIR/noclergy/xml
chown -R root:root $LOCALSTATEDIR/noclergy

chmod -R 2777 $LOCALSTATEDIR/noclergy
chmod -R 2777 $LOCALSTATEDIR/noclergy/ly
chmod -R 2777 $LOCALSTATEDIR/noclergy/pdf
chmod -R 2777 $LOCALSTATEDIR/noclergy/png
chmod -R 2777 $LOCALSTATEDIR/noclergy/web
chmod -R 2777 $LOCALSTATEDIR/noclergy/xml

cp cgi-bin/*.* $CGI_BIN_DIR/
chmod 775 $CGI_BIN_DIR/nc_feedback.cgi
echo >&2
echo 'Your No Clergy installation did not have any obvious errors.' >&2
echo "Congratulations. Please make sure that mod_ruby is installed, " >&2
echo "and begin with 'noclergy -h'." >&2
echo >&2
exit 0
