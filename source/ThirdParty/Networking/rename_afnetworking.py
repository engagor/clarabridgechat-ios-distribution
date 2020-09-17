import fileinput
import glob
import string
import pprint
import sys
import re
import os

# First gather all class names from the filenames
files = glob.glob('AF*')
classes = [];
for file in files:
	classname = file.split('.')[0]
	if not classname in classes:
		classes.append(classname)
pprint.pprint(classes)

# Replace them for their 'SK' equivalent
for classname in classes:
	rtext = 'CLB' + classname
	print 'Replacing ' + classname + ' by ' + rtext
	for file in files:
		for line in fileinput.input(file, inplace=1):
			lineno = string.find(line, classname)
  			if lineno >0:
				line = re.sub(r'\b%s\b' % classname, rtext, line)
			sys.stdout.write(line)

# Replace remaining keywords starting with 'AF' i.e. classes not in their own file
for file in files:
	for line in fileinput.input(file, inplace=1):
		match = re.search(r'\bAF\w*\b', line)
		while match and not match.group(0) == 'AF_INET':
			line = re.sub(match.group(0), 'CLB' + match.group(0), line)
			match = re.search(r'\bAF\w*\b', line)
		sys.stdout.write(line)

# Replace constants starting with 'kAF'
for file in files:
	for line in fileinput.input(file, inplace=1):
		match = re.search(r'\bkAF\w*\b', line)
		while match:
			line = re.sub(match.group(0), 'kCLB' + match.group(0), line)
			match = re.search(r'\bkAF\w*\b', line)
		sys.stdout.write(line)

# Replace preprocessor keywords starting with '_AF'
for file in files:
	for line in fileinput.input(file, inplace=1):
		match = re.search(r'\b_AF\w*\b', line)
		if match:
			line = re.sub(match.group(0), '_CLB' + match.group(0), line)
		sys.stdout.write(line)

for file in files:
	os.rename(file, 'CLB' + file)
