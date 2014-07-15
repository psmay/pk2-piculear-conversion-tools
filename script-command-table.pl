#! /usr/bin/perl

use warnings;
use strict;
use 5.010;
use Carp;

use JSON;

my $json = JSON->new->utf8->pretty;

my @codes;

for(<DATA>) {
	chomp;
	my @values = split(/\t/, $_);
	my $opname = shift @values;
	next unless defined $opname;

	my $byte = shift @values;
	$byte =~ s/0[Xx](.*)/hex($1)/esg;
	$byte += 0;

	my @params;
	for(@values) {
		/^(\w+)(.*)$/;
		my $name = $1;
		my $rest = $2;
		my $param = { name => $name, size => 1 };

		for($rest) {
			if(s/[%]//) {
				$param->{meaningOf0} = 256;
			}
			if(s/:(\d+)//) {
				$param->{size} = 0 + $1;
			}
			if(s/[+]//) {
				$param->{signed} = JSON::true;
			}
			if(s/[*](-?\d+(?:\.\d+)?)(.*)//) {
				$param->{multiplyBy} = $1 + 0;
				$param->{unit} = $2 if $2 ne '';
			}

			if(!/^$/) {
				die "Unused suffix $_ for $name under opname";
			}

			push @params, $param;
		}
	}

	my %op = (
		name => $opname,
		byte => $byte,
		params => \@params,
	);
	push @codes, \%op;
}

say $json->encode(\@codes);

__DATA__
VDD_ON	0xFF				
VDD_OFF	0xFE				
VDD_GND_ON	0xFD				
VDD_GND_OFF	0xFC				
VPP_ON	0xFB				
VPP_OFF	0xFA				
VPP_PWM_ON	0xF9				
VPP_PWM_OFF	0xF8				
MCLR_GND_ON	0xF7				
MCLR_GND_OFF	0xF6				
BUSY_LED_ON	0xF5				
BUSY_LED_OFF	0xF4				
SET_ICSP_PINS	0xF3	pinStates			
WRITE_BYTE_LITERAL	0xF2	value			
WRITE_BYTE_BUFFER	0xF1				
READ_BYTE_BUFFER	0xF0				
READ_BYTE	0xEF				
WRITE_BITS_LITERAL	0xEE	bitCount	value		
WRITE_BITS_BUFFER	0xED	bitCount			
READ_BITS_BUFFER	0xEC	bitCount			
READ_BITS	0xEB	bitCount			
SET_ICSP_SPEED	0xEA	clockPeriod*1000ns			
LOOP	0xE9	offset*-1	repeatCount%		
DELAY_LONG	0xE8	delay*5460000ns			
DELAY_SHORT	0xE7	delay*21300ns			
IF_EQ_GOTO	0xE6	value	offset+		
IF_GT_GOTO	0xE5	value	offset+		
GOTO_INDEX	0xE4	offset+			
EXIT_SCRIPT	0xE3				
PEEK_SFR	0xE2	sfrAddress			
POKE_SFR	0xE1	sfrAddress	value		
ICDSLAVE_RX	0xE0				
ICDSLAVE_TX_LIT	0xDF	value			
ICDSLAVE_TX_BUF	0xDE				
LOOPBUFFER	0xDD	offset*-1			
ICSP_STATES_BUFFER	0xDC				
POP_DOWNLOAD	0xDB				
COREINST18	0xDA	inst:2
COREINST24	0xD9	inst:3
NOP24	0xD8				
VISI24	0xD7				
RD2_BYTE_BUFFER	0xD6				
RD2_BITS_BUFFER	0xD5	bitCount			
WRITE_BUFWORD_W	0xD4	wNumber			
WRITE_BUFBYTE_W	0xD3	wNumber			
CONST_WRITE_DL	0xD2	value			
WRITE_BITS_LIT_HLD	0xD1	bitCount	value		
WRITE_BITS_BUF_HLD	0xD0	bitCount			
SET_AUX	0xCF	pinStates			
AUX_STATE_BUFFER	0xCE				
I2C_START	0xCD				
I2C_STOP	0xCC				
I2C_WR_BYTE_LIT	0xCB	value			
I2C_WR_BYTE_BUF	0xCA				
I2C_RD_BYTE_ACK	0xC9				
I2C_RD_BYTE_NACK	0xC8				
SPI_WR_BYTE_LIT	0xC7	value			
SPI_WR_BYTE_BUF	0xC6				
SPI_RD_BYTE_BUF	0xC5				
SPI_RDWR_BYTE_LIT	0xC4				
SPI_RDWR_BYTE_BUF	0xC3				
ICDSLAVE_RX_BL	0xC2				
ICDSLAVE_TX_LIT_BL	0xC1	value			
ICDSLAVE_TX_BUF_BL	0xC0				
MEASURE_PULSE	0xBF				
UNIO_TX	0xBE	deviceAddress	byteCount		
UNIO_TX_RX	0xBD	deviceAddress	txByteCount	rxByteCount	
JT2_SETMODE	0xBC	bitCount	tmsValue		
JT2_SENDCMD	0xBB	command			
JT2_XFERDATA8_LIT	0xBA	value			
JT2_XFERDATA32_LIT	0xB9	value:4
JT2_XFRFASTDAT_LIT	0xB8	value:4
JT2_XFRFASTDAT_BUF	0xB7				
JT2_XFERINST_BUF	0xB6				
JT2_GET_PE_RESP	0xB5				
JT2_WAIT_PE_RESP	0xB4				
JT2_PE_PROG_RESP	0xB3				
