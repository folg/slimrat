#!/usr/bin/env perl
#
# slimrat - HotFile plugin
#
# Copyright (c) 2009 Yunnan
#
# This file is part of slimrat, an open-source Perl scripted
# command line and GUI utility for downloading files from
# several download providers.
# 
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without
# restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following
# conditions:
# 
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
# HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
# FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.
#
# Authors:
#    Yunnan <www.yunnan.tk>
#

package HotFile;
use Term::ANSIColor qw(:constants);
$Term::ANSIColor::AUTORESET = 1;
use Toolbox;
use WWW::Mechanize;
my $mech = WWW::Mechanize->new('agent' => $useragent );

# return - as usual
#   1: ok
#  -1: dead
#   0: don't know

sub check {
	$mech->get(shift);
	return 1  if($mech->content() =~ m/Your download will begin in/);
	# TODO: detect 0-size reply HotFile returns upon dead links (and return 0 in other cases)
	return -1;
}

sub download {
	my $file = shift;
	$res = $mech->get($file);
	if (!$res->is_success) { print RED "Page #1 error: ".$res->status_line."\n\n"; return 0;}
	else {
		$_ = $mech->content();
		my($wait1) = m#timerend\=d\.getTime\(\)\+([0-9]+);
  document\.getElementById\(\'dwltmr\'\)#;
		$wait1 = $wait1/1000;
		my($wait2) = m#timerend\=d\.getTime\(\)\+([0-9]+);
  document\.getElementById\(\'dwltxt\'\)#;
		$wait2 = $wait2/1000;
		my($wait) = $wait1+$wait2;
		print CYAN &ptime."Waiting for ".$wait1." + ".$wait2." = ".$wait." sec.\n";
                main::dwait($wait);
		$mech->form_number(2); # free;
		$mech->submit_form();
		$download = $mech->find_link( text => 'Click here to download' )->url();
		return "'".$download."'";
	}
}

Plugin::register(__PACKAGE__,"^[^/]+//(?:www.)?hotfile.com");

1;

