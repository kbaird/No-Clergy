#!/bin/bash
# nc_backup.sh

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

# flush old dvi, ps, pdf files and make sure to backup 
# feedback.cgi and start.cgi
source ./NoClergy/flush_dvi_pdf_ps.sh
cp /usr/lib/cgi-bin/feedback.cgi ./
cp /usr/lib/cgi-bin/start.cgi ./

# make bzip2 compressed tar archives with dated filenames
tar -cvf nc_scripts$(date '+%Y_%m_%d-%H_%M_%S').tar ./*.sh ./*.cgi
echo 'compressing scripts'
bzip2 nc_scripts*.tar 
rm feedback.cgi start.cgi
tar -cvf nc_folder$(date '+%Y_%m_%d-%H_%M_%S').tar ./NoClergy/*
echo 'compressing ~/NoClergy/ folder'
bzip2 nc_folder*.tar 
tar -cvf nc_web$(date '+%Y_%m_%d-%H_%M_%S').tar /var/www/noclergy/*
echo 'compressing web'
bzip2 nc_web*.tar 
tar -cvf nc_dbk$(date '+%Y_%m_%d-%H_%M_%S').tar ./Diss_dbk/*
echo 'compressing DocBook'
bzip2 nc_dbk*.tar 

# secure copy tarballs into diss_backups folder on other machine
# 'kirk' is identified in /etc/hosts
scp nc_scripts*.tar.bz2 kirk:/home/kbaird/diss_backups/
scp nc_folder*.tar.bz2 kirk:/home/kbaird/diss_backups/
scp nc_web*.tar.bz2 kirk:/home/kbaird/diss_backups/
scp nc_dbk*.tar.bz2 kirk:/home/kbaird/diss_backups/

# store backups in the backups folder
mv nc_scripts*.tar.bz2 backups/
mv nc_folder*.tar.bz2 backups/
mv nc_web*.tar.bz2 backups/
mv nc_dbk*.tar.bz2 backups/
