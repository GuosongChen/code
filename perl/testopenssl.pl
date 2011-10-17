#!/usr/bin/perl -w

use FileHandle;
use IPC::Open2;
use MIME::Base64;
use Getopt::Std;

sub encrypt {
    my $encryptkey;
    my $pid = open2(*RDR, *WTR, "openssl rsautl -encrypt -inkey $pubkey -pubin");
    print WTR $randomkey;
    close(WTR);
    read(RDR, $encryptkey, 1024);
    close(RDR);
    waitpid $pid, 0;
    
    my $base64key = encode_base64($encryptkey);
    open(FH, ">/tmp/tmpkey");
    print FH $base64key;
    close(FH);
    
    open(ENC, "| openssl enc -des-ede3-cbc -aes-256-cbc -e -in $pubkey -pass stdin|dd bs=64 of=$pubkey.enc");
    print ENC $randomkey;
    close(ENC);
}

sub decrypt {    
    my ($destdir, $srcfile, $Pkey, $pass, $dekey, $tmpkey) = (@_);
    my $base64de = decode_base64(`cat $tmpkey`);
    open(DE, ">$dekey");
    print DE $base64de;
    close(DE);
    
    my $key;
    my $pid2 = open2(*RDR2, *WTR2, "openssl rsautl -decrypt -inkey $Pkey -in $dekey -passin stdin");
    print WTR2 $pass;
    close(WTR2);
    read(RDR2, $key, 1024);
    close(RDR2);
    waitpid $pid2, 0;
    
    open(FILE, "|openssl enc -des-ede3-cbc -aes-256-cbc -d -in $srcfile -pass stdin|dd bs=64 of=$srcfile.file");
    print FILE $key;
    close(FILE);
}
    
#####################################################################################
## main
##
##
#####################################################################################

sub main{
my $randomkey = `openssl rand -hex 64`;
my $pubkey = "/tmp/public.pem";
my $Pkey = "/tmp/private.pem";
my $pass = "123456";
my $tmpkey = "/tmp/tmpkey";
my $dekey = "/tmp/dekey";
my $destdir = "/tmp/testdir";
my $srcfile = "$pubkey.enc";

decrypt($destdir, $srcfile, $Pkey, $pass, $dekey, $tmpkey);
}

main;
