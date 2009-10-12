#!/usr/bin/env ruby
# mutator.rb
# $Id: mutator.rb,v 1.8 2006/07/14 13:21:21 kbaird Exp $

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

require 'noclergy/outputer'

=begin rdoc
Mutates notation for {No Clergy}[http://noclergy.rubyforge.org/].
=end

class Mutator < Outputer

  #LAMBDAs
  

  attr_reader :instsA

  def initialize()
    super()
    @ly_filename = ''
    @scoresA = []
    read_insts() # From Config
    setup_config()
    setup_header()
  end # initialize

=begin rdoc
Writes Lilypond[http://lilypond.org/] markup for each <b>Score</b>.
=end
  def ly_out_all()
    @scoresA.each do |score| 
      inst = score.get_inst()
      mv_old(inst.abbr)
      @ly_filename = NOTATION_VAR_DIR + inst.abbr + '.ly'
      File.open(@ly_filename, 'w') do |ly_file|
        ly_file.puts(@header.ly_output(inst) + output_score(score))
      end
    end # each score
  end # ly_out_all

=begin rdoc
Updates the config file for {No Clergy}[http://noclergy.rubyforge.org/].
=end
  def mutate_config()
    config = Config.new()
    config.read_insts()
    config.read_file()
    config.read_feedback()
    ['art', 'dyn', 'rest'].each do |var| 
      config.alter(var)
    end # each var type
    config.write_file()
  end # mutate_config

=begin rdoc
Reads user feedback, creates a <b>Score</b> via Markov Chains, and 
then applies the user feedback.
=end
  def mutate_scores()
  mutate_score_proc = lambda do |score| 
    feedbackH = score.make_feedbackH()
    score.debug_measures()
    score.mutate_by_markov(feedbackH)
    score.debug_measures()
    score.mutate_by_feedback(feedbackH)
    score.debug_measures()
    score
  end
    @scoresA.map!(&mutate_score_proc)
  end # mutate_scores

=begin rdoc
Reads each <b>Score</b> from XML.
=end
  def read_scores()
  read_score_by_inst_proc = lambda do |inst|
    score = Score.new(inst)
    score.add_variables(@config)
    score.set_system_breaks()
    score.file_read()
    score.collect_notes()
    score.debug_measures()
    score.debug_notes_XML()
    score
  end
  @scoresA += @instsA.map(&read_score_by_inst_proc)
  end # read_scores

=begin rdoc
Render Lilypond[http://lilypond.org/] files, each instrument in turn.
=end
  def render_all_ly()
    @instsA.each { |inst| render_ly(inst) }
  end # render_all_ly

  def write_all_scores_to_XML()
    @scoresA.each(&:file_write)
  end # write_all_scores_to_XML

end # Mutator
