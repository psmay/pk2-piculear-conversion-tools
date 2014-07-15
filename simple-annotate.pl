#! /usr/bin/perl

use warnings;
use strict;
use 5.010;
use Carp;

use JSON;

my $json = JSON
	->new
	->utf8
	->pretty;

my $command_table = do {
	my $filename = shift @ARGV;
	local $/;
	open my $fh, '<', $filename or die "$!";
	my $j = $json->decode(<$fh>);
	close $fh;
	$j;
};

my %byte_to_command_info = ();
for my $item (@$command_table) {
	my $n = $item->{byte} + 0;
	$byte_to_command_info{$n} = $item;
}

my $all_data = do {
	local $/;
	$json->decode(<>);
};

for my $data (@{$all_data->{scripts}}) {
	my @assoc = @{$data->{script_assoc}};
	my @script_human = ();
	$data->{script_human} = \@script_human;

	my %jump_targets = ();

	for my $op (@assoc) {
		my $result = {};
		push @script_human, $result;
		my $opcode = $op->{opcode};
		my $position = $op->{position} ;
		$position += 0 if defined $position;
		$result->{position} = $position;

		if(defined $opcode) {
			$opcode += 0;
			my $info = $byte_to_command_info{$opcode};
			if(defined $info) {
				my $opname = $info->{name};
				$result->{op} = $opname;
				my @operands = @{$op->{operands}};
				my %params_raw = ();
				my %params = ();
				for my $param_info (@{$info->{params}}) {
					my $k = $param_info->{name};
					my $size = $param_info->{size};
					my @po = splice(@operands, 0, $size);
					my $d = 0;
					my $c = "0x";
					for(@po) {
						$d = ($d << 8) | $_;
						$c = $c . sprintf("%02x", $_);
					}
					my $desc = "$c ($d)";

					# Apply modifications from command table
					my $meaning_of_0 = $param_info->{meaningOf0};
					my $unit = $param_info->{unit};
					my $signed = $param_info->{signed};
					my $multiply_by = $param_info->{multiplyBy};

					if(defined $meaning_of_0 and $d == 0) {
						$d = $meaning_of_0;
					}
					if($signed) {
						my $base = 1 << (8 * $size);
						my $value = $d;
						$value &= ($base - 1);
						$value -= $base if $value & ($base >> 1);
						$d = $value;
					}
					if($param_info->{multiplyBy}) {
						$d *= $multiply_by;
					}

					if($k eq 'offset') {
						my $dest = $position + $d;
						$result->{jumps_to} = $dest;
						$jump_targets{$dest} //= [];
						push @{$jump_targets{$dest}}, $position;
					}

					if(defined $unit) {
						my $unit_key = "${k}_${unit}";
						$result->{$unit_key} = $d;
					}

					if($k eq 'value') {
						my $v = $d + 0;
						if($opname eq 'IF_EQ_GOTO') {
							$result->{if_equals} = $v;
						} elsif($opname eq 'IF_GT_GOTO') {
							$result->{if_greater_than} = $v;
						}
					}
					if($k eq 'repeatCount') {
						$result->{times} = $d + 0;
					}
					$params{$k} = $d + 0;
					$params_raw{$k} = $desc;
				}
				if(%params) {
					$result->{params} = \%params;
				}
				if(%params_raw) {
					$result->{params_raw} = \%params_raw;
				}
			}
		}
		else {
			$op->{error} = "Missing opcode";
		}
	}

	for my $result(@script_human) {
		my $k = $result->{position};
		my $j = $jump_targets{$k};
		if(defined $j) {
			$result->{labeled_by} = $j;
		}
	}

	for my $result(@script_human) {

	}
}

say $json->encode($all_data);
