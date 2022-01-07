#!/usr/bin/env python

# Discover 0.1 (C) 2009 Rubin Simons - http://grond.org (GPLv3 License)
# IPCalc 0.3 routines (C) 2009 Wijnand Modderman - http://tehmaze.com (BSD License)

import socket
import subprocess
import sys
import types

class IP(object):
    '''
    Represents a single IP address.

    >>> localhost = IP("127.0.0.1")
    >>> print localhost
    127.0.0.1
    >>> localhost6 = IP("::1")
    >>> print localhost6
    0000:0000:0000:0000:0000:0000:0000:0001
    '''

    # Hex-to-Bin conversion masks
    _bitmask = {
        '0': '0000', '1': '0001', '2': '0010', '3': '0011',
        '4': '0100', '5': '0101', '6': '0110', '7': '0111',
        '8': '1000', '9': '1001', 'a': '1010', 'b': '1011',
        'c': '1100', 'd': '1101', 'e': '1110', 'f': '1111'
        }

    # IP range specific information, see IANA allocations.
    _range = {
        4: {
            '01'                    : 'CLASS A',
            '10'                    : 'CLASS B',
            '110'                   : 'CLASS C',
            '1110'                  : 'CLASS D MULTICAST',
            '11100000'              : 'CLASS D LINKLOCAL',
            '1111'                  : 'CLASS E',
            '00001010'              : 'PRIVATE RFC1918', # 10/8
            '101011000001'          : 'PRIVATE RFC1918', # 172.16/12
            '1100000010101000'      : 'PRIVATE RFC1918', # 192.168/16
            },
        6: {
            '00000000'              : 'RESERVED',       # ::/8
            '00000001'              : 'UNASSIGNED',     # 100::/8
            '0000001'               : 'NSAP',           # 200::/7
            '0000010'               : 'IPX',            # 400::/7
            '0000011'               : 'UNASSIGNED',     # 600::/7
            '00001'                 : 'UNASSIGNED',     # 800::/5
            '0001'                  : 'UNASSIGNED',     # 1000::/4
            '0010000000000000'      : 'RESERVED',       # 2000::/16 Reserved
            '0010000000000001'      : 'ASSIGNABLE',     # 2001::/16 Sub-TLA Assignments [RFC2450]
            '00100000000000010000000': 'ASSIGNABLE IANA',  # 2001:0000::/29 - 2001:01F8::/29 IANA
            '00100000000000010000001': 'ASSIGNABLE APNIC', # 2001:0200::/29 - 2001:03F8::/29 APNIC
            '00100000000000010000010': 'ASSIGNABLE ARIN',  # 2001:0400::/29 - 2001:05F8::/29 ARIN
            '00100000000000010000011': 'ASSIGNABLE RIPE',  # 2001:0600::/29 - 2001:07F8::/29 RIPE NCC
            '0010000000000010'      : '6TO4',           # 2002::/16 "6to4" [RFC3056]
            '0011111111111110'      : '6BONE TEST',     # 3ffe::/16 6bone Testing [RFC2471]
            '0011111111111111'      : 'RESERVED',  # 3fff::/16 Reserved
            '010'                   : 'GLOBAL-UNICAST', # 4000::/3
            '011'                   : 'UNASSIGNED',     # 6000::/3
            '100'                   : 'GEO-UNICAST',    # 8000::/3
            '101'                   : 'UNASSIGNED',     # a000::/3
            '110'                   : 'UNASSIGNED',     # c000::/3
            '1110'                  : 'UNASSIGNED',     # e000::/4
            '11110'                 : 'UNASSIGNED',     # f000::/5
            '111110'                : 'UNASSIGNED',     # f800::/6
            '1111110'               : 'UNASSIGNED',     # fc00::/7
            '111111100'             : 'UNASSIGNED',     # fe00::/9
            '1111111010'            : 'LINKLOCAL',      # fe80::/10
            '1111111011'            : 'SITELOCAL',      # fec0::/10
            '11111111'              : 'MULTICAST',      # ff00::/8
            '0' * 96                : 'IPV4COMP',       # ::/96
            '0' * 80 + '1' * 16     : 'IPV4MAP',        # ::ffff:0:0/96
            '0' * 128               : 'UNSPECIFIED',    # ::/128
            '0' * 127 + '1'         : 'LOOPBACK'        # ::1/128
            }
        }

    def __init__(self, ip, mask=None, version=0):
        self.mask = mask
        self.v = 0
        # Parse input
        if isinstance(ip, IP):
            self.ip = ip.ip
            self.dq = ip.dq
            self.v = ip.v
            self.mask = ip.mask
        elif type(ip) in [types.IntType, types.LongType]:
            self.ip = long(ip)
            if self.ip <= 0xffffffff:
                self.v = version or 4
                self.dq = self._itodq(ip)
            else:
                self.v = version or 4
                self.dq = self._itodq(ip)
        else:
            # If string is in CIDR notation
            if '/' in ip:
                ip, mask = ip.split('/', 1)
                self.mask = int(mask)
            self.v = version or 0
            self.dq = ip
            self.ip = self._dqtoi(ip)
            assert self.v != 0, 'Could not parse input'
        # Netmask defaults to one ip
        if self.mask is None:
            self.mask = self.v == 4 and 32 or 128
        # Validate subnet size
        if self.v == 6:
            self.dq = self._itodq(self.ip)
            if self.mask < 0 or self.mask > 128:
                raise ValueError, "IPv6 subnet size must be between 0 and 128"
        elif self.v == 4:
            if self.mask < 0 or self.mask > 32:
                raise ValueError, "IPv4 subnet size must be between 0 and 32"

    def bin(self):
        '''
        Full-length binary representation of the IP address.

        >>> ip = IP("127.0.0.1")
        >>> print ip.bin()
        01111111000000000000000000000001
        '''
        h = hex(self.ip).lower().rstrip('l')
        b = ''.join(self._bitmask[x] for x in h[2:])
        l = self.v == 4 and 32 or 128
        return ''.join('0' for x in xrange(len(b), l)) + b

    def hex(self):
        '''
        Full-length hexadecimal representation of the IP address.

        >>> ip = IP("127.0.0.1")
        >>> print ip.hex()
        7f000001
        '''
        if self.v == 4:
            return '%08x' % self.ip
        else:
            return '%032x' % self.ip

    def subnet(self):
        return self.mask

    def version(self):
        '''
        IP version.

        >>> ip = IP("127.0.0.1")
        >>> print ip.version()
        4
        '''
        return self.v
   
    def info(self):
        '''
        Show IANA allocation information for the current IP address.

        >>> ip = IP("127.0.0.1")
        >>> print ip.info()
        CLASS A
        '''
        b = self.bin()
        l = self.v == 4 and 32 or 128
        for i in range(len(b), 0, -1):
            if self._range[self.v].has_key(b[:i]):
                return self._range[self.v][b[:i]]
        return 'UNKNOWN'
 
    def _dqtoi(self, dq):
        '''
        Convert dotquad or hextet to long.
        '''
        # hex notation
        if dq.startswith('0x'):
            ip = long(dq[2:], 16)
            if ip > 0xffffffffffffffffffffffffffffffffL:
                raise ValueError, "%r: IP address is bigger than 2^128" % dq
            if ip <= 0xffffffff:
                self.v = 4
            else:
                self.v = 6
            return ip

        # IPv6
        if ':' in dq:
            hx = dq.split(':') # split hextets
            if ':::' in dq:
                raise ValueError, "%r: IPv6 address can't contain :::" % dq
            # Mixed address (or 4-in-6), ::ffff:192.0.2.42
            if '.' in dq:
                return self._dqtoi(hx[-1])
            if len(hx) > 8:
                raise ValueError, "%r: IPv6 address with more than 8 hexletts" % dq
            elif len(hx) < 8:
                # No :: in address
                if not '' in hx:
                    raise ValueError, "%r: IPv6 address invalid: compressed format malformed" % dq
                elif not (dq.startswith('::') or dq.endswith('::')) and len([x for x in hx if x == '']) > 1:
                    raise ValueError, "%r: IPv6 address invalid: compressed format malformed" % dq
                ix = hx.index('')
                px = len(hx[ix+1:])
                for x in xrange(ix+px+1, 8):
                    hx.insert(ix, '0')
            elif dq.endswith('::'):
                pass
            elif '' in hx:
                raise ValueError, "%r: IPv6 address invalid: compressed format detected in full notation" % dq
            ip = ''
            hx = [x == '' and '0' or x for x in hx]
            for h in hx:
                if len(h) < 4:
                    h = '%04x' % int(h, 16)
                if 0 > int(h, 16) > 0xffff:
                    raise ValueError, "%r: IPv6 address invalid: hextets should be between 0x0000 and 0xffff" % dq
                ip += h
            self.v = 6
            return long(ip, 16)
        elif len(dq) == 32:
            # Assume full heximal notation
            self.v = 6
            return long(h, 16)
        
        # IPv4
        if '.' in dq:
            q = dq.split('.')
            q.reverse()
            if len(q) > 4:
                raise ValueError, "%r: IPv4 address invalid: more than 4 bytes" % dq
            for x in q:
                if 0 > int(x) > 255:
                    raise ValueError, "%r: IPv4 address invalid: bytes should be between 0 and 255" % dq
            while len(q) < 4:
                q.insert(1, '0')
            self.v = 4
            return sum(long(byte) << 8 * index for index, byte in enumerate(q))
    
        raise ValueError, "Invalid address input"
       
    def _itodq(self, n):
        '''
        Convert long to dotquad or hextet.
        '''
        if self.v == 4:
            return '.'.join(map(str, [(n>>24) & 0xff, (n>>16) & 0xff, (n>>8) & 0xff, n & 0xff]))
        else:
            n = '%032x' % n
            return ':'.join(n[4*x:4*x+4] for x in xrange(0, 8))

    def __str__(self):
        '''
        Return dotquad representation of the IP.

        >>> ip = IP("::1")
        >>> print str(ip)
        0000:0000:0000:0000:0000:0000:0000:0001
        '''
        return self.dq

    def __int__(self):
        return int(self.ip)

    def __long__(self):
        return self.ip

    def size(self):
        return 1

    def clone(self):
        '''
        Return a new <IP> object with a copy of this one.

        >>> ip = IP('127.0.0.1')
        >>> ip.clone()
        <ipcalc.IP object at 0xb7d4d18c>
        '''
        return IP(self)

    def to_ipv4(self):
        '''
        Convert (an IPv6) IP address to an IPv4 address, if possible. Only works
        for IPv4-compat (::/96) and 6-to-4 (2002::/16) addresses.

        >>> ip = IP('2002:c000:022a::')
        >>> print ip.to_ipv4()
        192.0.2.42
        '''
        if self.v == 4:
            return self
        else:
            if self.bin().startswith('0' * 96):
                return IP(long(self), version=4)
            elif long(self) & 0x20020000000000000000000000000000L:
                return IP((long(self)-0x20020000000000000000000000000000L)>>80, version=4)
            else:
                return ValueError, "%r: IPv6 address is not IPv4 compatible, nor a 6-to-4 IP" % self.dq

    def to_ipv6(self, type='6-to-4'):
        '''
        Convert (an IPv4) IP address to an IPv6 address.

        >>> ip = IP('192.0.2.42')
        >>> print ip.to_ipv6()
        2002:c000:022a:0000:0000:0000:0000:0000
        '''
        assert type in ['6-to-4', 'compat'], 'Conversion type not supported'
        if self.v == 4:
            if type == '6-to-4':
                return IP(0x20020000000000000000000000000000L | long(self)<<80, version=6)
            elif type == 'compat':
                return IP(long(self), version=6)
        else:
            return self

    def to_tuple(self):
        '''
        Used for comparisons.
        '''
        return (self.dq, self.mask)
    
class Network(IP):
    '''
    Network slice calculations.

    >>> localnet = Network('127.0.0.1/8')
    >>> print localnet
    127.0.0.1
    '''

    def netmask(self):
        '''
        Network netmask derived from subnet size.

        >>> localnet = Network('127.0.0.1/8')
        >>> print localnet.netmask()
        255.0.0.0
        '''
        if self.version() == 4:
            return IP((0xffffffffL >> (32-self.mask)) << (32-self.mask), version=self.version())
        else:
            return IP((0xffffffffffffffffffffffffffffffffL >> (128-self.mask)) << (128-self.mask), version=self.version())

    def network(self):
        '''
        Network address.

        >>> localnet = Network('127.128.99.3/8')
        >>> print localnet.network()
        127.0.0.0
        '''
        return IP(self.ip & long(self.netmask()), version=self.version())
    
    def broadcast(self):
        '''
        Broadcast address.

        >>> localnet = Network('127.0.0.1/8')
        >>> print localnet.broadcast()
        127.255.255.255
        '''
        # XXX: IPv6 doesn't have a broadcast address, but it's used for other 
        #      calculations such as <Network.host_last>.
        if self.version() == 4:
            return IP(long(self.network()) | (0xffffffff - long(self.netmask())), version=self.version())
        else:
            return IP(long(self.network()) | (0xffffffffffffffffffffffffffffffffL - long(self.netmask())), version=self.version())

    def host_first(self):
        '''
        First available host in this subnet.
        '''
        if (self.version() == 4 and self.mask == 32) or (self.version() == 6 and self.mask == 128):
            return self
        return IP(long(self.network())+1, version=self.version())

    def host_last(self):
        '''
        Last available host in this subnet.
        '''
        if (self.version() == 4 and self.mask == 32) or (self.version() == 6 and self.mask == 128):
            return self
        return IP(long(self.broadcast())-1, version=self.version())

    def in_network(self, other):
        '''
        Check if the given IP address is within this network.
        '''
        other = Network(other)
        return long(other) >= long(self) and long(other) < long(self) + self.size() - other.size() + 1

    def __contains__(self, ip):
        '''
        Check if the given ip is part of the network.

        >>> '192.0.2.42' in Network('192.0.2.0/24')
        True
        >>> '192.168.2.42' in Network('192.0.2.0/24')
        False
        '''
        return self.in_network(ip)

    def __lt__(self, other):
        return self.size() < IP(other).size()

    def __le__(self, other):
        return self.size() <= IP(other).size()

    def __gt__(self, other):
        return self.size() > IP(other).size()

    def __ge__(self, other):
        return self.size() >= IP(other).size()

    def __iter__(self):
        '''
        Generate a range of ip addresses within the network.

        >>> for ip in Network('192.168.114.0/30'):
        ...     print str(ip)
        ... 
        192.168.114.0
        192.168.114.1
        192.168.114.2
        192.168.114.3
        '''
        for ip in [IP(long(self)+x) for x in xrange(0, self.size())]:
            yield ip

    def has_key(self, ip):
        '''
        Check if the given ip is part of the network.

        >>> net = Network('192.0.2.0/24')
        >>> net.has_key('192.168.2.0')
        False
        >>> net.has_key('192.0.2.42')
        True
        '''
        return self.__contains__(ip)

    def size(self):
        '''
        Number of ip's within the network.

        >>> net = Network('192.0.2.0/24')
        >>> print net.size()
        256
        '''
        return 2 ** ((self.version() == 4 and 32 or 128) - self.mask)

# Terse namespace definition based on "DNS Namespace within the Datacenter v1.0.1".
categories = dict(
    c = dict( 
        name = 'computing device',
        members = ['ex', 'hp', 'ln', 'wn']
    ),
    f = dict( 
        name = 'floating address',
        members = ['db', 'ws', 'ap', 'sa', 'sb', 'ns', 'ts', 'mc']
    ),
    n = dict(
        name = 'network device',
        members = ['cs', 'es', 'lb', 'fw', 'vc', 'id', 'ip', 'am', 'ds', 'dl', 'lo', 'si', 'gw', 'ts']
    ),
    s = dict(
        name = 'storage device',
        members = ['cs', 'es', 'sp', 'c0', 'c1', 's0', 's1', 'ta', 'hd', 'ns', 'lg']
    ),
    i = dict(
        name = 'intermediary interface',
        members = ['lo', 'gs', 'mc']
    ),
    o = dict(
        name = 'other device',
        members = ['ch', 'rc']
    )
)

# Basic dtap designations.
designations = dict(
    d='development',
    t='testing',
    a='acceptance',
    p='production'
)

# Network definitions
management = dict(
    equinix = dict(
        pv = Network('10.244.0.0/21'),
        pa = Network('10.244.64.0/22'),
        pd = Network('10.244.96.0/22'),
        av = Network('10.245.0.0/21'),
        aa = Network('10.245.64.0/22'),
        ad = Network('10.245.96.0/22'),
        tv = Network('10.245.128.0/22'),
        ta = Network('10.245.160.0/23'),
        td = Network('10.245.176.0/23'),
        dv = Network('10.245.192.0/22'),
        da = Network('10.245.224.0/23'),
        dd = Network('10.245.240.0/23'),
        mv = Network('10.244.128.0/22'),
        ma = Network('10.244.160.0/23'),
        md = Network('10.244.176.0/23'),
        il = Network('10.244.192.0/24'),
        la = Network('10.244.200.0/24'),
        lo = Network('10.244.208.0/23'),
        am = Network('10.244.224.0/23'),
        ns = Network('10.244.240.0/23')
    ),
    telecity = dict(
        pv = Network('10.244.8.0/21'),
        pa = Network('10.244.68.0/22'),
        pd = Network('10.244.100.0/22'),
        av = Network('10.245.8.0/21'),
        aa = Network('10.245.68.0/22'),
        ad = Network('10.245.100.0/22'),
        tv = Network('10.245.132.0/22'),
        ta = Network('10.245.162.0/23'),
        td = Network('10.245.178.0/23'),
        dv = Network('10.245.196.0/22'),
        da = Network('10.245.226.0/23'),
        dd = Network('10.245.242.0/23'),
        mv = Network('10.244.132.0/22'),
        ma = Network('10.244.162.0/23'),
        md = Network('10.244.178.0/23'),
        il = Network('10.244.193.0/24'),
        la = Network('10.244.201.0/24'),
        lo = Network('10.244.210.0/23'),
        am = Network('10.244.226.0/23'),
        ns = Network('10.244.242.0/23')
    )
)

def getCategory():
    if verifyHostname() != 1:
        result = getHostname()[0]
        return categories[result]['name']
    else:
        return "unknown"

def getConfiguration():
    if getPlatform() == "linux":
        command = '''
        unset LIST; 
        for i in `rpm -qa | grep datacenter-config`; do 
            LIST+="`echo -n $i | sed 's/datacenter-config-//g' | sed 's/-.*//g'` ";
        done; 
        echo $LIST;
        '''
        return runCommand(command)
    elif getPlatform() == "hp-ux":
        command = '''
        unset LIST
        test -d /oracle
        if [ $? = 0 ]; then
            LIST=`echo "oracle10g $LIST "`
        fi;
        test -d /usr/sap
        if [ $? = 0 ]; then
            LIST=`echo "sapr3 $LIST "`
        fi;
        echo $LIST;
        '''
        return runCommand(command)
    elif getPlatform() == "windows":
        command = '''
        echo "unknown"
        '''
        return runCommand(command)
    else:
        return "unknown"


def getDesignation():
    if verifyHostname() != 1:
        result = getHostname()[3]
        return designations[result]
    else:
        return 'unknown'

def getHostname():
    result = socket.gethostname()
    return result

def getLocation():
    ip = socket.gethostbyname(str(getHostname()))
    #ip = socket.gethostbyname(str(getHostname() + '.mgt.dc.root.local'))
    result = "unknown"
    for location in management:
        for network in management[location]:
            if management[location][network].in_network(ip):
                result = location
    return result

def getModel():
    if getPlatform() == "linux":
        command = '''
        dmidecode -s system-product-name
        '''
        return runCommand(command)
    elif getPlatform() == "hp-ux":
        command = '''
        model
        '''
        return runCommand(command)
    elif getPlatform() == "windows":
        command = '''
        wmic computersystem GET Model
        '''
        return runCommand(command)
    else:
        return "unknown"

def getNetworkDeviceInfo():
    if getPlatform() == "linux":
        command = '''
        ip addr list
        '''
        return runCommand(command)
    elif getPlatform() == "hp-ux":
        command = '''
        lanscan
        '''
        return runCommand(command)
    elif getPlatform() == "windows":
        command = '''
        ipconfig
        '''
        return runCommand(command)
    else:
        return "unknown"

def getPlatform():
    if   sys.platform == "linux2":  
        return "linux"  
    elif sys.platform == "hp-ux11":  
        return "hp-ux" 
    elif sys.platform == "win32":  
        return "windows" 
    else:
        return "unknown"

def getSerial():
    if getPlatform() == "linux":
        command = '''
        dmidecode -s system-serial-number
        '''
        return runCommand(command)
    elif getPlatform() == "hp-ux":
        command = '''
        machinfo | grep serial | cut -d ":" -f 2
        '''
        return runCommand(command)
    elif getPlatform() == "windows":
        command = '''
        wmic bios GET SerialNumber
        '''
        return runCommand(command)
    else:
        return "unknown"

def getStorageDeviceInfo():
    if getPlatform() == "linux":
        command = '''
        vgs
        '''
        return runCommand(command)
    elif getPlatform() == "hp-ux":
        command = '''
        vgdisplay
        fcmsutil /dev/fcd0 | grep "World Wide Name"
        '''
        return runCommand(command)
    elif getPlatform() == "windows":
        command = '''
        echo "show disks and partitions"
        '''
        return runCommand(command)
    else:
        return "unknown"

def getRoutingInfo():
    if getPlatform() == "linux":
        command = '''
        route -n
        '''
        return runCommand(command)
    elif getPlatform() == "hp-ux":
        command = '''
        netstat -rn
        '''
        return runCommand(command)
    elif getPlatform() == "windows":
        command = '''
        echo "show route stuff"
        '''
        return runCommand(command)
    else:
        return "unknown"

def getVendor():
    if getPlatform() == "linux":
        command = '''
        dmidecode -s system-manufacturer
        '''
        return runCommand(command)
    elif getPlatform() == "hp-ux":
        command = '''
        echo "HP"
        '''
        return runCommand(command)
    elif getPlatform() == "windows":
        command = '''
        wmic bios GET Manufacturer
        '''
        return runCommand(command)
    else:
        return "unknown"

def runCommand(command):
    p = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    output = p.stdout.read().strip()
    return output

def verifyHostname():
    result = getHostname()
    c  = result[0]
    ee = result[1:3]
    d  = result[3]
    if c not in categories or ee not in categories['c']['members'] or d not in designations:
        return 1
    else:
        return 0


if __name__ == '__main__':
    print '~* SYSTEM INFORMATION *~'
    print 'Hostname:', getHostname()
    print 'Category:', getCategory()
    print 'Platform:', getPlatform()
    print 'Designation:', getDesignation()
    print 'Primary Location:', getLocation()
    print 'Configuration:', getConfiguration()
    print 'Vendor:', getVendor()
    print 'Model:', getModel()
    print 'Serial:', getSerial()
    print ''

    print '~* NETWORK INFORMATION *~'
    print '', getNetworkDeviceInfo()
    print ''

    print '~* ROUTING INFORMATION *~'
    print '', getRoutingInfo()
    print ''

    print '~* STORAGE INFORMATION *~'
    print '', getStorageDeviceInfo()
    print ''

    print '~* SUPPORT INFORMATION *~'
    print 'Service Level Agreement:'
    print 'Customer Contact:'
    print 'SAID Number:'
    print 'Remarks:'
