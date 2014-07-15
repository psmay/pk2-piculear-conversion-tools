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



sub humanize($) {
	my $value = shift;
	my $g = 0;
	while($value and abs($value) < 1) {
		++$g;
		$value *= 1000;
	}
	my $pfx = ('', qw/m u n/)[$g];
	$pfx = "*10^-" . (3*$g) unless defined $pfx;
	"$value $pfx";
}

my $all_data = do {
	local $/;
	$json->decode(<>);
};

print <<'EOF' ;

// A default implementation, maybe
#define discardBufferByte() getBufferByte()

EOF

my $indent = 1;
sub ind() {
	return "\t" x $indent;
}

for my $data (@{$all_data->{scripts}}) {
	my $name = $data->{name};
	my $comment = $data->{comment};

	my $safe_name = $name;
	for($safe_name) {
		s/__/__u/g;
		s/^(\d)/n__$1/g;
		s/\./__p/g;
		s/"/__q/g;
		s/'/__s/g;
		s/ /__z/g;
		s/-/__h/g;
		s/([^A-Za-z0-9_])/sprintf('__%02x', ord($1))/eg
	}
	my $name_comment = ($name eq $safe_name) ? "" : "// $name";

	my $safe_comment = $comment;
	for($safe_comment) {
		s/\x0D\x0A/\x0A/sg;
		$_ = "\x0A$_";
		s!\x0A!\x0A// !sg;
	}

	say "$safe_comment";
	say "void $safe_name() { $name_comment";
	say "	int loopai, loopbi;";

	my @sh = @{$data->{script_human}};

	for my $script_step (@sh) {
		my $op = $script_step->{op};
		next unless defined $op;

		my $position = $script_step->{position};
		my $labeled_by = $script_step->{labeled_by};
		my $jumps_to = $script_step->{jumps_to};

		if($labeled_by and @$labeled_by) {
			for my $by (@$labeled_by) {
				say "Lbl_${position}_from_$by:";
				for ( grep { $_->{position} == $by } @sh ) {
					my $op = $_->{op};
					my $adj = $_->{loop_iterations_adjustment} // 0;
					if($adj) {
						say ind . "// loop started early by goto-index";
					}
					$adj += 1;
					my $xadj = ($adj == 0) ? "" : " + $adj";
					if($op eq 'LOOP') {
						my $times = $_->{times} + $adj;
						say ind . "for(loopai = $times; loopai > 0; loopai--) {";
						++$indent;
					}
					elsif($op eq 'LOOPBUFFER') {
						say ind . "for(loopbi = getBufferWord()$xadj; loopbi > 0; loopbi--) {";
						++$indent;
					}
				}
			}
		}

		my %params = ();
		%params = %{$script_step->{params}} if defined $script_step->{params};
		my @param_values = ();
		for(sort keys %params) {
			push @param_values, $params{$_};
		}

		my $jlbl = defined($jumps_to) ? "Lbl_${jumps_to}_from_$position" : undef;
		my $jt = defined($jlbl) ? " to $jlbl" : "";

		if ($op eq 'GOTO_INDEX') {
			my $post_position = $position + 2;
			my $adjustment_required = 0;
			for (grep { $_->{position} == $jumps_to } @sh) {
				if($_->{op} =~ /LOOP/ and $_->{jumps_to} == $post_position) {
					# This goto jumps into a loop just before the end of the first iteration. Instead of actually doing
					# this, simply do one fewer iteration.
					$_->{loop_iterations_adjustment} = -1;
					$adjustment_required = 1;
				}
			}
			if($adjustment_required) {
				# Nothing - goto is replaced by a compensated loop
			} else {
				say ind . "goto $jlbl;";
			}
		} elsif ($op eq 'LOOPBUFFER') {
			#say ind . "LOOP_VIA(loopb, $position, getBufferWord(), $jlbl);";
			$indent--;
			say ind . "}";
		} elsif ($op eq 'LOOP') {
			#say ind . "LOOP_VIA(loopa, $position, $script_step->{times}, $jlbl);";
			$indent--;
			say ind . "}";
		} elsif ($op =~ /COREINST18/) {
			say ind . "coreInst18(" . join(', ', map { sprintf('0x%04x', $_) } @param_values ) . ");";
		} elsif ($op =~ /COREINST24/) {
			say ind . "coreInst24(" . join(', ', map { sprintf('0x%06x', $_) } @param_values ) . ");";
		} elsif ($op eq 'WRITE_BYTE_BUFFER') {
			say ind . "putLineByte(getBufferByte());";
		} elsif ($op eq 'READ_BYTE_BUFFER') {
			say ind . "putBufferByte(getLineByte());";
		} elsif ($op eq 'WRITE_BITS_LITERAL') {
			say ind . "putLineBits(" . sprintf('0x%x', $params{value}) . ", $params{bitCount});";
		} elsif ($op eq 'WRITE_BYTE_LITERAL') {
			say ind . "putLineByte(" . sprintf('0x%02x', $params{value}) . ");";
		} elsif ($op eq 'CONST_WRITE_DL') {
			say ind . "putInputBufferByte(" . sprintf('0x%02x', $params{value}) . ");";
		} elsif ($op =~ /DELAY/) {
			my $ns = $script_step->{delay_ns};
			my $human = humanize($ns / 1000000000) . "s";
			say ind . "delay_ns($ns); // $human";
		} elsif ($op eq 'POP_DOWNLOAD') {
			say ind . "discardBufferByte();";
		} elsif ($op eq 'SET_ICSP_PINS') {
			my $value = $params{pinStates};
			my $pgd_value = ($value & 0x08) ? "true" : "false";
			my $pgc_value = ($value & 0x04) ? "true" : "false";
			my $pgd_direction = ($value & 0x02) ? "DIRECTION_INPUT" : "DIRECTION_OUTPUT";
			my $pgc_direction = ($value & 0x01) ? "DIRECTION_INPUT" : "DIRECTION_OUTPUT";
			say ind . "setIcspPins($pgd_value, $pgc_value, $pgd_direction, $pgc_direction);";
		} else {
			say ind . "$op(" . join(', ', @param_values) . ")$jt;";
		}
	}

	say "}";
	say "";

}

#say $json->encode($all_data);
