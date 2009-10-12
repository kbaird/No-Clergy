#!/usr/bin/env ruby
# debugable.rb
# $Id: debugable.rb,v 1.6 2006/07/14 13:21:21 kbaird Exp $

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

module Debugable

  def debug_inst(asserted_inst=nil)
    unless @inst.abbr.class == String
      fail 'bad instS = ' + @inst.print_r() + ' ' + @inst.abbr.class.print_r()
    end
  end # debug_inst

  def debug_markov_construction(previousA=nil)
    if previousA
      previousA.each { |p| fail p.class.to_s unless proper_markov_member?(p) }
    end # if previousA
    @markovH.each_key do |k|
      fail 'bad key: ' + k.print_r() unless ['art', 'dur', 'dyn', 'midi_pitch'].include?(k)
      fail unless @markovH[k].class == Hash
      @markovH[k].each_key do |j|
        fail 'bad key: ' + j.print_r() unless proper_markov_member?(j)
        case k
          when 'art': legalA = Note.get_att_array('art')
          when 'dyn': legalA = Note.get_att_array('dyn')
        end # case
        if legalA:
          fail 'bad key: ' + j.print_r() unless legalA.include?(j)
        else
          fail 'bad key: ' + j.print_r() unless j.instance_of?(Fixnum)
        end
      end # @markovH[k].each_key
    end # @markovH.each_key
  end # debug_markov_construction

  def debug_markov(att, prev2, prev1)
    debug_markov_construction()
    fail unless @markovH
    fail unless att
    fail "#{@markovH.print_r} #{att.print_r}"      unless @markovH[att]
    fail "#{@markovH[att].print_r} prev2=#{prev2}" unless @markovH[att][prev2]
    fail debug_markov_message(att, prev2, prev1)   unless @markovH[att][prev2][prev1]
  end # debug_markov

  def debug_markov_message(att, prev2, prev1)
    "\nprev2 = #{prev2.print_r}, prev1 = #{prev1.print_r}, " + 
    "@markovH[#{att.print_r}][#{prev2.print_r}] = \n" +
    "#{@markovH[att][prev2].print_r}\n" 
  end # debug_markov_message

  def debug_measures()
    fail 'no measures' unless @measuresA.size > 0
    fail 'one measure' unless @measuresA.size > 1
  end # debug_measures

  def debug_nil_dur(argS=nil)
    argS = 'nil dur' unless argS
    fail argS unless @duration
  end # debug_nil_dur

  def debug_nil_durs()
    @notesA.each { |note| note.debug_nil_dur() }
  end # debug_nil_durs

  def debug_nil_pitch(argS=nil)
    argS = 'nil pitch' unless argS
    fail argS unless @midi_pitchI
  end # debug_nil_dur

  def debug_nil_SAO(argV, argS=nil)
    argS = 'nil SAO' unless argS
    fail argS unless argV
  end # debug_nil_dur

  def debug_no_inst_abbr(inst_abbr)
    fail 'No inst_abbr' + "\n" if (inst_abbr == '')
    fail 'Nil inst_abbr' + "\n" unless inst_abbr
  end # debug_no_inst_abbr
  
=begin rdoc
When <b>Mutator</b> contains multiple <b>Outputer</b>s, 
this will only be executed for a real instrument.
=end
  def debug_no_xml_files(filenamesA)
    disable = true
    unless ((filenamesA.size > 0) or disable)
      fail "no files in #{@xml_dirname}"
    end
  end # debug_no_xml_files

  def debug_notes_XML()
    @notesA.each(&:debug_XML_vals)
  end # debug_notes_XML

  def debug_num(arg)
    unless (arg == 'rand' || [Fixnum, Integer].include?(arg.class))
      fail "pitch ain't num: #{arg.class.to_s} #{arg.to_s}"
    end
  end # debug_num

  def debug_previous_notes(prevA, markov)
    prevA.each { |p| fail p.class.to_s unless markov.proper_markov_member?(p) }
  end # debug_previous_notes

=begin rdoc
Marks pitches that are too low for debugging purposes.
=end
  def debug_too_low()
    debug_nil_pitch()
    if @midi_pitchI < lowestI:
      return "\n%too low\n" unless rest?
    end # if too low
  end # debug_too_low
    
  def debug_val(valuesA)
    badA = ['articulations', 'pitch', 'dynamics', 'no dynamic set yet']
    valuesA.each { |v| fail v.print_r() if badA.include?(v) }
  end # debug_val

  def debug_varsHmm(key='number_of_measures')
    fail "bad varsH[#{key}]\n" unless (varsH[key] > 0)
  end

  def debug_XML_vals(arg=nil)
    testA = [@artS, @dynS]
    if arg:
      testA.clear()
      testA.push(arg)
    end # if arg
    badA = ['articulations', 'pitch', 'dynamics', 'no dynamic set yet']
    testA.each { |t| fail t.inspect() if badA.include?(t) }
  end # debug_XML_vals

  def die_unless_good_dyn()
    fail @previous_dyn_outputS.class.to_s unless @previous_dyn_outputS
    fail @previous_dynS.class.to_s unless @previous_dynS
  end # die_unless_good_dyn

=begin rdoc
Returns get_val(att) for a random member of @notesA.
Used when Markov Chain construction fails.
=end
  def failsafe(att)
    @notesA[rand(@notesA.size)].get_val(att)
  end # failsafe

=begin rdoc
Reports details about a <b>Note</b>.
=end
  def inspect_mod()
    inspectS  = ly_output_pitch(INVERT_NOTE_DURTYPE[@duration])
    inspectS += @midi_pitchI.inspect()
    inspectS += ', 1st sound' if @first_sound_in_scoreB
    inspectS += ', ' + @artS unless @artS.strip == ''
    inspectS += ', ' + @dynS
    inspectS += inspect_mod_tuplet()
    inspectS += "\n"
    return inspectS
  end # inspect_mod

  def inspect_mod_tuplet()
    return '' unless respond_to?('tuplet?')
    return '' unless tuplet?
    return " - tuplet #{@ordinal_num_within_tuplet_set.inspect} of #{@tuplet_type.inspect}"
  end # inspect_mod_tuplet

  def ly_output_dyn_debug(previous_dyn_outputS)
    set_previous_dyns_from_dyn(previous_dyn_outputS, rest?)
    return '-\\' + @dynS
  end # ly_output_dyn_debug

end # module Debugable
