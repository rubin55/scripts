#!/usr/bin/perl -w

## killdupes.pl
## 
## Simple script to remove duplicate messages from an mbox file.
## Created by William Reardon -- 11/29/02
## 
## 

use strict;
use Getopt::Long;
use Data::Dumper;
use File::Copy;

our $VERSION = '$Revision: 1.1 $ ';

&main();


sub main {
  my $cfg = &init();

  foreach my $f (@{ $cfg->{files} }) {
    &crunch($f);
  }

  if ($cfg->{pause_at_end}) {
    print "Press return to exit...";
    <STDIN>;
  }
}


##############################################################  crunch  ######
sub crunch {
  my ($f) = @_;
  my ($b, $n, $msg, $line, %ids, $total, $duplicates, $originals, $errors);
  
  $total =  $duplicates =  $originals = $errors = 0;
  unless (-f $f) {
    print STDERR ("No file '$f'... Skipping!\n");
    return -1;
  }
  
  ## Create backup & working files
  $b = "$f.bak";
  $n = "$f.new";
  copy($f, $b) || die("Couldn't copy '$f' to '$b': $!");
  copy($f, $n) || die("Couldn't copy '$f' to '$n': $!");
  open(F, $f) || die("Couldn't read '$f' :$!");
  open(N, ">$n") || die("Couldn't read '$n' : $!");

  $msg = "";
  while ($line = <F>) {
    if ($line =~ /^From /) {
      next unless ($msg);
      $total++;
      my $rv = &process_message( $msg, \%ids, \*N );
      if ($rv > 0) {
        $originals++;
      } elsif ($rv == 0) {
        $duplicates++;
      } elsif ($rv < 0) {
        $errors++;
      }
      $msg = "";
    }
    $msg .= $line;
  }
  my $rv = &process_message( $msg, \%ids, \*N );
  if ($rv > 0) {
    $originals++;
  } elsif ($rv == 0) {
    $duplicates++;
  } elsif ($rv < 0) {
    $errors++;
  }

  close(F) || warn($!);
  close(N) || warn($!);
  unlink($f) || die("Could not unlink '$f': $!");
  rename($n, $f) || die("Could not move '$n' to '$f': $!");
  print "$f: $total messages, $originals kept, $duplicates duplicates, $errors errors.\n";
}


########################################################  process_message  ### 
sub process_message {
  my ($msg, $ids, $NFH) = @_;

      my ($id) = ($msg) =~ /^Message-ID: (.*)$/im;
      unless ($id) {
        warn("Odd. Could not extract id from message?\n",
             "=" x 78, "\n",
             $msg,
             "=" x 78, "\n");
        return -1 ;
      }
      
      unless (exists $ids->{ $id }) {
        $ids->{ $id } = 1;
        print $NFH $msg;
        return 1;
      } else {
        return 0;
      }
}




sub init {
  my ($cfg, $usage, @files);

  $cfg = {};
  $usage=<<'__USAGE__';
killdupes.pl [--help] [--version] [<mbox files>]

Simple script to remove duplicate messages from a mbox file.
If no mbox files are found, will glob for *.mbox files in working directory.

--help       - show this screen
--version    - show the version number  
__USAGE__
    
  &GetOptions($cfg, "help!", "version!") || die($usage);

  if ($cfg->{help}) {
    print $usage;
    exit(0);
  }

  if ($cfg->{version}) {
    print $VERSION, "\n";
    exit(0);
  }
  
  while (my $f = shift @ARGV) {
    unshift @files, $f;
  }
  ## Allow someone to double-click us in Windoze
  unless (@files) {
    opendir(D, ".") || die($!);
    $cfg->{pause_at_end} = 1;
    @files = sort grep {-f $_} grep { /\.mbx$/ } readdir(D);
  }
  
  die($usage) unless (@files);
  $cfg->{files} = \@files;

  return $cfg;
}
