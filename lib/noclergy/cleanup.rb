#!/usr/bin/env ruby
# cleanup.rb
# $Id: cleanup.rb,v 1.8 2006/05/29 23:59:44 kbaird Exp $

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

=begin rdoc
Extracts step, alter and octave tags from XML and generates internal pitch.
=end

require 'noclergy/config'

class Cleanup < Config

  # Directory listings not to deal with
  IGNORE_LISTINGS = ['.', '..', 'DTDs']

  def initialize(instS)
    @instS = instS
    @listdirnameS = BASE_XML_DIR + instS + '/'
    @bakdirnameS  = BASE_XML_DIR + "bak/#{instS}/"
    system("mkdir -p #{@bakdirnameS}") unless File.directory?(@bakdirnameS)
    @dirA = Dir.new(@listdirnameS).to_a.sort! - IGNORE_LISTINGS
  end # initialize

  def do_command(argS)
    @argS = argS
    case argS
      when 'ls': do_ls
      when 'mv': do_mv
    end # case argS
  end # do_command

private
=begin rdoc
Applies bzip2 compression to XML files.
=end
  def compress_XML_backups()
    system("bzip2 #{@bakdirnameS}*.xml")
  end # compress_XML_backups

  def do_ls()
    puts @dirA
  end # do_ls

  def do_mv()
    if @dirA.size > 0
      last_itemS = @dirA.pop # keep one in the directory
      @dirA.each { |i| mv_to_bak(i) if i[-4, 4] == '.xml' }
    end # if any files
  end # do_ls

  def mv_to_bak(itemS)
    system("mv #{@listdirnameS}#{itemS} #{@bakdirnameS}")
    compress_XML_backups()
  end # mv_to_bak

end # Cleanup
