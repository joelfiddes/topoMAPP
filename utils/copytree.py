#!/usr/bin/env python
import os
import shutil

# def main(src, dst, symlinks=False, ignore=None):
#     """Main entry point for the script."""
#     copytree(src, dst, symlinks=False, ignore=None)

def copytree(src, dst, symlinks=False, ignore=None):
    for item in os.listdir(src):
        s = os.path.join(src, item)
        d = os.path.join(dst, item)
        if os.path.isdir(s):
            shutil.copytree(s, d, symlinks, ignore)
        else:
            shutil.copy2(s, d)


#             # calling main
# if __name__ == '__main__':
#     import sys
#     src           = sys.argv[1]
#     dst         = sys.argv[2]
#     symlinks   = sys.argv[3]
#     ignore   = sys.argv[4]

#     main(src, dst, symlinks, ignore)