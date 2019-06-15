def toLayer(s):
    layer = []
    for line in s.split('\n'):
        line = line.strip()
        if line.startswith('#'):
            continue
        if not line:
            continue
        layer.append(line)

    return layer

def loadLayers(fn):
    layers = []
    with open(fn, 'r') as f:
        data = f.read().strip()

        while True:
            idx = data.find('\n\n')
            if idx == -1:
                break
            layers.append(toLayer(data[:idx]))
            data = data[idx+2:]

        data = data.strip()
        if data:
            layers.append(toLayer(data))

    return layers

def toV(layers):
    size = len(layers[0])

    for layer in layers:
        layer.reverse()

    newLayers = []
    for i in range(0, size):
        newLayer = []
        for layer in layers:
            newLayer.append(layer[i])
        newLayers.append(newLayer)

    return newLayers

def writeLayers(fn, layers):
    with open(fn, 'w') as f:
        for layer in layers:
            for line in layer:
                f.write(line)
                f.write('\n')
            f.write('\n')

if __name__ =='__main__':
    import sys
    layers = loadLayers(sys.argv[1])
    newLayers = toV(layers)

    writeLayers(sys.argv[1] + '.v', newLayers)
