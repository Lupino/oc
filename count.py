import sys

with open(sys.argv[1], 'r') as f:
    data = f.read()
    print(data.count('P'))
