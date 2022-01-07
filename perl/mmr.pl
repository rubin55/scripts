#!/usr/bin/perl -w
#
# mmr.pl - configure multimaster replication between two fedora-ds servers
#
# Mike Jackson <mj@sci.fi> 19.11.2005
# Federico Roman added the --port option. 10-08-2007
#
# Professional LDAP consulting for large and small projects
#
#       http://www.netauth.com
#
# GPLv2 License
#

use strict;
use Getopt::Long;
use Net::LDAP qw(LDAP_ALREADY_EXISTS LDAP_TYPE_OR_VALUE_EXISTS);
use Pod::Usage;

my %o;
GetOptions(
    \%o,
    'base=s',       # optional, default to get_base()
    'binddn=s',     # optional, default to "cn=directory manager"
    'bindpw=s',
    'repmanpw=s',
    'host1=s',
    'host2=s',
    'host1_id=i',
    'host2_id=i',
    'port=i',
    'create',
    'display',
    'remove',
    'with-ssl',
    'help',
    'man',
);

pod2usage(-verbose => 1) if ($o{help});
pod2usage(-verbose => 2) if ($o{man} );

pod2usage(-verbose => 1) if (! ($o{create} || $o{display} || $o{remove}) );

# mandatory in all cases
my $host1     = $o{host1};
my $host2     = $o{host2};
my $bindpw    = $o{bindpw};

# mandatory in create case
my $create    = $o{create};
my $host1_id  = $o{host1_id};
my $host2_id  = $o{host2_id};
my $repmanpw  = $o{repmanpw};

# mandatory in display case
my $display   = $o{display};

# mandatory in remove case
my $remove    = $o{remove};

# optional in create case
my $with_ssl  = $o{'with-ssl'};

# optional in all cases
my $port      = $o{port}    || ($with_ssl && "636") || "389";
my $base      = $o{base}    || get_base($host1, $port);
my $binddn    = $o{binddn}  || "cn=directory manager";


# all cases check
if (!($host1 && $host2 && $bindpw))
{
    pod2usage(-verbose => 1);
    exit(1);
}



###############################################
# create
###############################################
if ($create)
{
    if (!($host1_id && $host2_id && $repmanpw))
    {
        pod2usage(-verbose => 1);
        exit(1);
    }
    else
    {
        # configure suppliers
        config_supplier($host1, $port, $host1_id, $repmanpw);
        config_supplier($host2, $port, $host2_id, $repmanpw);

        # add replication agreements
        add_rep_agreement($host1, $host2, $port, $repmanpw);
        add_rep_agreement($host2, $host1, $port, $repmanpw);

        # initialize host2 from host1
        initialize($host1, $host2, $port);
    }
}

###############################################
# remove
###############################################
if ($remove)
{
    if (!($host1 && $host2))
    {
        pod2usage(-verbose => 1);
        exit(1);
    }
    else
    {
        # remove agreements
        remove_agreement($host1, $host2, $port);
        remove_agreement($host2, $host1, $port);
    }
}

###############################################
# display
###############################################
if ($display)
{
    if (!($host1 && $host2))
    {
        pod2usage(-verbose => 1);
        exit(1);
    }
    else
    {
        # display agreements
        print "\n";
        display_agreement($host1, $port);
        print "\n";
        display_agreement($host2, $port);
        print "\n";
    }
}



###############################################
# subs
###############################################
sub display_agreement
{
    my ($server, $prt) = @_;

    my $msg;
    my $res;

    my $ldap = Net::LDAP->new($server, port => $prt) || die "$@";

    $msg     = $ldap->bind($binddn, password => $bindpw, version => 3);
    $msg->code && die $msg->error;

    print "replication agreements from $server ($prt)\n";
    $res = $ldap->search(
                         base    => "cn=config",
                         filter  => "(objectClass=nsDS5ReplicationAgreement)",
                        );
    $res->code && die $res->error;

    if ($res->count)
    {
        for ($res->entries)
        {
            print "\t ->" . $_->get_value("nsDS5ReplicaHost");
            print " (" . $_->get_value("nsDS5ReplicaPort") . ")\n";
        }
    }
    else
    {
        print "\t -> none found\n";
    }

    $ldap->unbind;
}


sub remove_agreement
{
    my ($from, $to, $prt) = @_;

    my $msg;
    my $res;

    my $ldap = Net::LDAP->new($from, port => $prt) || die "$@";

    $msg     = $ldap->bind($binddn, password => $bindpw, version => 3);
    $msg->code && die $msg->error;

    print "removing replication agreement from $from -> $to\n";
    $res = $ldap->search(
                         base    => "cn=config",
                         filter  => "(&(objectClass=nsDS5ReplicationAgreement)(nsDS5ReplicaHost=$to))",
                        );
    $res->code && die $res->error;

    my $dn  = $res->entry(0)->dn;

    $res    = $ldap->delete($dn);
    $res->code && warn "failed to remove replication agreement: " . $res->error;

    $ldap->unbind;
}


sub config_supplier
{
    my ($server, $prt, $replicaid, $repmanpw) = @_;

    my $msg;
    my $res;

    my $ldap = Net::LDAP->new($server, port => $prt) || die "$@";

    $msg     = $ldap->bind($binddn, password => $bindpw, version => 3);
    $msg->code && die $msg->error;


    ##############################
    # find the instance-dir
    ##############################
    $res = $ldap->search (
                          base    => "cn=config",
                          scope   => "base",
                          filter  => "(objectClass=*)",
                         );

    my $instance_dir = $res->entry(0)->get_value("nsslapd-instancedir");
    my $hadd = $server;
    # $hadd = "newserver" if $server eq "some_exception";
    $instance_dir ||= "/etc/fedora-ds/slapd-$hadd";
    ##############################

    ##############################
    # add changelog
    ##############################
    print "adding to $server -> cn=changelog5,cn=config\n";
    $res = $ldap->add(
          "cn=changelog5,cn=config",
          attr => [
            objectclass                  => [qw (top extensibleObject)],
            cn                           => "changelog5",
            "nsslapd-changelogdir"       => "$instance_dir/changelogdb",
          ]
    );

    if ($res->code == LDAP_ALREADY_EXISTS)
    {
        print "\t -> already exists\n\n";
    }
    else
    {
        $res->code && die "failed to add changelog entry: " . $res->error;
    }
    ##############################

    ##############################
    # add replication user
    ##############################
    print "adding to $server -> cn=repman,cn=config\n";
    $res = $ldap->add(
          "cn=repman,cn=config",
          attr => [
            objectclass    => [qw (top person)],
            cn             => "repman",
            sn             => "repman",
            userPassword   => $repmanpw,
          ]
    );

    if ($res->code == LDAP_ALREADY_EXISTS)
    {
        print "\t -> already exists\n\n";
    }
    else
    {
        $res->code && die "failed to add repman entry: " . $res->error;
    }
    ##############################

    ##############################
    # add replica object
    ##############################
    print "adding to $server -> cn=replica,cn=\"$base\",cn=mapping tree,cn=config\n";
    $res = $ldap->add(
          "cn=replica,cn=\"$base\",cn=mapping tree,cn=config",
          attr => [
            objectclass                  => [qw (top nsDS5Replica)],
            cn                           => "replica",
            nsDS5ReplicaId               => $replicaid,
            nsDS5ReplicaRoot             => $base,
            nsDS5Flags                   => 1,
            nsDS5ReplicaBindDN           => "cn=repman,cn=config",
            nsds5ReplicaPurgeDelay       => 604800,
            nsds5ReplicaLegacyConsumer   => "off",
            nsDS5ReplicaType             => 3,
          ]
    );

    if ($res->code == LDAP_ALREADY_EXISTS)
    {
        print "\t -> already exists\n\n";
    }
    else
    {
        $res->code && die "failed to add replica entry: " . $res->error;
    }
    ##############################

    $ldap->unbind;
}


sub add_rep_agreement
{
    my ($from, $to, $prt, $repmanpw) = @_;

    my $msg;
    my $res;
    
    my $ldap = Net::LDAP->new($from, port => $prt) || die "$@";

    $msg     = $ldap->bind($binddn, password => $bindpw, version => 3);
    $msg->code && die $msg->error;

    if ($with_ssl)
    {
        print "adding to $from -> SSL replication $from -> $to\n";
        $res = $ldap->add(
              "cn=\"Replication to $to\",cn=replica,cn=\"$base\",cn=mapping tree,cn=config",
              attr => [
                objectclass                  => [qw (top nsDS5ReplicationAgreement)],
                cn                           => "\"Replication to $to\"",
                nsDS5ReplicaHost             => $to,
                nsDS5ReplicaRoot             => "$base",
                nsDS5ReplicaPort             => $prt,
                nsDS5ReplicaTransportInfo    => "SSL",
                nsDS5ReplicaBindDN           => "cn=repman,cn=config",
                nsDS5ReplicaBindMethod       => "simple",
                nsDS5ReplicaCredentials      => $repmanpw,
                nsDS5ReplicaUpdateSchedule   => "0000-2359 0123456",
                nsDS5ReplicaTimeOut          => 120,
              ]
        );

        if ($res->code == LDAP_ALREADY_EXISTS)
        {
            print "\t -> already exists\n\n";
        }
        else
        {
            $res->code && die "failed to add replication agreement entry: " . $res->error;
        }
    }
    else
    {
        print "adding to $from -> plaintext replication $from -> $to\n";
        $res = $ldap->add(
              "cn=\"Replication to $to\",cn=replica,cn=\"$base\",cn=mapping tree,cn=config",
              attr => [
                objectclass                  => [qw (top nsDS5ReplicationAgreement)],
                cn                           => "\"Replication to $to\"",
                nsDS5ReplicaHost             => $to,
                nsDS5ReplicaRoot             => "$base",
                nsDS5ReplicaPort             => $prt,
                nsDS5ReplicaBindDN           => "cn=repman,cn=config",
                nsDS5ReplicaBindMethod       => "simple",
                nsDS5ReplicaCredentials      => $repmanpw,
                nsDS5ReplicaUpdateSchedule   => "0000-2359 0123456",
                nsDS5ReplicaTimeOut          => 120,
              ]
        );

        if ($res->code == LDAP_ALREADY_EXISTS)
        {
            print "\t -> already exists\n\n";
        }
        else
        {
            $res->code && die "failed to add replication agreement entry: " . $res->error;
        }
    }

    $ldap->unbind;
}


sub initialize
{
    my ($from, $to, $prt) = @_;

    my $msg;
    my $res;

    my $ldap = Net::LDAP->new($from, port => $prt) || die "$@";

    $msg     = $ldap->bind($binddn, password => $bindpw, version => 3);
    $msg->code && die $msg->error;

    print "initializing replication $from -> $to (port $prt)\n";

    my $dn = "cn=\"Replication to $to\",cn=replica,cn=\"$base\",cn=mapping tree,cn=config";

    $res = $ldap->modify($dn, add => { nsDS5BeginReplicaRefresh => 'start' });
    $res->code && die "failed to add initialization attribute: " . $res->error;

    $ldap->unbind;
}


sub get_base
{
    my ($server, $prt) = @_;

    my $base;
    my $res;

    my $ldap = Net::LDAP->new($server, port => $prt) || die "$@";
    $ldap->bind;

    $res = $ldap->search(
                         base    => "",
                         scope   => "base",
                         filter  => "(objectClass=*)",
                        );
    $res->code && die $res->error;

    my @contexts = $res->entry(0)->get_value("namingContexts");

    for (@contexts)
    {
        if (! /o=NetscapeRoot/)
        {
            $base = $_;
        }
    }

    $ldap->unbind;

    return $base;
}


__END__

=head1 NAME

mmr.pl - Configure multi-master replication between two Fedora Directory Servers

=head1 SYNOPSIS

Usage: mmr.pl [options]

 Mandatory in all cases:
    --host1       FQDN of host 1
    --host2       FQDN of host 2
    --bindpw      Password for Directory Manager

 Optional in all cases:
    --base        LDAP naming context
    --binddn      Alternative distinguished name for Directory Manager
    --port        LDAP port (default=389)

 Mandatory for creating a 2-way agreement:
    --host1_id    Replication ID number of host 1
    --host2_id    Replication ID number of host 2
    --repmanpw    Password for Replication Manager
    --create

 Optional when creating a 2-way agreement:
    --with-ssl    Use SSL for Replication (requires CA and server certs on both machines)

 Mandatory for removing a 2-way agreement:
    --remove

 Mandatory for displaying agreements
    --display

 Examples:

 # create a 2-way replication agreement
 % mmr.pl \
    --host1 a.bigcorp.com \
    --host2 b.bigcorp.com \
    --host1_id 1 \
    --host2_id 2 \
    --bindpw secret \
    --repmanpw repsecret \
    --create

 # create a 2-way replication agreement with SSL
 % mmr.pl \
    --host1 a.bigcorp.com \
    --host2 b.bigcorp.com \
    --host1_id 1 \
    --host2_id 2 \
    --bindpw secret \
    --repmanpw repsecret \
    --create \
    --with-ssl

 # remove a 2-way replication agreement
 % mmr.pl \
    --host1 a.bigcorp.com \
    --host2 b.bigcorp.com \
    --bindpw secret \
    --remove

 # display replication agreements
 % mmr.pl \
    --host1 a.bigcorp.com \
    --host2 b.bigcorp.com \
    --port 3890
    --bindpw secret \
    --display


=head1 DESCRIPTION

B<mmr.pl> will configure multi-master replication between two Fedora or
Redhat Directory Servers.

The listen port must be the same on both machines. By default port 389
is assumed (636 if --with-ssl) , but it can be overriden with the --port option.

The "cn=Directory Manager" user's password must be the same on both
machines. As well, the "cn=Directory Manager" user which was created
during installation must exist on both machines, or if this username
was changed to something else then it can be provided with the --binddn
option.

The LDAP naming context must be the same on both machines. If there
is only one naming context configured on the machines, then it is not
necessary to provide the --base option as the naming context will be
discovered automatically.

=cut

