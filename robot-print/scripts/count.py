import sys
import math

with open(sys.argv[1], 'r') as f:
    data = f.read()
    count = data.count('P')

    print('Total: {}'.format(count))
    print('Need: {} * 64'.format(math.ceil(count / 64)))
    print('IU: {} * 64 * 16'.format(math.ceil(count / 64 / 16)))
