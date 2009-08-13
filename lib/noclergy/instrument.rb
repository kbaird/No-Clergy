#!/usr/bin/env ruby
# instrument.rb
# $Id: instrument.rb,v 1.27 2006/07/15 22:04:23 kbaird Exp $

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

require 'noclergy/no_clergy_object'

=begin rdoc
Stores information on naming and transposition.
=end
class Instrument < NoClergyObject

  ARTS_IN_BOTH_LY_XML = %w{ accent staccato tenuto staccatissimo }

  CLEF = {
    'bass'  => 'bass',
    'bsn'   => 'bass',
    'eb'    => 'bass',
    'vc'    => 'bass',
  }
  CLEF.default = 'treble'

  # Stores human-readable names as Strings
  FULLNAME = {
    'as'    => 'Alto Sax',
    'bass'  => 'Bass',
    'bs'    => 'Bari Sax',
    'bsn'   => 'Bassoon',
    'cl'    => 'Clarinet',
    'eb'    => 'Electric Bass',
    'eh'    => 'English Horn',
    'fl'    => 'Flute',
    'gtr'   => 'Guitar',
    'ob'    => 'Oboe',
    'ss'    => 'Soprano Sax',
    'tpt'   => 'Trumpet',
    'ts'    => 'Tenor Sax',
    'va'    => 'Viola',
    'vc'    => 'Cello',
    'vn'    => 'Violin',
  }

  LY_ART_FROM_XML_ART = { 
    'strong-accent'   => 'marcato', 
    'detached-legato' => 'portato',
    'up-bow'          => 'upbow',          
    'down-bow'        => 'downbow',
  }

  # limits for comfortable playing, obviously variable
  #--
  # FIXME: Add more ranges
  #++
  RANGE = { 
    'as'    => [53, 81], 
    'bass'  => [28, 55],
    'bs'    => [41, 69], 
    'bsn'   => [34, 74], 
    'cl'    => [52, 89], 
    'eb'    => [28, 55],
    'eh'    => [52, 84],
    'gtr'   => [52, 88],
    'ob'    => [58, 89],
    'ss'    => [60, 88], 
    'tpt'   => [57, 80], 
    'ts'    => [48, 76],
    'vc'    => [36, 69],
    'vn'    => [55, 88],
	}
  RANGE.default=[60, 80]

  # Stores transposition values as Integers
  #--
  # FIXME: Add more transpositions
  #++
  TRANSPOSITION = {
    'as'    => -9,
    'bass'  => -12,
    'bs'    => -21,
    'cl'    => -2,
    'eb'    => -12,
    'eh'    => -7,
    'gtr'   => -12,
    'ss'    => -2,
    'tpt'   => -2,
    'ts'    => -14,
  }
  TRANSPOSITION.default=0

  XML_ART_FROM_LY_ART = LY_ART_FROM_XML_ART.invert() 
  
  attr_reader :abbr

# CLASS METHODS

  def Instrument.clef(inst_abbr)
    CLEF[inst_abbr]
  end # clef

# Get full instrument name as <b>String</b>, falling back to
# the abbreviation if the FULLNAME value is nil.
  def Instrument.fullname(inst_abbr)
    FULLNAME[inst_abbr] || inst_abbr
  end # fullname

# Returns <b>Array</b> of [lowest, highest] <b>Integers</b>.
  def Instrument.range(inst_abbr)
    RANGE[inst_abbr]
  end # range

  def Instrument.legal_abbrs()
    display_abbr = lambda { |abbr| "#{abbr}\t#{FULLNAME[abbr]}" }
    legal_list = ['Legal abbreviations to use for No Clergy:']
    legal_list += FULLNAME.keys.sort.map(&display_abbr)
    puts "\n" + legal_list.join("\n") + "\n\n"
  end # Instrument.show_legal_abbreviations

# Get transposition as <b>Integer</b>, Bb = -2, etc.
  def Instrument.transposition(inst_abbr)
    TRANSPOSITION[inst_abbr]
  end # transposition

# INSTANCE METHODS

=begin rdoc
Mandatory abbreviated name <b>String</b> argument and two optional 
arguments: fullname <b>String</b> and transposition <b>Integer</b>. 
Constructs default fullname and transposition from internal 
<b>Hash</b>es with nil arguments.
=end
  def initialize(abbr, fullname=nil, transposition=nil, clef=nil, range=nil)
    instsH = read_personal_instrument_definitions()
    @abbr = abbr
    if instsH
      if instsH[abbr]
        fullname      = instsH[abbr][0]
        transposition = instsH[abbr][1]
        clef          = instsH[abbr][2] || nil
        from_range    = instsH[abbr][3, 2]
        range         = from_range.map { |item| item || nil }
      end
    end
    @fullname      = fullname.ensure_nil_if_unusable()
    @transposition = transposition.ensure_nil_if_unusable()
    @clef          = clef.ensure_nil_if_unusable()
    @range         = range ? range.map(&:ensure_nil_if_unusable) : nil
  end # initialize

# Returns @clef if it exists, or calls Instrument#clef.
  def clef()
    @clef || Instrument.clef(@abbr)
  end # clef

=begin rdoc
Translate Lilypond[http://www/lilypond.org/] articulations 
into MusicXML[http://www.recordare.com.musicxml/] format, as 
needed.
=end
	def file_write_art(art)
		return '' unless (art.strip.size > 0)
		return %Q[<#{art} />]                      if ARTS_IN_BOTH_LY_XML.include?(art)
		return %Q(<#{XML_ART_FROM_LY_ART[art]} />) if XML_ART_FROM_LY_ART.keys.include?(art)
    fail "bad art = #{art}"
	end # file_write_art

# Returns @fullname if it exists, or calls Instrument#fullname.
  def fullname()
    @fullname || Instrument.fullname(@abbr)
  end # fullname

# Returns @range if it exists, or calls Instrument#range.
  def range()
    @range || Instrument.range(@abbr)
  end # range

=begin rdoc
Reads custom user definitions of instruments from 
'~/.noclergy/instruments.txt'.
=end
  def read_personal_instrument_definitions()
    filename = ENV['HOME'] + '/.noclergy/instruments.txt'
    if (File.exists?(filename) && File.file?(filename))
      outH = Hash.new()
      instsH = read_inst_hash(filename)
      instsH.keys.sort.each do |abbr|
        arr = instsH[abbr]
        fullname      = arr[0]
        transposition = arr[1]
        clef          = arr[2]||nil
        range[0]      = arr[3][0]||nil
        range[1]      = arr[3][1]||nil
        outH[abbr] = [fullname, transposition, clef, range[0], range[1]]
      end
      return outH
    end
    return nil
  end # read_personal_instrument_definitions

=begin rdoc
Translate MusicXML[http://www.recordare.com.musicxml/] articulations 
into Lilypond[http://www/lilypond.org/] format, as needed.
=end
def translate_art_from_XML(art)
    if LY_ART_FROM_XML_ART.has_key?(art)
      art = LY_ART_FROM_XML_ART[art]
    end
    return art
  end # translate_art_from_XML

=begin rdoc
Returns @transposition if it exists, or calls Instrument#transposition.
=end
  def transposition()
    @transposition || Instrument.transposition(@abbr)
  end # transposition

end # class Instrument
