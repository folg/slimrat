# slimrat - YouTube plugin
#
# Copyright (c) 2008 Přemek Vyhnal
# Copyright (c) 2009 Tim Besard
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
# Thanks to:
#    Bartłomiej Palmowski
#

#
# Configuration
#

# Package name
package Vimeo;

# Extend Plugin
@ISA = qw(Plugin);

# Packages
use WWW::Mechanize;

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
	$self->{MECH} = $_[3];
	bless($self);

	$self->{URL} =~ m#.*vimeo\.com/(\d+).*#;
	$self->{VIDEOID} = $1;
	$self->{URL} = "http://vimeo.com/moogaloop/load/clip:$1";
	
	$self->{PRIMARY} = $self->fetch();
	
	return $self;
}

# Plugin name
sub get_name {
	return "Vimeo";
}

# Filename
sub get_filename {
	my $self = shift;
	return $1."\.mp4" if ($self->{PRIMARY}->decoded_content =~ m/<caption>(.*?)<\/caption>/);
}

# Filesize
sub get_filesize {
	return 0;
}

# Check if the link is alive
sub check {
	my $self = shift;
	
	return -1 if ($self->{PRIMARY}->decoded_content =~ m#<error_id>video_doesnt_exist</error_id>#);
	return 1 if ($self->{PRIMARY}->decoded_content =~ m/<caption>/);
	return 0;
}

# Download data
sub get_data_loop  {
	# Input data
	my $self = shift;
	my $data_processor = shift;
	my $captcha_processor = shift;
	my $message_processor = shift;
	my $headers = shift;

	my ($sig, $exp) = $self->{PRIMARY}->decoded_content =~ m#<request_signature>(.+?)</request_signature>.*<request_signature_expires>(.+?)</request_signature_expires>#ms;

	if($sig and $exp){
		my $download = "http://vimeo.com/moogaloop/play/clip:".$self->{VIDEOID}."/$sig/$exp/?q=sd";
		return $self->{MECH}->request(HTTP::Request->new(GET => $download, $headers), $data_processor);
	}
	return;
}


# Amount of resources
Plugin::provide(-1);

# Register the plugin
Plugin::register(".*vimeo\.com/\\d+.*");

1;
