#!/usr/bin/env ruby
# sound_haver.rb
# $Id: sound_haver.rb,v 1.2 2006/01/24 13:35:57 kbaird Exp $

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

['config', 'instrument'].each do |filename|
  require 'noclergy/' + filename
end

=begin rdoc
Superclass, contains Methods used by multiple objects.

This exists to be an ancestor for any child that has or contains sounds: 
<b>Note</b> and <b>NoteHolder</b> 
(and therefore <b>Measure</b> and <b>Score</b>).
=end
class SoundHaver < Config

	PITCH_CLASS_NAME_FROM_MIDI = %w{ c cs d ef e f fs g af a bf b }
    
	def initialize(inst_abbr)
    debug_no_inst_abbr(inst_abbr)
    super()
		@artS = '' # used by Note
    @dynS = '' # used by Note
    @has_declared_first_soundB = false
		@inst = Instrument.new(inst_abbr)
		@previous_dynS = 'mp'
		@previous_dyn_outputS = 'mp'
		@tempoI = nil
    fail "inst_abbr = #{inst_abbr}" unless @inst.abbr()
	end # initialize

=begin rdoc
Set both <b>@previous_dynS</b> and
<b>@previous_dyn_outputS</b> for this <b>Measure</b>.
=end
  def set_previous_dyns(dynS)
    set_previous_dyns_from_dyn(dynS, false)
  end # set_previous_dyns

  def transpositionI()
    @inst.transposition()
  end # transpositionI

private

	def empty_tags?(node, name)
		return true unless node.getElementsByTagName(name)
		return true unless node.getElementsByTagName(name).item(0)
		return false
	end # empty_tags?

=begin rdoc
Reads the contents of a given XML tag.
=end
	def get_tag_data(node, name, what_to_get='data')
		return '' if empty_tags?(node, name)
		outputS = ''
		tag = node.getElementsByTagName(name).item(0).firstChild()
		case what_to_get
			when 'name'
        outputS = tag.nodeName()
			else 
				fail what_to_get unless tag
				outputS = tag.nodeValue()
		end # case
		debug_XML_vals(outputS)
		return outputS
	end # get_tag_data

=begin rdoc
Set <b>@previous_dynS</b>, and also <b>@previous_dyn_outputS</b> if 
2nd parameter is false (generally <b>Note.rest?</b>, because rests 
don't have dynamic output.).
=end
  def set_previous_dyns_from_dyn(dynS, skip_outputB)
    @previous_dynS = dynS||'mp'
    @previous_dyn_outputS = dynS unless skip_outputB
    @previous_dyn_outputS ||= 'mp'
  end # set_previous_dyns_from_dyn

=begin rdoc
Set <b>@previous_dynS</b> and <b>@previous_dyn_outputS</b>
for this <b>Measure</b> from a single <b>Note</b>
as an argument.
=end
  def set_previous_dyns_from_note(note)
    set_previous_dyns_from_dyn(note.dynS, note.rest?)
  end # set_previous_dyns_from_note

  def tag(name, value, spaces=0, linebreak=true)
    output = ''
    output += (' ' * spaces)
    output += "<#{name}>#{value.inspect}</#{name}>"
    output += "\n" if linebreak
    return output
  end # tag

end # class SoundHaver
