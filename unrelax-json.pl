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
	->utf8
	->pretty
	->allow_nonref
	->relaxed
	->canonical;

my $data = do {
	local $/;
	$json->decode(<>)
};

print $json->encode($data);
