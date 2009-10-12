#!/usr/bin/env ruby
# piece.rb
# $Id: piece.rb,v 1.3 2006/04/25 14:01:45 kbaird Exp $

# Copyright (C) 2004-2009 Kevin C. Baird
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

require 'noclergy/note_holder'

=begin rdoc
The entire piece 
(<b>{No Clergy}[http://noclergy.rubyforge.org/noclergy/]</b>). 
This object exists to hold states and methods for cross-fertilizing 
mutations between instruments.
=end
class Piece

=begin rdoc
Receives an <b>Array</b> of <b>Score</b>s.
=end
	def initialize(scoresA)
		@articulationsA = []
		@durationsA = []
		@dynamicsA = []
		@notesA = NoteList.new()
		@pitchesA = []
		@scoresA = scoresA
		get_all_notes()
	end # initialize

private

	def get_all_notes()
		@scoresA.each do |score|
			score.collect_notes()
			@articulationsA += score.articulationsA 
			@articulationsA += score.durationsA 
			@dynamicsA      += score.dynamicsA 
			@notesA         += score.notesA 
			@pitchesA       += score.pitchesA 
		end # @scoresA.each
	end # get_all_notes

end # class Piece
