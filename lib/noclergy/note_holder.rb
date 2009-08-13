#!/usr/bin/env ruby
# note_holder.rb
# $Id: note_holder.rb,v 1.10 2006/04/23 20:10:19 kbaird Exp $

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

['note_list', 'sound_haver'].each do |filename|
  require 'noclergy/' + filename
end

=begin rdoc
Generic "Superclass" for anything that contains <b>Note</b>s and modifies them: 
<b>Measure</b>s and <b>Score</b>s. <b>Piece</b> requires such minimal 
manipulation of internal content that it does not need to descend from this 
Superclass.
=end
class NoteHolder < SoundHaver

  # how many lines of notation?
  NUMBER_OF_SYSTEMS = 4 
    
	def initialize(inst_abbr)
    debug_no_inst_abbr(inst_abbr)
    super(inst_abbr)
    fail unless @inst.abbr()
    @notesA = NoteList.new()
	end # initialize

=begin rdoc
Append all articulations, durations, dynamics, <b>Note</b>s and 
pitches from an <b>Array</b> parameter to instance <b>Array</b>'s.
=end
	def get_all_notes(notesA)
    @notesA += notesA
	end # get_all_notes

=begin rdoc
Sets @@mm_per_systemI, which is the number of <b>Measure</b>s per system, 
by dividing the total number of <b>Measure</b>s by the number of systems.
=end
  def set_system_breaks()
		@@mm_per_systemI = @varsH['number_of_measures']/NUMBER_OF_SYSTEMS
		@@mm_per_systemI.freeze()
  end # set__system_breaks

end # class NoteHolder
