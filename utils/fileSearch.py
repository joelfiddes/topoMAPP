import os

def search(path, file):
	fullPath = path
	inDir = os.listdir(path)

	for element in inDir:
		if os.path.join(path, file) == os.path.join(path, element):
			fullPath = os.path.join(fullPath, file)
			print(fullPath)
			return fullPath
	        
		elif os.path.isdir(os.path.join(path, element)):
			fullpath = search(os.path.join(path, element), file)
			if fullpath is not None:
				return 1
				#return fullpath