#!/bin/bash
# mv_oldfiles.sh

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

rm lilypond/ly/*-old.* 2> /dev/null
rm lilypond/out/pdf/*-old.* 2> /dev/null
rm lilypond/out/png/*-old.* 2> /dev/null

mv lilypond/ly/clar.ly lilypond/ly/clar-old.ly
mv lilypond/ly/sax.ly lilypond/ly/sax-old.ly
mv lilypond/ly/vn.ly lilypond/ly/vn-old.ly
mv lilypond/out/pdf/clar.pdf lilypond/out/pdf/clar-old.pdf
mv lilypond/out/pdf/sax.pdf lilypond/out/pdf/sax-old.pdf
mv lilypond/out/pdf/vn.pdf lilypond/out/pdf/vn-old.pdf

cp lilypond/out/png/clar-page1.png lilypond/out/png/clar-page1-old.png
cp lilypond/out/png/sax-page1.png lilypond/out/png/sax-page1-old.png
cp lilypond/out/png/vn-page1.png lilypond/out/png/vn-page1-old.png
# cp instead of mv, so the player isn't stuck with no image file
