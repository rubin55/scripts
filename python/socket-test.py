import socket

#Simply change the host and port values
host = '10.10.10.1'
port = '69'

s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
try:
 s.connect((host, port))
 s.shutdown(2)
 print "Success connecting to "
 print host + " on port: " + str(port)
except:
 print "Cannot connect to "
 print host + " on port: " + str(port)
