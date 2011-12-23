#!/bin/bash
# nc_functions.sh

# Copyright (C) 2004 Kevin C. Baird
#
# This file is part of 'No Clergy'.
#
# No Clergy is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# Kevin can be reached at 
# kcbaird@world.oberlin.edu or 
# http://kevinbaird.net

# START VARIABLES
configDir='/var/www/noclergy'
#configFile=$configDir/config.txt
if [ -f $configDir/config.txt 2> /dev/null > /dev/null ]; then
  configFile=$configDir/config.txt
else
  configFile=$configDir/config.txt.orig
fi
# END VARIABLES

# START FUNCTIONS
cleanup() {
python NoClergy/Python/cleanup.py $@ mv
}

makeLy() {
python -O NoClergy/Python/make_ly.py $@ > lilypond/ly/$@.ly
}

renderLy() {
lilypond --png -o lilypond/out/ lilypond/ly/$@.ly >>stdout.txt 2>>stderr.txt
}
# END FUNCTIONS
