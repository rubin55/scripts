#!/usr/bin/env perl

use MIME::Base64;
print decode_base64($ARGV[0]) . "\n";
