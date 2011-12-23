#!/bin/bash
# mv_output.sh

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

crop() {
  for file in $@; do
    convert -crop 744x800+0+0 $file cropped.png
    mv cropped.png $file
  done
}

mv lilypond/out/*.dvi lilypond/out/dvi/
mv lilypond/out/*.midi lilypond/out/midi/
mv lilypond/out/*.pdf lilypond/out/pdf/
mv lilypond/out/*.png lilypond/out/png/
mv lilypond/out/*.ps lilypond/out/ps/

crop lilypond/out/png/*.png

chmod 744 lilypond/out/png/*.png
# make images readable to the outside world
