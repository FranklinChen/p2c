#!/bin/perl --     # -*-Perl-*-

# Author:  Dave Gillespie, daveg@synaptics.com.

# This is a Perl script that runs p2c and cc together to form
# an ad-hoc Pascal compiler.

# Usage:  p2cc <options-and-filenames>

# All options are passed through to the cc command except:
#   -p2c        runs p2c to get .c files, but does not run cc
#   -p2c<text>  passes <text> as an option to p2c, e.g., -p2c-Lturbo
#   -O          passes -O to cc and disables -check on p2c
#   -I<dir>     passes -I<dir> to both cc and p2c

# All filenames are passed through to the cc command except
# those ending in ".p" or ".pas", which are translated by p2c
# and then compiled.


# To be filled in by the Makefile:
$homedir = "--HOMEDIR--";
$incdir = "--INCDIR--";
$libdir = "--LIBDIR--";

$pascalpat = $ENV{"P2CC_PAT"} || "\\.p\$|\\.pas\$";
$cccommand = $ENV{"P2CC_CC"} || "cc";
$ccopts = $ENV{"P2CC_CCOPTS"} || "";
$ccopts2 = $ENV{"P2CC_CCOPTS2"} || "";
$p2clib = $ENV{"P2CC_LIBP2C"};
$p2ccommand = $ENV{"P2CC_P2C"} || "p2c";
$p2copts = $ENV{"P2CC_P2COPTS"} || "-comp -local";
$suffix = $ENV{"P2CC_SUFFIX"} || "..c";

unless ($p2clib) {
  $p2clib = "$libdir/libp2c.a";
  unless (-f $p2clib) {
    $p2clib = "-lp2c";
  }
}

$ccname = $cccommand;
$ccname =~ s/ .*$//;
$ccname =~ s/^.*\///;

($progname = $0) =~ s/.*\///g;


@ccargs = ( );
@p2cargs = ( );
@p2cfiles = ( );
@rmfiles = ( );

$verbose = 0;
$quietopt = " -q";
$nocc = 0;
$noobj = 0;
$onedot = 0;
$checkopt = " -check";


while (@ARGV) {
  $_ = shift @ARGV;
  if (/^-I/) {
    push(@ccargs, $_);
    push(@p2cargs, $_);
    if (/^-I$/) {
      $_ = shift @ARGV;
      push(@ccargs, $_);
      push(@p2cargs, $_);
    }
  } elsif (/^-p2c$/) {
    $nocc = 1;
    $onedot = 1;
  } elsif (/^-p2c/) {
    push(@p2cargs, $');
  } elsif (/^-/) {
    if (/^-O/) {
      $checkopt = "";
    } elsif (/^-c$/) {
      $noobj = 1;
      $onedot = 1;
    } elsif (/^-v$/) {
      $quietopt = "";
      $verbose = 1;
    }
    push(@ccargs, $_);
  } elsif (/$pascalpat/) {
    push(@p2cfiles, $_);
  } else {
    push(@ccargs, $_);
  }
}


if ($onedot) {
  $suffix =~ s/\.\./\./;
}


sub dodie {
  unlink @rmfiles;
  die @_;
}


foreach (@p2cfiles) {
  /$pascalpat/;
  $base = $`;
  $cname = "$base$suffix";
  unlink $cname;
  $opts = " $p2copts$checkopt$quietopt @p2cargs $_ -o $cname";
  if (!($opts =~ / -H/) && (-f "$homedir/p2crc")) {
    $opts = " -H --HOMEDIR--$opts";
  }
  $cmd = "$p2ccommand$opts";
  $verbose && print "$cmd\n";
  $res = system($cmd);
  ($res < 0) && &dodie("$progname $_: $p2ccommand failed: $!\n");
  ($res >> 8) && &dodie("$progname $_: errors found by p2c\n");
  push(@ccargs, $cname);
  push(@rmfiles, $cname);
}


unless ($nocc) {
  $noobj && ($p2clib = "");
  if ((($inc = $incdir) =~ s/\/p2c$//) && -f "$inc/p2c/p2c.h") {
    $ccopts .= " -I$inc";
  }
  $cmd = "$cccommand $ccopts @ccargs $ccopts2 $p2clib";
  $verbose && print "$cmd\n";
  $res = system($cmd);
  ($res < 0) && &dodie("$progname: $cccommand failed: $!\n");
  ($res >> 8) && &dodie("$progname: errors found by $ccname\n");
  $verbose && print "$progname: removing @rmfiles\n";
  unlink @rmfiles;
}


exit 0;   # Successful completion.

