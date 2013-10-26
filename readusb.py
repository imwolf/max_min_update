id_to_usbport = dict();
#id_to_usbport = list();
f = open("usb_testbed")
for line in f.readlines():
	#print line,
        words = line.split()
        #print words
        if words == [] or words[0] == "Bus" or words[0] == "---":
                pass
        else:
                id_to_usbport[words[0]] = words[4]

print id_to_usbport
f.close()

        
	
