# slimrat - direct downloading plugin
#
# Copyright (c) 2008 Přemek Vyhnal
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
#    Přemek Vyhnal <premysl.vyhnal gmail com>
#    Tim Besard <tim-dot-besard-at-gmail-dot-com>
#

#
# Configuration
#

# Package name
package Direct;

# Packages
use LWP::UserAgent;

# Custom packages
use Log;
use Toolbox;
use Configuration;

# Write nicely
use strict;
use warnings;


#
# Routines
#

# Constructor
sub new {
	my $self  = {};
	$self->{CONF} = $_[1];
	$self->{URL} = $_[2];
	
	
	$self->{CONF}->set_default("enabled", 0);
	if ($self->{CONF}->get("enabled")) {
		warning("no appropriate plugin found, downloading using 'Direct' plugin");
	} else {
		return error("no appropriate plugin found");
	}
	
	$self->{PRIMARY} = $self->{MECH}->get($self->{URL});
	return error("plugin error (primary page error, ", $self->{PRIMARY}->status_line, ")") unless ($self->{PRIMARY}->is_success);
	dump_add($self->{MECH}->content());

	bless($self);
	return $self;
}

# Plugin name
sub get_name {
	return "Direct";
}

# Get filename
sub get_filename {
	my $self = shift;
	
	# Get filename through HTTP request
	my $filename = ($self->{MECH}->head($self->{URL})->filename);
	
	# If unsuccessfull, deduce from URL
	unless ($filename) {
		if ($self->{URL} =~ m/http.+\/([^\/]+)$/) {
			$filename = $1;
		} else {
			return error("could not deduce filename");
		}
	}
	return $filename;
}

# Filesize
sub get_filesize {
	my $self = shift;
	
	return 0;
}

# Check if the link is alive
sub check {
	my $self = shift;
	
	return 1 if ($self->{MECH}->head($self->{URL})->is_success);
	return -1;
}

# Download data
sub get_data {
	my $self = shift;
	my $data_processor = shift;
	
	$self->{MECH}->request(HTTP::Request->new(GET => $self->{URL}), $data_processor);
}


1;

