import os,re

class storage:

   def _lunError(self, symmetrix, device, lun):
      output = ''
      output += "Lun not present for symmetrix device " + symmetrix + ", skipping %X" % lun + ":" + device + "\n"
      return output

   def Luns(self):
      lunList = []
      pseudoList = []
      pseudoLunDict = {}
      pseudoName = None
      lunName = None
      pseudore = re.compile(r'Pseudo name=(.+)$')
      lunre = re.compile(r'Logical device ID=(.+)$')
      devicere = re.compile(r'Symmetrix ID=(.+)$')
      p = os.popen("powermt display dev=all")
      for line in p:
         device = devicere.match(line)
         pseudo = pseudore.match(line)
         if device != None:
            deviceName = device.group(1)
         if pseudo != None:
            pseudoName = pseudo.group(1)
            pseudoList.append(pseudoName)
         else:
            lun = lunre.match(line)
            if lun != None:
               lunName = lun.group(1)
               lunList.append(int(lunName, 16))
               pseudoLunDict[deviceName, int(lunName, 16)] = pseudoName
               lunName = None
               psuedoName = None
               deviceName = None
      return(pseudoLunDict, lunList, pseudoList)

   def DeviceUdev(self, device):
      output = ''
      udevre = re.compile(r'KERNEL=="' + device + '\d",  SYMLINK="(.+dsk0\d.)".+$')
      p = os.popen("grep " + device + " /etc/udev/rules.d/*orarac*")
      for line in p:
         udevMatch = udevre.match(line)
         if udevMatch != None:
            output += udevMatch.group(1) + "::"
      return output

   def DeviceSize(self, device):
      output = ''
      sizere = re.compile(r'Disk ' + device + ': (.+)$')
      p = os.popen("parted " + device + " print | grep Disk")
      for line in p:
         sizeMatch = sizere.match(line)
         if sizeMatch != None:
            output += sizeMatch.group(1)
      return output

   def FreePseudo(self):
      pseudoList = []
      pseudore = re.compile(r'.+(emcpower\S\S\S?).+$')
      p = os.popen("emcpadm getfreepseudos -n 100")
      for line in p:
         pseudo = pseudore.match(line)
         if pseudo != None:
            pseudoList.append(pseudo.group(1))
      return pseudoList

   def PseudoPossibilities(self):
        pseudoPossibilities = []
        z = letterSeq = [ "%c" % (x) for x in range(ord('a'), ord('z')+1)]
        y = twoLetterSeq = [ "%c%c" % (x, y) for x in range(ord('a'), ord('z')+1) for y in range(ord('a'), ord('z')+1)]
        pseudoPossibilities = z+y
        return pseudoPossibilities

   def RealLuns(self, lunList, pseudoLunDict, pseudoPossibilities, deviceEQ, deviceTC, _sleep):
        output = ''
        x=0
        for lun in lunList:
                if pseudoLunDict.has_key((deviceEQ, lun)):
                        output += "emcpadm renamepseudo -s " + pseudoLunDict[deviceEQ, lun] + " -t emcpower" + pseudoPossibilities[x] + "\n"
                        if _sleep!=0:
                                output += "sleep 2" + "\n"
                        x = x+1
                else:
                        output += self._lunError(deviceEQ, pseudoLunDict[deviceTC, lun], lun)
                if pseudoLunDict.has_key((deviceTC, lun)):
                        output += "emcpadm renamepseudo -s " + pseudoLunDict[deviceTC, lun] + " -t emcpower" + pseudoPossibilities[x] + "\n"
                        if _sleep!=0:
                                output += "sleep 2" + "\n"
                        x = x+1
                else:
                        output += self._lunError(deviceTC, pseudoLunDict[deviceEQ, lun], lun)
        return output

   def FreeLuns(self, lunList, pseudoLunDict, pseudoFree, deviceEQ, deviceTC, _sleep):
        output = ''
        x=0
        for lun in lunList:
                if pseudoLunDict.has_key((deviceEQ, lun)):
                        output += "emcpadm renamepseudo -s " + pseudoLunDict[deviceEQ, lun] + " -t " + pseudoFree[x] + "\n"
                        if _sleep!=0:
                                output += "sleep 2" + "\n"
                        x = x+1
                else:
                        output += self._lunError(deviceEQ, pseudoLunDict[deviceTC, lun], lun)
                if pseudoLunDict.has_key((deviceTC, lun)):
                        output += "emcpadm renamepseudo -s " + pseudoLunDict[deviceTC, lun] + " -t " + pseudoFree[x] + "\n"
                        if _sleep!=0:
                                output += "sleep 2" + "\n"
                        x = x+1
                else:
                        output += self._lunError(deviceTC, pseudoLunDict[deviceEQ, lun], lun)
        return output

   def Munin(self, lunList, pseudoLunDict, deviceEQ, deviceTC):
      output = ''
      for i in lunList:
         if pseudoLunDict.has_key((deviceEQ, i)):
            output += "ln -s /etc/munin/custom-plugins/iostat2 /etc/munin/plugins/iostat2_" + pseudoLunDict[deviceEQ, i] + "\n"
         if pseudoLunDict.has_key((deviceTC, i)):
            output += "ln -s /etc/munin/custom-plugins/iostat2 /etc/munin/plugins/iostat2_" + pseudoLunDict[deviceTC, i] + "\n"
      return output

   def Csv(self, lunList, pseudoLunDict, deviceEQ, deviceTC):
      output = ''
      for i in lunList:
         if pseudoLunDict.has_key((deviceEQ, i)):
            output += deviceEQ + "," + str(i) + "," + hex(i) + "," + pseudoLunDict[deviceEQ, i] + "," + self.DeviceSize("/dev/" + pseudoLunDict[deviceEQ, i]) + "," + self.DeviceUdev(pseudoLunDict[deviceEQ, i]) + "\n"
         if pseudoLunDict.has_key((deviceTC, i)):
            output += deviceTC + "," + str(i) + "," + hex(i) + "," + pseudoLunDict[deviceTC, i] + "," + self.DeviceSize("/dev/" + pseudoLunDict[deviceTC, i]) + "," + self.DeviceUdev(pseudoLunDict[deviceTC, i]) + "\n"
      return output
