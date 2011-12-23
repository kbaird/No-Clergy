#!/bin/bash
# setup.sh

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

source ~/NoClergy/nc_functions.sh
# define functions and variables

source NoClergy/mv_oldfiles.sh 2>/dev/null
source NoClergy/flush_feedback.sh 2>/dev/null

egrep '^inst' $configFile > $configDir/insts.txt
instList=$(sed 's# =.*$##g' /var/www/noclergy/insts.txt | sed 's#inst ##g')

for inst in $instList; do	# written with 3 different for loops, 
  makeLy $inst			# one for each operation - inefficient 
done				# at first glance. I wanted to keep each
				# instrument in as close sync as 
for inst in $instList; do	# possible, and wrote it this way to 
  renderLy $inst		# avoid having the first instrument's 
done				# notation already rendered and shown
				# on screen while the 2nd instrument was 
for inst in $instList; do	# still waiting for the Lilypond markup 
  cleanup $inst			# to be made.
done

source NoClergy/mv_output.sh

