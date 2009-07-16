# slimrat - configuration handling
#
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
#    Tim Besard <tim-dot-besard-at-gmail-dot-com>
#

#
# Configurationuration
#

# Package name
package Configuration;

# Packages
use Class::Struct;

# Write nicely
use strict;
use warnings;

# Custom packages
# NOTE: this module cannot include any custom package (it be Log.pm, Toolbox.pm, ...) as it is
#   used by almost any package and would cause circular dependancies. Also, including Log.pm
#   wouldn't help much as the verbosity etc. hasn't been initialised yet when the configuration
#   file is being parsed (debug() statements wouldn't matter). Instead, Perls internal
#   output routines are used (warn & die).
#   If there is a sensible way to include Log.pm, please change! It'd still be somewhat useful
#   to use functions like warning() and fatal() instead of warn and die.

# A configuration item
struct(Item =>	{
		default		=>	'$',
		mutable		=>	'$',
		value		=>	'$',
});


#
# Internal routines
#

# Create a new item
sub init($$) {
	my ($self, $key) = @_;
	
	if ($self->contains($key)) {
		warn("attempt to overwrite existing key through initialisation");
		return 0;
	}
	
	my $item = new Item;
	$item->mutable(1);
	
	# Add at right spot (self or parent)
	if ($self->{_parent}) {
		$self->{_parent}->init($self->{_section} . ":" . $key);
		$self->{_items}->{$key} = $self->{_parent}->{_items}->{$self->{_section} . ":" . $key};
	} else {
		$self->{_items}->{$key} = $item;
	}
	
	return 1;
}


#
# Routines
#

# Constructor
sub new {
	my $self = {
		_items		=>	{},	# Anonymous hash
		_parent		=>	undef,
		_section	=>	undef,
	};
	bless $self, 'Configuration';
	return $self;
}

# Check if the configuration contains a specific key
sub contains($$) {
	my ($self, $key) = @_;
	if (exists $self->{_items}->{$key}) {
		return 1;
	} else {
		return 0;
	}
}

# Add a default value
sub set_default($$$) {
	my ($self, $key, $value) = @_;
	
	# Check if key already exists
	unless ($self->contains($key)) {
		$self->init($key);
	}
	
	# Update the default value
	$self->{_items}->{$key}->default($value);
}

# Get a value
sub get($$) {
	my ($self, $key) = @_;
	
	# Check if it contains the key (not present returns false)
	return 0 unless ($self->contains($key));
	
	# Return value or default
	if (defined $self->{_items}->{$key}->value) {
		return $self->{_items}->{$key}->value;
	} else {
		return $self->{_items}->{$key}->default;
	}
}

# Get the default value
sub get_default($$) {
	my ($self, $key) = @_;
	
	# Check if it contains the key (not present returns false)
	return 0 unless ($self->contains($key));
	
	# Return default
	return $self->{_items}->{$key}->default;
}

# Set a value
sub set($$$) {
	my ($self, $key, $value) = @_;
	
	# Check if contains
	if (!$self->contains($key)) {
		$self->init($key);
	}
	
	# Check if mutable
	if (! $self->{_items}->{$key}->mutable) {
		warn("attempt to modify protected key '$key'");
		return 0;
	}
	
	# Modify value
	$self->{_items}->{$key}->value($value);
	return 1;
}

# Protect an item
sub protect($$) {
	my ($self, $key) = @_;
	if ($self->contains($key)) {
		$self->{_items}->{$key}->mutable(0);
		return 1;
	}
	return 0;
}

# Read a file
sub file_read($$) {
	my ($self, $file) = @_;
	my $prepend = "";	# Used for section seperation
	open(READ, $file) || die("could not open configuration file '$file'");
	while (<READ>) {
		chomp;
		
		# Skip comments, and leading & trailing spaces
		s/#.*//;
		s/^\s+//;
		s/\s+$//;
		next unless length;
		
		# Get the key/value pair
		if (my($key, $separator, $value) = /^(.+?)\s*(=+)\s*(.+?)$/) {		# The extra "?" makes perl prefer a shorter match (to avoid "\w " keys)

			# Replace '~' with HOME of user who started slimrat
			$value =~ s#^~/#$ENV{'HOME'}/#;
			
			# Substitute negatively connoted values
			$value =~ s/^(off|none|disabled|false)$/0/i;
			
			if ($key =~ m/(:)/) {
				warn("ignored configuration entry due to protected string in key ('$1')");
			} else {
				$self->set($prepend.$key, $value);
				$self->protect($prepend.$key) if (length($separator) >= 2);
			}
		}
		
		# Get section identifier
		elsif (/^\[(.+)\]$/) {
			my $section = lc($1);
			if ($section =~ m/^\w+$/) {
				$prepend = "$section:";
			} else {
				warn("ignored non-alphanumeric subsection entry");
			}
		}
		
		# Invalid entry
		else {
			warn("ignored invalid configuration entry '$_'");
		}
	}
	close(READ);
}

# Return a section
sub section($$) {
	my ($self, $section) = @_;
	$section = lc($section);
	
	# Extract subsection
	my $config_section = new Configuration;
	foreach my $key (keys %{$self->{_items}}) {
		if ($key =~ m/^$section:(.+)$/) {
			$config_section->{_items}->{substr($key, length($section)+1)} = $self->{_items}->{$key};
		}
	}
	
	# Give the section parent access
	$config_section->{_parent} = $self;
	$config_section->{_section} = $section;
	
	return $config_section;
}

# Merge two configuration objects
sub merge($$) {
	my ($self, $complement) = @_;
	
	# Process all keys and update the complement
	foreach my $key (keys %{$self->{_items}}) {
		warn("merge call only copies defaults") if (defined $self->{_items}->{$key}->value);
		$complement->set_default($key, $self->get_default($key));
	}
	
	# Update self
	$self->{_items} = $complement->{_items};
}

# Return
1;

__END__

=head1 NAME 

Configuration

=head1 SYNOPSIS

  use Configuration;

  # Construct the configuration handles
  my $config = Configuration::new();

=head1 DESCRIPTION

This package provides a configuration handler, which should ease the use
of several inputs for configuration values, including their default values.

=head1 METHODS

=head2 Configuration::new()

This constructs a new configuration object, with initially no contents at all.

=head2 $config->set_default($key, $value)

Adds a new item into the configuration, with $value as default value. This happens
always, even when the key has been marked as protected. Any previously entered
values do not get overwritten, which makes it possible to enter or re-enter a
default value after actual values has been entered.

=head2 $config->set($key, $value)

Set a key to a given value. This is separated from the default value, which can still
be accessed with the default() call.

=head2 $config->get($key)

Return the value for a specific key. Returns 0 if not found, and if found but no values
are found it returns the default value (which is "undef" if not specified).

=head2 $config->contains($key)

Check whether a specific key has been entered in the configuration (albeit by default
or customized value).

=head2 $config->protect($key)

Protect the values of a key from further modification. The default value always remains
mutable.

=head2 $config->file_read($file)

Read configuration data from a given file. The file is interpreted as a set of key/value pairs.
Pairs separated by a single '=' indicate mutable entries, while a double '==' means the entry
shall be protected and thus immutable.

=head2 $config->section($section)

Returns a new Configuration object, only containing key/value pairs listed in the given section.
This can be used to seperate the configuration of several parts, in the case of slimrat e.g.
preventing a malicious plugin to access data (e.g. credentials) of other plugins. Keys are
internally identified by the key and a section preposition, which makes it possible to use
identical keys in different sections. The internally used seperation of preposition and key
(a ":") is protected in order to avoid a security leak.
Be warned though that the section Configuration object only contains references to the actual
entries, so modifying the section object _will_ modify the main configuration object too (unless
protected offcourse).
NOTE: section entries are case-insensitive.

=head2 $config->merge($complement)

Merges two Configuration objects. This is especially usefull in combination with the section()
routine: a package/objects creates a Configuration object with some default entries at
BEGIN/construction, but gets passed another Configuration object with some user-defined
entries. The merge function will read all values in the $self object (the one with the
default values), and update those values in the passed $complement object. This in order
to update the main Configuration object, as the complement only contains references.
  use Configuration;
  
  # A package creates an initial Configuration object (e.g. at construction)
  my $config_package = new Configuration;
  $config_package->set_default("foo", "bar");
  
  # The main application reads the user defined values (from file, or manually, ...)
  my $config_main = new Configuration;
  $config_main->file_read("/etc/configuration");
  
  # The package receives the configuration entries it is interested in, and merges them
  # with the existing default values
  $config_package->merge($config_main->section("package"));
  
  # The package configuration object shall now contain all user specified entries, with
  # preserved default values. It'll also contain default values for objects not specified
  # by the user.
=cut=
