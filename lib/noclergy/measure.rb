#!/usr/bin/env ruby
# measure.rb
# $Id: measure.rb,v 1.34 2006/07/14 13:21:21 kbaird Exp $

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

['markov', 'note', 'note_holder'].each do |filename|
  require 'noclergy/' + filename
end

=begin rdoc
Occurring within a <b>Score</b>, this contains a list of 
<b>Note</b>s, a meter, etc.
=end
class Measure < NoteHolder

  # only subdivide 1/4 or longer with tuplets
  SUB_DIV_I = 4 

  attr_reader :bottomI
  attr_reader :has_declared_first_soundB
  attr_reader :lengthI
  attr_reader :notesA
  attr_reader :numI
  attr_reader :previous_dyn_outputS
  attr_reader :topI

	def initialize(numI, inst_abbr)
		debug_no_inst_abbr(inst_abbr)
    super(inst_abbr)
		debug_inst()
		@feedbackH = {}
		@notesA = NoteList.new()
    @numI = numI # measure number, starting with 1, as normally used
		@previous_duration = nil
		@lengthI = nil # How many 16ths in the measure?
		@previous_dynS = nil
		@previous_dyn_outputS = nil
    fail unless @inst.abbr
	end # initalize

=begin rdoc
Adds the <b>Note</b> argument to its list of <b>Note</b>s, ensuring that
it will fit within the remaining beats in the <b>Measure</b>.
=end
	def add_note(note)
		if remainingI > 0:
			note.set_duration('rand', @previous_duration) until note_will_fit?(note)
			@notesA.push(note)
		  set_previous_dyns_from_note(note)
		end # if remainingI > 0
	end # add_note

=begin rdoc
Adds all of <b>tupletsA</b> arg to <b>@notesA</b>.
=end
	def add_tuplets(tupletsA)
		tupletsA.each do |note|
			@notesA.push(note)
			set_previous_dyns_from_note(note)
		end # tupletsA.each
	end # add_tuplets

=begin rdoc
This method steps through the <b>Note</b>s in <b>Measure.notesA</b>, 
checking for note.tuplet_type values other than 1. It assigns appropriate  
note.tuplet_num values so that Lilypond[http://lilypond.org/] knows when 
to close tuplet brackets.
=end
	def assign_XML_tuplet_nums()
		ordinal_num_within_tuplet_set = 0
	  @notesA.each do |note|
      if note.done_with_tuplets?
        ordinal_num_within_tuplet_set = 0
      elsif note.tuplet?
        ordinal_num_within_tuplet_set += 1
        tuplet_type = note.tuplet_type
        note.make_tuplet(tuplet_type, ordinal_num_within_tuplet_set)
      end # if done with tuplets
      ordinal_num_within_tuplet_set = 0 if ordinal_num_within_tuplet_set == tuplet_type
    end # each note
    assign_non_rest_tuplet_ends('first')
	  assign_non_rest_tuplet_ends('last')
    @notesA.each do |note|
      note.fix_false_double_non_rest_tuplet()
    end # each note
  end # assign_XML_tuplet_nums

=begin rdoc
Generates a <b>Measure</b>'s worth of musical data, 
mainly a list of <b>_notes</b>.
=end
	def construct(tempoI, previous_dynS, first_soundB, methodS='rand')
		@has_declared_first_soundB = first_soundB
		set_previous_dyns(previous_dynS)
		set_meter(methodS)
		set_tempo(tempoI)
		fill_with_notes(methodS)
		set_autobeam_settings()
	end # construct

=begin rdoc
Constructs a new <b>Measure</b>, defining <b>Note</b> 
characteristics via <b>Markov</b> methods.
=end
	def construct_by_markov(tempoI, prev_notesA, markov)
		fail @previous_dyn_outputS.class.to_s unless @previous_dyn_outputS
		fail unless prev_notesA.size > 1
		# make sure @notesA has at least one Note
    prev_note = prev_notesA[0]
		prev2_note = prev_notesA[1]
		set_tempo(tempoI)
		fill_with_notes(markov, prev_note, prev2_note)
	end # construct_by_markov

=begin rdoc
Not set to true if <b>Note</b> arg is a rest or if 
<b>@has_declared_first_soundB</b> is true.
=end
	def declare_first_sound_by_note(note)
		unless @has_declared_first_soundB
			unless note.rest?
				note.declare_first_sound_in_score()
				@has_declared_first_soundB = true
			end # unless note.rest?
		end # unless @has_declared_first_soundB
	end # declare_first_sound_by_note

=begin rdoc
This method attaches a duration to the <b>Note</b> argument. 
It reads <b>@varsH['tupletpc']</b> for the percent chance that a given 
<b>Note</b> will be the start of a tuplet, subject to other limitations. 
The method automatically blocks durations that can not fit within the 
remaining measure.
=end
	def do_duration(note)
		begin
			note.set_duration('rand', @previous_duration)
			# keep creating new notes until they
			# fit inside the remaining measure
			tupletsA = make_tuplets(note) if acceptable_tuplet?(note)
			duration = note.duration
			if remainingI == 0:
				duration = 0
				note = nil
			end # if remainingI == 0
		end until duration <= remainingI
		return tupletsA
	end # do_duration

=begin rdoc
Returns true on a downbeat. Accepts an optional arg which can be 
either an <b>Integer</b> length or <b>Note</b>.
=end
	def downbeat?(lengthI=4)
		if lengthI.class == Note
			lengthI = lengthI.invert_dur(@bottomI)
		end
		(filled % lengthI == 0)
	end # downbeat?

=begin rdoc
This method returns a string describing this <b>Measure</b>
as a fragment of a MusicXML[http://www.recordare.com/xml.html] file.
=end
	def file_write()
		return <<END_OF_FILE_WRITE
<measure number="#{@numI.inspect}">
  <attributes>
    #{tag('divisions', 4)}
    <key><fifths>0</fifths></key>
    <time>
      #{tag('beats', @topI)}
      #{tag('beat-type', @bottomI)}
    </time>
    <clef>
      #{tag('sign', 'G')}
      #{tag('line', 2)}
    </clef>
  </attributes>
	#{tempo_XML_out() if @tempoI}
  #{file_write_transposition()}
	#{file_write_notes()}
</measure>
END_OF_FILE_WRITE
	end # file_write

  def file_write_notes()
		@notesA.map(&:file_write).join('')
  end # file_write_notes

  def file_write_transposition()
		return '' unless (transpositionI == 0)
		%Q[<transpose>#{tag('chromatic', transpositionI)}</transpose>]
  end # file_write_transposition

=begin rdoc
Look for tags in mm_from_XML, returns the last <b>Note</b> to keep
track of <em>first_sound_in_score_B<em> status.
=end
	def from_XML_DOM(mm_from_XML)
    @notesA = mm_from_XML.getElementsByTagName('note').to_a.map do |noteTag|
  		note_from_XML = Note.new(@inst.abbr)
	  	note_from_XML.add_variables(@config)
		  note_from_XML.from_XML_DOM(noteTag)
  		set_previous_dyns_from_note(note_from_XML)
      note_from_XML.debug_nil_dur()
		  declare_first_sound_by_note(note_from_XML)
      note_from_XML
		end # noteTag map
    return @notesA[-1] 
	end # from_XML_DOM

=begin rdoc
Returns the previous dynamic based on whether the 
first sound has been declared. If not, it does the 
declaration for the appropriate <b>Note</b>.
=end
	def get_previous_dynamic_from_note(note)
		if @has_declared_first_soundB:
			previous_dynS = note.previous_dynS
			@previous_dyn_outputS = note.previous_dyn_outputS
		end # if @has_declared_first_soundB
		declare_first_sound_by_note(note)
		return previous_dynS
	end # get_previous_dynamic

=begin rdoc
How far apart are the midi pitches of these <b>Note</b>s?
=end
	def get_separation(curr_note, prev_note)
		(curr_note.midi_pitchI - prev_note.midi_pitchI).abs
	end # get_separation

=begin rdoc
Return new <b>Note</b> characteristics by <b>Markov</b> methods.
=end
	def get_vals_by_markov(prev2_note, prev_note, markov)
		[prev2_note, prev_note].each do |n|
			fail 'not notes' unless n.class == Note
		end # each prev note
		markov.debug_markov_construction()
		prevA = []
		prevA.push(prev2_note.get_val('art'))
		prevA.push(prev_note.get_val('art'))
		debug_previous_notes(prevA, markov)
		new_art = markov.extract('art', prevA)
		prevA = []
		prevA.push(prev2_note.get_val('dyn'))
		prevA.push(prev_note.get_val('dyn'))
		debug_previous_notes(prevA, markov)
		new_dyn = markov.extract('dyn', prevA)
		fail if new_dyn == ' '
    prevA = []
		prevA.push(prev2_note.get_val('midi_pitch'))
		prevA.push(prev_note.get_val('midi_pitch'))
		debug_previous_notes(prevA, markov)
		if (rand(100)+1) <= @varsH['restpc']:
			pitch_arg = 0
		else
			pitch_arg = markov.extract('midi_pitch', prevA)
		end # if do rest
		return [new_art, new_dyn, pitch_arg]
	end # get_vals_by_markov


=begin rdoc
Reports details about this <b>Measure</b>.
=end
	def inspect(markerS='')
		notes_output = ''
    @notesA.each_with_index do |n,i| 
      notes_output += "  % Note[#{i.inspect}]: #{n.inspect}"
		end # each_index
    return <<END_OF_INSPECT
% Measure[#{@numI.inspect}]: #{@topI.inspect}/#{@bottomI.inspect} meter #{markerS}
#{notes_output}
END_OF_INSPECT
	end # inspect

=begin rdoc
Returns an entire <b>Measure</b> in Lilypond[http://lilypond.org/] 
format, complete with a meter declaration and a comment with the 
measure number within the piece.
=end
	def ly_output(previous_dynS)
		break_output = new_system? ? "\n\n\\break" : ''
    notes_output = ''
    @notesA.each do |note|
			notes_output += note.ly_output(@previous_dyn_outputS)
			set_previous_dyns_from_note(note)
		end # each note
		set_previous_dyns(previous_dynS)
    return <<END_OF_LY_OUTPUT
#{break_output}

| % MEASURE #{@numI.inspect}
\\time #{@topI.inspect}/#{@bottomI.inspect} #{notes_output}
END_OF_LY_OUTPUT
	end # ly_output

=begin rdoc
Do a <b>Markov</b>-based mutation at the <b>Measure</b> level.
=end
	def mutate_by_markov(markov)
		die_unless_good_dyn()
    # FIXME make this a method of NoteList?
      1.upto(@notesA.size) do |i|
			note = @notesA[i]
			prev_note = @notesA[i-1]
			if i > 1:
				prev2_note = @notesA[i-2]
			else
				prev2_note = Note.new(@inst.abbr)
				prev2_note.set_articulation('')
				prev2_note.set_dynamics('mp', @previous_dyn_outputS)
				prev2_note.set_pitch(0)
			end # if i > 1
			new_valsA = get_vals_by_markov(prev2_note, prev_note, markov)
			new_art, new_dyn, pitch_arg = new_valsA
			note.set_pitch(pitch_arg)
			note.set_articulation(new_art)
			note.set_dynamics(new_dyn, @previous_dyn_outputS)
			set_previous_dyns_from_note(note)
		end # 1.upto(notesA.size)
	end # mutate_by_markov

	def previous_dyn_output()
		@previous_dyn_outputS
	end # previous_dyn_output

=begin rdoc
Sum this <b>Measure</b>'s <b>Note</b>s' durations.
False if they don't add up to <b>Measure.lengthI</b>.
=end
	def properly_filled?()
    (filled == @lengthI)
	end # properly_filled?

=begin rdoc
Fake "instance variable" method that simply reports 
<b>Measure.lengthI</b> - <b>Measure.filledI</b>.
=end
	def remainingI()
    (@lengthI - filled)
	end # remainingI

=begin rdoc
Puts the feedback <b>Hash</b> into the <b>Measure</b> instance.
=end
	def set_feedback(feedbackH)
		@feedbackH = feedbackH
	end # set_feedback

=begin rdoc
Assigns values to its own states determining meter: top and bottom.
Meters range from 3/8 to 11/8, and are expressed as x/4 if possible.
=end
	def set_meter(topI, bottomI=8)
		topI = @topA[rand(@topA.size)] if topI == 'rand'
		if should_simplify_meter?(topI, bottomI):
			topI /= 2
			bottomI /= 2
		end # if change meter expression
		@topI = topI
		@bottomI = bottomI
		@ticksI = (topI * @@ticks_per_I * 16) / bottomI
		@lengthI = @ticksI / @@ticks_per_I
	end # set_feedback

	def set_tempo(tempoI)
		@tempoI = tempoI if @numI == 1
	end # set_tempo

private

=begin rdoc
Is dividing this <b>Note</b> allowable at this point in the 
<b>Measure</b>?
=end
	def acceptable_tuplet?(note)
		acceptable_tuplet_start? && acceptable_tuplet_sub_div?(note)
	end # acceptable_tuplet?

=begin rdoc
Only do a tuplet if the pc says to, and only on a downbeat
=end
	def acceptable_tuplet_start?()
		downbeat? && ((rand(100)+1) < @varsH['tupletpc'])
	end # acceptable_tuplet_start?

=begin rdoc
Only subdivide certain notes or longer, only if it fits within the measure
=end
	def acceptable_tuplet_sub_div?(note)
		note.at_least_as_long_as?(SUB_DIV_I) && note_will_fit?(note)
	end # acceptable_tuplet_start?

  def assign_non_rest_tuplet_ends(end_pointS)
    found_pitch = false
    @notesA.reverse if end_pointS == 'last'
    @notesA.each do |note|
      if note.tuplet?
        unless found_pitch
          unless note.rest?
            note.make_non_rest_tuplet(end_pointS)
            found_pitch = true
          end # unless rest?
        end # unless found_pitch
      else
        found_pitch = false
      end # if tuplet?
      @notesA.reverse if end_pointS == 'last'
    end # each note
  end # assign_non_rest_tuplet_ends

=begin rdoc
Duration filled so far, in 16ths.
=end
  def filled()
    @notesA.filled()
  end # filled

=begin rdoc
Adds <b>Note</b>s to this <b>Measure.notesA</b>, possibly with 
<b>Markov</b> methods.
=end
	def fill_with_notes(method, prev_note=nil, prev2_note=nil)
    do_markovB = (method.class == Markov)
		
		while remainingI > 0
		  fail 'no inst' unless @inst.abbr
			samplenote = Note.new(@inst.abbr)
			samplenote.add_variables(@config)
			tupletsA = do_duration(samplenote)

			if do_markovB:
				new_valsA = get_vals_by_markov(prev2_note, prev_note, method)
				art_arg = new_valsA[0]
				dyn_arg = new_valsA[1]
				fail if dyn_arg == ' '
        pitch_arg = new_valsA[2]
				debug_num(pitch_arg)
			else
				art_arg = method
				dyn_arg = method
				pitch_arg = method
				debug_num(pitch_arg)
			end # if do_markovB

      fail if dyn_arg == ' '
			debug_num(pitch_arg)
			samplenote.set_pitch(pitch_arg)
			samplenote.set_articulation(art_arg)
			fail if @previous_dyn_outputS == ('no dynamic set yet' || 'dynamics')
		  fail @previous_dyn_outputS.class.to_s unless @previous_dyn_outputS
      samplenote.set_dynamics(dyn_arg, @previous_dyn_outputS)
			set_previous_dyns_from_note(samplenote)
			samplenote.set_remaining(remainingI)
			declare_first_sound_by_note(samplenote)
			if tupletsA:
				add_tuplets(tupletsA)
			else
				add_note(samplenote)
			end # if tupletsA

			if do_markovB:
				prev2_note = prev_note.dup
				prev_note = samplenote.dup
			end # if do_markovB

		end # while remainingI
	end # fill_with_notes

=begin rdoc
This creates a set of tuplets to fill the duration of the <b>Note</b> 
parameter. The type of tuplet is determined by the master_tupletA Array 
in the main Ruby[http://www.ruby-lang.org/] script. That tuplet type 
then falls within the space of the closest lower power of 2: 
5 in 4, 3 in 2, etc. In other words, it only creates tuplets which go 
faster than the base note type. 
=end
	def make_tuplets(note)
		fail 'unupdated dynS' if @previous_dyn_outputS == 'no dynamic set yet'
		tuplet_type = @master_tupletA[rand(@master_tupletA.size)]
		subdivideI = note.get_nearest_2_power(tuplet_type) # 3/2, 5/4, 7/4, etc.
		
    begin # until some non-rests
	  	tupletA = NoteList.new()
			1.upto(tuplet_type) do |ordinal_num_within_tuplet_set|
				tupletnote = Note.new(@inst.abbr)
				tupletnote.add_variables(@config)
				tupletnote.make_tuplet(tuplet_type, ordinal_num_within_tuplet_set)
				tupletnote.set_pitch('rand')
				tupletnote.set_articulation('rand')
				tupletnote.set_dynamics('rand', @previous_dyn_outputS)
				declare_first_sound_by_note(tupletnote)
				tupletnote.set_duration((note.duration / subdivideI), @previous_duration)
				tupletnote.set_ticks(note.duration * @@ticks_per_I / tuplet_type)
				tupletA.push(tupletnote)
			end # 1.upto(tuplet_type)
		end until tupletA.some_non_rests?
        
		return tupletA
	end # make_tuplets

=begin rdoc
Returns <b>true</b> if this <b>Measure</b> should begin a new page system.
=end
	def new_system?()
		(@numI % @@mm_per_systemI == 1) && (@numI > @@mm_per_systemI)
	end # new_system?

	def note_will_fit?(note)
		note.duration <= remainingI
	end # note_will_fit?

=begin rdoc
Cycles through <b>Note</b>s, removing expressions (articulations and
dynamics) from all tied notes except the first. Used only for
display in Lilypond[http://lilpond.org/]; does not affect what's 
stored as MusicXML[http://www.recordare.com/xml.html].
=end
	def remove_adjacent_expressions()
		new_notesA = NoteList.new()
		1.upto(@notesA.size) do |i| 
			note = @notesA[i]
			prev_note = @notesA[i-1]
			note.set_articulation('') if same_val?('art', note, prev_note)
			note.set_dynamics('', @previous_dyn_outputS) if same_val?('dyn', note, prev_note)
			new_notesA.push(note)
			@notesA.replace(new_notesA)
			set_previous_dyns_from_note(note)
		end # 1.upto(@notesA.size)
	end # remove_adjacent_expressions

=begin rdoc
Returns <b>true</b> if both <b>Note</b>s have the same value for 
<em>type</em> (one of articulation or dynamics).
=end
	def same_val?(type, note, prev_note)
		case type
			when 'art'
				return note.artS == prev_note.artS
			when 'dyn'
				return note.dynS == prev_note.dynS
		end # case
	end # same_val

# Called from within set_autobeam_settings
  def set_autobeam_for_note_pair(prev_note, curr_note, max_separationI)
		if prev_note.first_tuplet_in_set?:
			prev_note.set_autobeam('suspend')
		elsif curr_note.last_tuplet_in_set?:
			curr_note.set_autobeam('resume')
		elsif curr_note.tied?:
			prev_note.set_autobeam('suspend')
			curr_note.set_autobeam('resume')
		end # if prev_note.first_tuplet_in_set?

		# separate loop from above, so that it will
		# break beams within tuplets as well
		unless prev_note.rest?
			separationI = get_separation(curr_note, prev_note)
			if separationI > max_separationI:
				prev_note.set_autobeam('suspend')
				curr_note.set_autobeam('resume')
				# break beams if notes are 15+ semitones apart
			end # if separationI > max_separationI
		end # unless prev_note.rest?
  end # set_autobeam_for_note_pair

=begin rdoc
Cycle through <b>Note</b>s, turn auto-beaming
on or off as demanded aesthetically.
=end
	def set_autobeam_settings(max_separationI = 15)
		# FIXME make a method of NoteList
    1.upto(@notesA.size-1) do |i|
			prev_note = @notesA[i-1]
			curr_note = @notesA[i]
      set_autobeam_for_note_pair(prev_note, curr_note, max_separationI)
		end # 1.upto(@notesA.size)
	end # set_autobeam_settings

=begin rdoc
Reports true for 4/8, 6/8, 8/8, 10/8, etc. Leaves 2/8 alone.
=end
  def should_simplify_meter?(topI, bottomI)
		(topI % 2 == 0) && (topI > 2) && (bottomI == 8)
  end # should_simplify_meter?

=begin rdoc
Outputs tempo indications according to 
MusicXML[http://www.recordare.com/xml.html] spec.
=end
	def tempo_XML_out()
		return '' unless (@tempoI > 0 && @numI == 1)
		%Q[<direction><sound tempo="#{@tempoI.inspect}" /></direction>]
	end # tempo_XML_out

end # class Measure
