#!/usr/bin/env ruby
# no_clergy_cli
# $Id: no_clergy_cli.rb,v 1.11 2006/07/30 00:41:14 kbaird Exp $

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

['cleanup', 'mutator'].each do |filename|
  require 'noclergy/' + filename
end # each require file

=begin rdoc
Parses the command line options for No Clergy.
=end
class No_Clergy_CLI

  OPTIONS = {
    :v => ['-v', '--version'],
    :h => ['-h', '--help'],
    :s => ['-s', '--show'],
    :r => ['-r', '--reset'],
    :i => ['-i', '--inst', '--insts'],
  }

  VERSION = "No Clergy version 0.01 (Pre-Alpha)\n"

  #LAMBDAs
  RENDER_EACH_INST_ARG_PROC = lambda do |inst|
    make_ly = Outputer.new()
    make_ly.initialize_ensemble()
    make_ly.add_inst_to_config_file(inst)
    make_ly.set_inst(inst)
    make_ly.setup()
    make_ly.mv_old()
    make_ly.output()
    make_ly.render()
    cleanup = Cleanup.new(inst)
    cleanup.do_command('mv')
  end

  def parse_opts(argsA)
    if argsA.size < 1
      mutate()
    else
      return non_mutate_options(argsA) if understand_args?(argsA)
      Outputer.display_usage() # options are not understandable
    end
  end # parse_opts

  private

  def display_version()
    puts VERSION
  end

  def initialize_insts(argsA)
    if argsA.size < 1
      Outputer.display_missing_inst_error()
    else
      argsA.each(&RENDER_EACH_INST_ARG_PROC)
    end # if insts provided
  end # initialize_insts

  def mutate()
    if Outputer.ensemble_initialized?
      mutator = Mutator.new()
      mutator.mutate_config()
      mutator.read_scores()
      mutator.mutate_scores()
      mutator.write_all_scores_to_XML()
      mutator.ly_out_all()
      mutator.render_all_ly()
      mutator.instsA.each do |inst|
        cleanup = Cleanup.new(inst)
        cleanup.do_command('mv')
      end # each inst
    else
      Outputer.display_usage()
    end # if initialized
  end # mutate

  def non_mutate_options(argsA)
    opt = argsA.shift() # any remaining in argsA are insts 
    return display_version()        if OPTIONS[:v].include?(opt)
    return Outputer.display_usage() if OPTIONS[:h].include?(opt)
    return Instrument.legal_abbrs   if OPTIONS[:s].include?(opt)
    return initialize_insts(argsA)  if OPTIONS[:i].include?(opt)
    # otherwise, reset
    outputer = Outputer.new()
    outputer.reset()
  end # non_mutate_options

  def understand_args?(argsA)
    OPTIONS.keys.any? { |key| OPTIONS[key].include?(argsA[0]) }
  end # understand_args?

end # No_Clergy_CLI
