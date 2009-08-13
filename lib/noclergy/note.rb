#!/usr/bin/env ruby
# note.rb
# $Id: note.rb,v 1.42 2006/05/30 11:31:40 kbaird Exp $

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

['sound_haver', 'tupletable'].each do |filename|
  require 'noclergy/' + filename
end

=begin rdoc
This is an individual sound/silence event within a <b>Measure</b>. 
It has states for pitch, duration, articulation, dynamics, tuplet 
(boolean), tuplet_type (1 for normal notes, 3 for triplets, etc.), 
and tuplet_num (what number am I out of 3 or 5 or whatever? - 1 for 
non-tuplets). self.pitch is 'r' for a rest, and duration is the 
number of 16th notes in its normal (i.e. non-tuplet) note type, 
rather than the number commonly associated with the note type. So 
an eighth note has a dur of 2, not 8.

Tuplet info has been moved into the <b>Tupletable</b> module.
=end
class Note < SoundHaver

  include Tupletable

  ART_A = ['staccatissimo', 'staccato', 'marcato', 'accent', '', 'portato', 'tenuto']
	
  DUR_A = [1, 2, 4, 8, 16]
  
  # Greater number of 1 values (16ths) to 
  # make 16ths more common after a 16th
	DUR16A = [1, 1, 1, 1, 1, 2, 2, 4, 8, 16]
    
	DYN_A = %w{ ppp pp p mp mf f ff fff }

  ATT_HASH = { 'art' => ART_A, 'dyn' => DYN_A }

  # used to invert note type and duration in 16ths
  INVERT_NOTE_DURTYPE = {
    1=>16, 2=>8,  3=>8,  4=>4, 
    6=>4,  8=>2, 12=>2, 16=>1
  } 

  NOTE_NAME_FROM_DURTYPE = { 
    16=>'whole',    12=>'half',     8=>'half', 
    6=>'quarter',   4=>'quarter',   3=>'eighth', 
    2=>'eighth',    1=>'sixteenth', ' '=>'quarter'
  }
    
  PITCH_CLASS_FROM_NAME = {
    'c'=>0, 'd'=>2, 'e'=>4, 'f'=>5, 
    'g'=>7, 'a'=>9, 'b'=>11
  }
    
	attr_reader :artS
	attr_reader :duration
	attr_reader :dynS
	attr_reader :midi_pitchI
	attr_reader :previous_dyn_outputS
	attr_reader :previous_dynS
	attr_reader :varsH

# CLASS METHODS

=begin rdoc
Class Method that returns default <b>Array</b>s for articulation or dynamics.
=end
	def Note.get_att_array(att)
		ATT_HASH[att]
	end # get_att_array

# INSTANCE METHODS

=begin rdoc
Receives a <b>String</b> of the instrument abbreviation.
=end
	def initialize(inst_abbr)
		super(inst_abbr)
    define_tuplet_vars()
    debug_inst()
		@artS = ''
		@auto_beam_suspendB = nil
		@auto_beam_resumeB = nil
		@duration = nil
		@dynS = 'mp' # arbitrary starting dynamic
    @first_sound_in_scoreB = false
    @midi_pitchI = nil
		@tiedB = false
	end # initialize

  def at_least_as_long_as?(timeI)
    @duration >= timeI
  end # at_least_as_long_as

=begin rdoc
The purpose is to make sure the first note of
a <b>Score</b> always has an explicit dynamic mark.
=end
	def declare_first_sound_in_score(truth_value = true)
		@first_sound_in_scoreB = truth_value
	end # declare_first_sound_in_score

=begin rdoc
This method returns a string consisting of an entire <note> element compliant 
with the MusicXML[http://www.recordare.com/xml.html] DTD. It is called from
the <b>Measure</b> object's <b>file_write</b> method.
=end
	def file_write()
		fail unless @duration
		return <<END_OF_FILE_WRITE
  <note>
#{"<!-- 1st note in score -->\n" if @first_sound_in_scoreB}
#{file_write_pitch_or_rest}
#{tag('duration', INVERT_NOTE_DURTYPE[@duration], 3)}
#{tag('type', NOTE_NAME_FROM_DURTYPE[@duration], 3)}
#{file_write_tuplet_time}
#{add_xml_notations_tag}
  </note>
END_OF_FILE_WRITE
	end # file_write

=begin rdoc
Return an <b>Integer</b> duration in 16ths. For tuplets, it returns 
- zero in some cases when the tuplets are 'shortened'/'normal': 3:2, 5:4, etc. 
- an extra-long first note when tuplets are 'stretched': 7:8, etc.
Both of these alterations are intended to normalize the total tuplet set duration.
=end
  def filled()
    return @duration unless tuplet?
    return 0 if within_tuplet_nums_to_ignore?
    return first_stretched_duration if first_of_stretched_tuplet_set? 
    return @duration # normal duration tuplet
  end # filled

=begin rdoc
Look for tags in noteTag
=end
	def from_XML_DOM(noteTag)
		artS = ''
		alterI = nil
		octaveI = nil
		stepS = nil
		@duration = get_dur_from_XML(noteTag)
		if rest_XML_tag?(noteTag):
			set_pitch(0)
		else
			debug_XML_vals()
      @dynS = get_tag_data(noteTag, 'dynamics', 'name')
			artS = get_tag_data(noteTag, 'articulations', 'name')
			techS = get_tag_data(noteTag, 'technical', 'name')
			artS = techS if techS.size > artS.size()
			artS = @inst.translate_art_from_XML(artS)
			@artS += artS
			noteTag.getElementsByTagName('pitch').each do |pitchTag|
				stepS = get_tag_data(pitchTag, 'step')
				debug_nil_SAO(stepS, 'stepS after pitchTag')
				alterI = get_tag_data(pitchTag, 'alter').to_i()
				octaveI = get_tag_data(pitchTag, 'octave').to_i()
			end # each pitchTag
			debug_XML_vals()
			set_pitch_from_XML(stepS, alterI, octaveI)
		end # if rest_XML_tag?
    make_tuplets_from_XML(noteTag)
    end # from_XML_DOM

	def get_dur_from_XML(noteTag)
		divisorI = get_tag_data(noteTag, 'duration').to_i()
		return 16 / divisorI
	end # get_dur_from_XML

=begin rdoc
Returns the nearest power of 2 less than the argument. Useful for
determining how many non-tuplet notes a tuplet occurs within the space
of. E.g: 3 triplets occur within the space of 2, and this method
returns 2 when given 3, etc. It does not support more exotic
tuplet types (such as 7 in the space of 8). An optional <b>Boolean</b> 
argument allows the return value to be <=, not just less than.
=end
	def get_nearest_2_power(i, equal_ok=false)
    return 1 if i < 2
    arg = equal_ok ? i : i - 1 
    2 * get_nearest_2_power((arg / 2), true)
	end # get_nearest_2_power

=begin rdoc
Retrieve various <b>Note</b> values: pitch class, pitch, dynamics, articulation, duration.
=end
	def get_val(attS)
    fail if @dynS == ' '
    output = nil
    case attS
			when 'pc': output = (@midi_pitchI % 12)
			when 'midi_pitch': output = @midi_pitchI
			when 'dyn': output = @dynS
			when 'art': output = @artS
			when 'dur': output = @duration
		end # case
    fail unless output
    fail unless [String, Fixnum].include?(output.class)
    return output
	end # get_val

  def invert_dur(valI)
    INVERT_NOTE_DURTYPE[valI]
  end

  def instS()
    @inst.name()
  end # instS

=begin rdoc
Returns this <b>Note</b>'s Lilypond[http://lilypond.org/] output.
=end
	def ly_output(previous_dyn_outputS)
    last_tuplet_string = "\n} % end tuplet set\n"
		return <<END_OF_LY_OUTPUT
#{"\n\\autoBeamOff\n" if (tuplet? && @auto_beam_suspendB)}
#{ly_output_tuplet_open() if first_tuplet_in_set?}
#{ly_output_pitch(INVERT_NOTE_DURTYPE[@duration])}
#{ly_tuplet_markers}
#{ly_output_dyn(previous_dyn_outputS)}
#{ly_output_art + ' '}
#{last_tuplet_string if last_tuplet_in_set?}
#{"\n\\autoBeamOn\n" if @auto_beam_resumeB}
END_OF_LY_OUTPUT
	end # ly_output

  def ly_output_art()
		return '' if rest?
	  return <<END_OF_LY_ART
#{'-\\' + @artS if (@artS.strip.size > 0)}
#{' -' if tied?}
END_OF_LY_ART
  end # ly_output_art

=begin rdoc
feedbackH contains entries like {'pitch': 5} 
for maximum high pitch, etc. charS and charA 
stand for the characteristic to be mutated.
=end
	def mutate_by_feedback(typeS, feedbackH)
    fI = 0; wI = 1
		if feedbackH: 
			fI = feedbackH[typeS] || 0 # force
			wI = feedbackH[typeS + 'var'] || 1 # width
		end # if feedbackH
		unless rest?
      case typeS
	      when 'pitch'
				  mutate_pitch_by_feedback(fI, wI, typeS, feedbackH)
			  else
			    mutate_non_pitch_by_feedback(fI, wI, typeS, feedbackH)
		  end # case typeS
    end # unless rest?
	end # mutate_by_feedback

=begin rdoc
Fake "as variable" Method.
=end
  def octaveS()
    return '' if rest?
    get_ly_octave_marks()
  end # octaveS

=begin rdoc
Fake "as variable" Method.
=end
  def pitch()
    return 'r' if rest?
    fail unless @midi_pitchI.class == Fixnum
    fail unless transpositionI.class == Fixnum
    temp_pitchI = @midi_pitchI - transpositionI
    PITCH_CLASS_NAME_FROM_MIDI[temp_pitchI % 12]
    end # pitch

# Boolean predicate, (@midi_pitch == 0)?
	def rest?()
		(@midi_pitchI == 0)
	end # rest?

# Boolean predicate, are there any such XML tags?
	def rest_XML_tag?(noteTag)
		(noteTag.getElementsByTagName('rest').size > 0)
	end # rest_XML_tag?

=begin rdoc
Accepts literal values, 'rand', 'shorter', or 'longer'.
=end
	def set_articulation(artS)
    fail 'bad artS' unless artS.class == String
		new_index = nil
		case artS
			when 'rand'
				if rest?
					artS = ''
				elsif rand(100) < @varsH['artpc']:
					artS = ART_A[rand(ART_A.size)]
				else
					artS = ''
				end # if < pc
			when 'longer'
				new_index = bound(0, ART_A.index(@artS)+1, ART_A.size-1)
			when 'shorter'
				new_index = bound(0, ART_A.index(@artS)-1, ART_A.size-1)
		end # case
		artS = ART_A[new_index] if new_index
		@artS = artS
	end # set_articulation

=begin rdoc
Receives either 'resume' or 'suspend'.
=end
	def set_autobeam(type)
		@auto_beam_resumeB == true if type == 'resume'
		@auto_beam_suspendB == true if type == 'suspend'
	end # set_autobeam

=begin rdoc
Accepts literal values or 'rand'.
=end
	def set_duration(duration, previous_duration=0)
		if duration == 'rand'
			durA     = DUR_A
			durA     = DUR16A if previous_duration == 1
			duration = durA[rand(durA.size)]
		end # if rand
    fail 'bad duration' unless duration.class == Fixnum
		@duration = duration
		@ticksI   = duration * @@ticks_per_I / @tuplet_type
	end # set_duration

=begin rdoc
Accepts literal <b>Strings</b> or 'rand', 'softer', or 'louder'.
=end
	def set_dynamics(dynS, previous_dynS)
		fail unless dynS.class == String
		fail previous_dynS.class.to_s unless previous_dynS.class == String
    set_previous_dyns_from_dyn(previous_dynS, rest?)
		case dynS
			when 'rand'
				dynS, previous_dynS = set_dynamics_rand(dynS, previous_dynS)
			when 'louder'
				new_index = bound(0, DYN_A.index(@dynS)+1, DYN_A.size-1)
			when 'softer'
				new_index = bound(0, DYN_A.index(@dynS)-1, DYN_A.size-1)
		end # case dynS
		dynS = DYN_A[new_index] if new_index
		@dynS = dynS
    fail if @dynS == ' '
	end # set_dynamics

=begin rdoc
Accepts literal <b>Integers</b> or 'rand'.
=end
	def set_pitch(pitch)
    fail 'no inst' unless @inst.abbr
		if pitch == 'rand'
			unless rand(100) > @varsH['restpc']:
	  		pitch = 0
			else
				rangeA = (lowestI...highestI).to_a
				pitch = rangeA[rand(rangeA.size)]
			end # unless make a rest
		end # if rand
    fail "bad pitch: #{pitch}" unless pitch.class == Fixnum
		@midi_pitchI = pitch
	end # set_pitch

	def set_remaining(remainingI)
		@remainingI = remainingI
	end # set_remaining

=begin rdoc
Accepts literal <b>Integers</b> only.
=end
	def set_ticks(ticksI)
		@ticksI = ticksI
	end # set_ticks

	def tied?()
		@tiedB
	end # tied?

private

=begin rdoc
Deal with slight differences in articulation names between 
MusicXML and Lilypond.
=end
  def add_xml_articulations_tag(art)
    return '' if art == ''
		return '    <articulations>' + art + '</articulations>' + "\n" 
  end # add_xml_articulations_tag

=begin rdoc
Deal with slight differences in articulation names between 
MusicXML and Lilypond.
=end
  def add_xml_notations_tag()
    output = ''
	  if (@artS || @dynS):
			if (@artS.strip.size > 0) || (@dynS.strip.size > 0):
				xml_artS = ''
				output += '   <notations>' + "\n"
				output += file_write_tuplet_type() if tuplet?
				output += '    <dynamics><' + @dynS + ' /></dynamics>' + "\n" 
				xml_artS += @inst.file_write_art(@artS)
				output += add_xml_technical_tag(@arts, xml_artS)
				output += add_xml_articulations_tag(xml_artS)
				output += '   </notations>' + "\n"
			end # if non spaces
		end # if (@artS || @dynS)
    return output
  end # add_xml_notations_tag

=begin rdoc
Deal with slight differences in articulation names between 
MusicXML and Lilypond.
=end
  def add_xml_technical_tag(art, xml_art)
    tech = nil
    case art
		  when '<stopped />': tech = xml_art
			when 'upbow': tech = '<up-bow />'
			when 'downbow': tech = '<downbow />'
		end # case art
		return '   <technical>' + xml_tech + '</technical>' + "\n" if tech
    return ''
  end # add_xml_technical_tag

=begin rdoc
Used by vary_gauss. Returns the lesser of 
distance from center to either end, unless that value 
would be less than 1. In that case it returns the greater.  
The reasoning behind this is to prevent extreme values from 
being 'locked in', preventing bouncing back by Markovian 
or audience feedback data.
=end
	def calc_space(minvalI, maxvalI, centerI)
		top_rangeI = maxvalI - centerI
		bottom_rangeI = centerI - minvalI
		spaceI = [top_rangeI, bottom_rangeI].min
		spaceI = [top_rangeI, bottom_rangeI].max if spaceI < 1
		return spaceI
	end # calc_space

=begin rdoc
Fake "as variable" Method. Returns nil for white notes and 
<b>String</b>s '1' for sharp and '-1' for flat.
=end
  def alterS
    return nil  if pitch.size == 0
    return '1'  if pitch[1,1] == 's'
    return '-1' if pitch[1,1] == 'f'
  end # alterS

=begin rdoc
Outputs MusicXML[http://www.recordare.com/xml.html] for the <em>pitch</em> 
tag of a <b>Note</b>, or a <em>rest</em> tag for a rest.
=end
	def file_write_pitch_or_rest()
		return "   <rest />\n" if rest?
		xmlS = '   <pitch>'
		
    # Lilypond stores pitches like 'fs' for f#
		xmlS += "<step>#{pitch[0].chr}</step>"
    xmlS += tag('alter', alterS, 0, false) if alterS
		xmlS += tag('octave', get_octaveI_from_midi_pitch(), 0, false)
		xmlS += "</pitch>\n"
		return xmlS
	end # file_write_pitch_or_rest

=begin rdoc
Prevents the variation from bouncing back against the 
direction of the audience's wishes.
=end
	def fix_vary_direction(variationI, forceI)
		unless forceI == 0:
		  # only bother with this if there is a clear 
  		# direction (i.e., not 0) from the audience
	  	directionI = forceI / forceI.abs # -1 or +1
		  variationI *= -1 if (variationI * directionI < 0)
  		# if relative direction is negative, they are 
	  	# in opposite directions. multiplication works 
      # as well as division, and is presumably faster.
		end # unless forceI == 0
		return variationI
	end # calc_space

=begin rdoc
sigmaI = standard deviation
muI = mean
diceI = number of random numbers to sum
=end
	def gauss(sigmaI, muI, diceI=20)
		sumI = 0
		diceI.times do
			sumI += rand(2)
		  gaussI = sigmaI * (sumI - (diceI / 2))
		end # diceI.times
		return gaussI + muI
	end # gauss

=begin rdoc
Returns 0 if within range or a rest, -1 if too high, and 1 if too low. 
These values are used for multiplication outside of this method. Multiply a 
<b>Note</b>'s output from this Method by 12 and add it to the <b>Note</b>'s 
<em>midi_pitchI</em> until it's back inside the instrument's range.
=end
	def get_inst_range_multi(midi_pitchI)
		return  0 if rest?
		return -1 if midi_pitchI > highestI
		return  1 if midi_pitchI < lowestI
		return  0 # within range
	end # get_inst_range_multi

=begin rdoc
Returns an <b>Integer</b> representing a MusicXML[http://www.recordare.com/xml.html] 
<octave> tag value appropriate for the <b>midi_pitchI</b> argument. 
=end
	def get_octaveI_from_midi_pitch(midi_pitchI=@midi_pitchI)
    (midi_pitchI / 12) - 2
	end # get_octaveI_from_midi_pitch

=begin rdoc
Extracts step, alter and octave tags from XML and generates internal pitch.
=end
	def set_pitch_from_XML(stepS, alterI, octaveI)
    octaveI += 2 # MusicXML octave3 == MIDI octave 5
    stepI = PITCH_CLASS_FROM_NAME[stepS]
    fail "No stepI for stepS #{stepS} in #{PITCH_CLASS_FROM_NAME.print_r}" unless stepI
    midi_pitchI = (octaveI * 12) + stepI + alterI
		set_pitch(midi_pitchI)
	end # set_pitch_from_XML

=begin rdoc
Fake "as variable name" Method.
=end
    def highestI()
      debug_inst()
      @inst.range[1]
    end # highestI

    def in_range?()
      return true if rest? # 0 midi pitch is fine for rests
      (@midi_pitchI <= highestI) && (@midi_pitchI >= lowestI)
    end # in_range?

=begin rdoc
Fake "as variable name" Method.
=end
    def lowestI()
      @inst.range[0]
    end # lowestI

=begin rdoc
Outputs Dynamic indicators for a <b>Note</b> in 
Lilypond[http://lilypond.org/] format. 
=end
	def ly_output_dyn(previous_dyn_outputS)
		return '-\\' + @dynS if @first_sound_in_scoreB
    set_previous_dyns_from_dyn(previous_dyn_outputS, rest?)
		unless (rest? or tied?) # no rests or tied notes
			unless @dynS == @previous_dyn_outputS
				if (@dynS && @dynS.size > 0):
					return '-\\' + @dynS
				end # if @dynS
			end # unless repeated dynS
		end # unless (rest? or tied?)
		return ''
	end # ly_output_dyn

=begin rdoc
Prepares a <b>Note</b>'s pitch data for transposed 
Lilypond[http://lilypond.org/] output. It is generalized enough to  
handle transposition values other than the ones I happen to be using. 
I've decided to store the musical data in the XML files in concert  
pitch and only worry about transposition for display.

I currently determine transposition values from the instrument name 
and a <b>Hash</b>, but I should eventually write it the XML file.
=end
	def ly_output_pitch(rhythmI)
		unless (@midi_pitchI && transpositionI):
			fail "midi_pitchI = #{@midi_pitchI.inspect} transpositionI = #{transpositionI}"
		end # fail unless
		return "r#{rhythmI.to_s}" if rest?
    return pitch + octaveS + rhythmI.to_s()
	end # ly_output_pitch

	def mutate_var_by_force(forceI, widthI, minI, maxI, currI)
		return 0 if (forceI == 0)
		vary_gauss(minI, maxI, currI, forceI, widthI)
	end # mutate_var_by_force

	def mutate_non_pitch_by_feedback(forceI, widthI, typeS, feedbackH)
    fail if @dynS == ' '
    fail 'nil att' unless (@artS && @duration && @dynS)
    case typeS
			when 'art': mut = @artS; mutA = ART_A
			when 'dur': mut = @duration; mutA = DUR_A
			when 'dyn': mut = @dynS; mutA = DYN_A
      else fail
		end # case typeS
    fail if mut == 'rest'
    currentI = mutA.index(mut)
    fail "#{mutA.print_r}\n" + "typeS = #{typeS}, mut = #{mut}, class = #{mut.class.to_s}" unless currentI
		varI = mutate_var_by_force(forceI, widthI, lowestI, highestI, @midi_pitchI)
		index = currentI + varI
		index = bound(0, index, mutA.size-1)
		case typeS
			when 'art': set_articulation(mutA[index])
			when 'dur': set_duration(mutA[index])
			when 'dyn': set_dynamics(mutA[index], @previous_dyn_outputS)
		end # case typeS
	end # mutate_non_pitch_by_feedback

	def mutate_pitch_by_feedback(forceI, widthI, typeS, feedbackH)
		varI = mutate_var_by_force(forceI, widthI, lowestI, highestI, @midi_pitchI)
		new_pitchI = @midi_pitchI + varI
		new_pitchI = bound(lowestI, new_pitchI, highestI)
		set_pitch(new_pitchI) if new_pitchI > -1
	end # mutate_pitch_by_feedback

=begin rdoc
Returns a <b>String</b> with Lilypond[http://lilypond.org/] octave markers 
appropriate for the midi_pitchI argument, modified by transpositionI. 
Returns an empty <b>String</b> for rests.
=end
	def get_ly_octave_marks(midi_pitchI=@midi_pitchI)
		return '' if rest?
		temp_pitchI = midi_pitchI - transpositionI
		temp_octaveI = (temp_pitchI / 12) - 4
    # -4 because 5th octave begins high markers
    return '' if (temp_octaveI == 0)
    mark = (temp_octaveI > 0) ? "'" : ','
    return (mark * temp_octaveI.abs) 
	end # get_ly_octave_marks

=begin rdoc
Set dynamic strings when the method is 'rand'.
=end
	def set_dynamics_rand(dynS, previous_dynS)
		return dynS, previous_dynS if rest?
		if rand(100) < @varsH['dynpc']:
			dynS = DYN_A[rand(DYN_A.size)]
		else
			previous_dynS ||= 'mp' 
			dynS = previous_dynS
		end # if < pc
		return dynS, previous_dynS
	end # set_dynamics_rand

=begin rdoc
<em>divisor_multI</em> = portion of range to utilize, for example: 
<em>divisor_multI</em> = 2 means that maximum values range halfway to 
the extreme end. <em>divisor_multI</em> = 4 means it ranges 1 
quarter of the way, etc.

- <em>minI</em>, <em>maxI</em> = boundaries of range of variation

- <em>centerI</em> = mean of variation within range

- <em>forceI</em> = audience feedback (-5 to 5)
	-5 = much less (of whatever characteristic)
	+5 = much more (of whatever characteristic)

- <em>widthI</em> = audience feedback (-5 to 5)
	-5 = very narrow variation (i.e. tight Gaussian)
	+5 = very wide variation (i.e. flat)

Combine (0-width) flat dists over inst's range (min 0) 
+ (width) Gaussian distributions (min 0)

Gaussian dists are <b>Note#gauss(1, center, space)</b>, where
space = lesser of (max-center) or (center-min)

TODO: fix space - if it's at an end point, there's 
no room for it to go the other way either with space = 0
=end
	def vary_gauss(minI, maxI, centerI, forceI, widthI)
		divisor_multI = 1 # use the whole range
		newvalI = 0
		spaceI = calc_space(minI, maxI, centerI)
		divisorI = forceI * divisor_multI
		orig_centerI = centerI.dup
		center += (forceI * spaceI / divisorI)
		spaceI = calc_space(minI, maxI, centerI)
		num_unifI = bound(1, widthI, widthI)
		num_gaussI = bound(1, widthI, widthI)
		# ensures no lower than 1 for both
		num_gaussI.times { newvalI += gauss(1, centerI, spaceI) }
		unifA = (minI...maxI+1).to_a
		num_unifI.times { newvalI += unifA[rand(unifA.size)] }
		newvalI = newvalI / (num_gaussI + num_unifI)
		return newvalI - orig_centerI # output change only
	end # vary_gauss

end # class Note
