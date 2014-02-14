#! /usr/bin/perl

# Accepts JSON with trailing list/object commas, then reprints it in standard
# JSON with indentation and sorted keys.

use warnings;
use strict;
use 5.010;
use Carp;

use JSON;

my $json = JSON
	->new
	->utf8;

sub once {
	my $filename = shift;

	
	print "$filename: ";
	my $fh;
	if(open($fh, '<', $filename)) {
		eval {
			my $data = do {
				local $/;
				$json->decode(<$fh>)
			};
			close $fh;
			say "OK";
		};

		if("$@" ne '') {
			my $e = $@;
			chomp $e;
			say "FAIL: $e";
		}
	}
	else {
		say "ERROR: $!";
	}
}

once($_) for @ARGV;
