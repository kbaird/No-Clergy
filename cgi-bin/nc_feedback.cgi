#!/usr/bin/env ruby
# feedback.cgi

# put me in /usr/lib/cgi-bin/ on a Debian system
# possibly elsewhere for other OSes
# and give me permissions 755

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

require 'cgi'

host = `hostname`.chomp()
baseURL = "http://#{host}/noclergy/"
WEB_DIR = '/var/lib/noclergy/web/'
FEEDBACK_FILE = WEB_DIR + 'feedback/feedback.html'

form = CGI.new()
formS = "<pre>\n"
form.params.each do |field, value|
	formS += field.to_s + ' = ' + value.to_s + "\n"
end # each param
formS += "end 1 item\n</pre>\n"

new_feedbackFileS = ''
File.open(FEEDBACK_FILE, 'r').readlines.each do |line|
	new_feedbackFileS += line
	new_feedbackFileS += formS if line.include?('<!--begin-->')
end # feedbackfile read

File.open(FEEDBACK_FILE, 'w') do |feedbackfile|
	feedbackfile.puts(new_feedbackFileS)
end # feedbackfile write

# replace this with plain old puts statements, due to ruby 1.8 bug
cgi = CGI.new('html4')
metaS = '<meta http-equiv="refresh" content="10; url=' + baseURL + '" />'
cgi.out do
        cgi.html do
                cgi.head { "\n" + metaS + "\n" + cgi.title{'feedback results'} + "\n" } +
                cgi.body do "\n" +
                        cgi.h1 { 'Thank you for your feedback' } +
                        cgi.p { 'The form will reload automatically.' }
                end # cgi.body
        end # cgi.html
end # cgi.out
