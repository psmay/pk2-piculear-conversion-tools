#! /usr/bin/perl

# Converts a dump with a raw script into one that associates operators with operands.

use warnings;
use strict;
use 5.010;
use Carp;

use JSON;

my $json = JSON
	->new
	->utf8
	->pretty;
	

my $data = do {
	local $/;
	$json->decode(<>)
};


my @script_meaning = ();
my %out = (
	name => $data->{name},
	raw_script => $data->{script},
	script => \@script_meaning,
);


# Parse the bytes into operations and operands.

my @script_bytes = @{$data->{script}};
my $pending_op = undef;
my $position = -1;

while(@script_bytes) {
	++$position;
	my $value_byte = shift(@script_bytes);
	my $type_byte = shift(@script_bytes);

	if($type_byte == 0xAA) {
		# Value is opcode
		$pending_op = {
			position => $position,
			opcode => $value_byte,
			operands => [],
		};
		push @script_meaning, $pending_op;
	}
	elsif($type_byte == 0xBB or $type_byte == 0x00) {
		# Value is operand
		if(not defined $pending_op) {
			$pending_op = {
				position => $position,
				operands => [],
				error => "Operands supplied before command",
			};
			push @script_meaning, $pending_op;
		}
		push @{$pending_op->{operands}}, $value_byte;
	}
	else {
		$pending_op = {
			position => $position,
			operands => [],
			error => "Unrecognized tag value " . sprintf('%02x', $type_byte),
			value => $value_byte,
			tag => $type_byte,
		};
		push @script_meaning, $pending_op;
	}
}

say $json->encode(\%out) . ",";
say "";
