#!/usr/bin/env ruby
# outputer.rb
# $Id: outputer.rb,v 1.25 2006/05/05 21:51:43 kbaird Exp $

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

['header', 'score'].each do |filename|
  require 'noclergy/' + filename
end

=begin rdoc
Creates Lilypond[http://lilypond.org/] output for one instrument's 
<b>Score</b> in {No Clergy}[http://noclergy.rubyforge.org/noclergy/]
=end

class Outputer < Config

  BASE_VAR_DIR      = '/var/lib/noclergy/'
  INIT_BASENAME     = 'has_been_initialized'
  LY_OPTIONS        = '--png'
  NOTATION_VAR_DIR  = BASE_VAR_DIR + 'ly/'
  NOTATION_PDF_DIR  = BASE_VAR_DIR + 'pdf/'
  NOTATION_PNG_DIR  = BASE_VAR_DIR + 'png/'

=begin rdoc
what types of non-power of 2 tuplets are allowed?
repetitions give greater likelihood to repeated options, i.e.
[3, 3, 3, 5, 5] means 60% of all tuplets will be triplets of
some sort, and 40% of all tuplets will be fives of some sort
(subject to other limitations specific to the placement of
the tuplet set in the score)
=end
  TUPLET_STARTER_A = [3, 3, 3, 5, 5]

  USAGE = <<END_OF_USAGE

Usage: noclergy [OPTION]

Generate music notation to be transformed via audience feedback.

Optional arguments:
  -h, --help              display this message
  
  -i, --inst(s) [INSTS]   setup initial pages of notation for each 
                          instrument whose abbreviated name appears in [INSTS]
  
  -r, --reset             restore configuration options to blank slate
                          (I.e., remove instrument setups)
                          
  -s, --show              shows a list of legal instrument abbreviations to use

When called with no arguments, it transforms the music based on feedback 
provided by the audience, assuming that one or more instruments have been 
previously set up. Otherwise, it displays this help message.

Further information is available at http://noclergy.rubyforge.org/

Report bugs to <kbaird@rubyforge.org>

END_OF_USAGE

# CLASS METHODS

  def Outputer.display_usage()
    puts USAGE
  end # display_usage

# See also initialize_ensemble
  def Outputer.ensemble_initialized?()
    File.exists?(BASE_VAR_DIR + INIT_BASENAME)
  end # ensemble_initialized

# INSTANCE METHODS

	def initialize()
    super()
		define_tuplet_time()
		# x/4 meters are twice as likely, due to repetition above
		@topA = [3, 4, 4, 5, 6, 6, 7, 8, 8, 9, 10, 10]
	end # initialize

  def ensemble_initialized?()
    Outputer.ensemble_initialized?()
  end # ensemble_initialized

  def flush_config_file()
    config_file = CONFIG_WRITE_DIR + CONFIG_BASENAME
    if (File.exists?(config_file) && File.file?(config_file))
      system("rm #{config_file}")
    end
  end

  def flush_feedback()
    File.open(FEEDBACK_FILE_IN_PROCESS, 'w') do |feedback_file|
      feedback_file.puts(FEEDBACK_FILE_INITIAL_CONTENTS)
    end
  end # flush_feedback

  def flush_image_output()
    system("rm #{NOTATION_PNG_DIR}*.png")
  end # flush_image_output

  def flush_xml()
    system("rm #{BASE_XML_DIR}*.xml")
  end # flush_xml

# See also Outputer.ensemble_initialized?
  def initialize_ensemble(create=true)
    filename = BASE_VAR_DIR + INIT_BASENAME
    if (create)
      system("touch #{filename}")
    elsif ensemble_initialized?()
      system("rm #{filename}")
    end
  end # initialize_ensemble

=begin rdoc
Move/copy existing output files to 'old' versions. Takes an optional 
instrument abbreviation <b>String</b>; defaults to Outputer::inst.abbr().
=end
  def mv_old(inst=@inst.abbr())
    system("mv #{NOTATION_VAR_DIR}#{inst}.ly #{NOTATION_VAR_DIR}#{inst}-old.ly")
    system("cp #{NOTATION_PNG_DIR}#{inst}.png #{NOTATION_PNG_DIR}#{inst}-old.png")
   end # mv_old 

# For now, only outputs in Lilypond[http://lilypond.org/] format.
  def output()
    output_ly()
  end # output

  def render(format='ly')
    case format
      when 'ly': render_ly()
    end
  end # 

  def reset()
    flush_image_output()
    flush_feedback()
    flush_xml()
    initialize_ensemble(false)
    flush_config_file()
    setup_config_files()
  end # reset

	def set_inst(inst_abbr)
		@inst = Instrument.new(inst_abbr)
	end # set_inst

	def setup()
    read_insts() # from Config
		setup_config()
		setup_header()
		setup_score()
		write_score_to_XML()
	end # setup

private

=begin rdoc
tuplets start from a base 1/4 note value (ticks * 4), 
and divide by their tuplet_type to get their ticks value
=end
	def define_tuplet_time()
		TUPLET_STARTER_A.each do |tuplet_modI|
			@master_tupletA.push(tuplet_modI)
			@@ticks_per_I *= tuplet_modI
		end # each tuplet_modI
    @@ticks_per_I.freeze()
	end # define_tuplet_time

# Returns Lilypond[http://lilypond.org/] output with <b>Header</b>.
	def output_ly()
		debug_inst()
    outfilename = NOTATION_VAR_DIR + @inst.abbr + '.ly'
    File.open(outfilename, 'w') do |outfile|
      outfile.puts(@header.ly_output(@inst) + output_ly_score(@score))
    end # outfile
	end # output

# Returns Lilypond[http://lilypond.org/] output without <b>Header</b>.
	def output_ly_score(score)
    score.debug_measures()
    score.print_open() + score.ly_output() + score.print_close()
	end # output_ly_score

# For now, only option is Lilypond[http://lilypond.org/].
  def output_score(score)
    output_ly_score(score)
  end # output_score

# Render a Lilypond[http://lilypond.org/] file to PNG.
  def render_ly(inst = @inst.abbr)
    fail 'no inst' unless inst
    ly_input_file   = NOTATION_VAR_DIR + inst + '.ly'
    system("lilypond #{LY_OPTIONS} -o #{NOTATION_PNG_DIR} #{ly_input_file}")
  end # render_ly

	def setup_config()
		@config = Config.new()
		@config.read_file()
		@config.set_timing(@@ticks_per_I, @master_tupletA, @topA)
	end # setup_config

	def setup_header()
		@header = Header.new(@config)
	end # setup_header

	def setup_score()
		@score = Score.new(@inst.abbr())
    @score.create_web_dir()
    @score.add_variables(@config)
		@score.debug_varsHmm()
    @score.set_tempo(MIN_TEMPO, MAX_TEMPO)
		@score.construct(@config)
    @score.debug_measures()
	end # setup_score

	def write_score_to_XML()
		@score.file_write()
	end # write_score_to_XML

end # Outputer
