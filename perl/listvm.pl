#!/usr/bin/perl

# Handle module imports. 
use VMware::VIRuntime;

# Read, validate and connect.
Opts::parse();
Opts::validate();
Util::connect();

# Get a list of all virtual machines
$input = Vim::find_entity_views(view_type => 'VirtualMachine');

# Parse each line and output a short name.
foreach (@$input) {
    @name  = split(/\./, lc($_->name));  # Create an fqdn array from input.
    push(@vmlist, $name[0]);              # Push the shortname onto a fresh array.
}

@vmlist = sort(@vmlist);
foreach $name (@vmlist) {
    print $name. "\n";
}

# Disconnect and cleanup.
Util::disconnect();                                  

