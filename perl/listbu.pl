#!/usr/bin/env perl

# Extract list of virtual machines from the NetBackup environment and output to file.
system('bpplclients -allunique | find /i "virtual_machine" > %TEMP%\bpplclients.out');

# Open created file, remove empty lines and sort it.
open(input, "<$ENV{'TEMP'}\\bpplclients.out");
@lines = grep(/\S/, sort(<input>));

# Parse each line and output a short name.
foreach $line (@lines) {
    $line = lc($line);              # Lowercase line coming from input.
    @line = split(/\s+/, $line);    # Convert to array, split on whitespace.
    @fqdn  = split(/\./, $line[2]); # Create an fqdn array from input.
    print $fqdn[0] . "\n";          # Output short name and append newline.
}

# Close input file.
close(input);
system('del %TEMP%\bpplclients.out');
