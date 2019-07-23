import json

data = json.load(open('crafting-guide.json', 'r'))

mods = data['mods']

items = []
for mod in mods:
    items += mod['items']

def get_item(items, idx):
    if not idx:
        return ''

    return items[idx]['displayName']

table = ['', '', '',
          '', '', '',
          '', '', '']

def get_3xx(items, inputs):
    v = table[:]
    v[0] = get_item(items, inputs[0])
    v[3] = get_item(items, inputs[1])
    v[6] = get_item(items, inputs[2])
    v[1] = get_item(items, inputs[3])
    v[4] = get_item(items, inputs[4])
    v[7] = get_item(items, inputs[5])
    v[2] = get_item(items, inputs[6])
    v[5] = get_item(items, inputs[7])
    v[8] = get_item(items, inputs[8])
    return v

def get_1x3(items, inputs):
    v = table[:]
    v[0] = get_item(items, inputs[0])
    v[1] = get_item(items, inputs[1])
    v[2] = get_item(items, inputs[2])

    return v

def get_2x3(items, inputs):
    v = table[:]
    v[0] = get_item(items, inputs[0])
    v[1] = get_item(items, inputs[1])
    v[2] = get_item(items, inputs[2])

    v[3] = get_item(items, inputs[3])
    v[4] = get_item(items, inputs[4])
    v[5] = get_item(items, inputs[5])

    return v

def get_2x2(items, inputs):
    v = table[:]
    v[0] = get_item(items, inputs[0])
    v[3] = get_item(items, inputs[1])
    v[1] = get_item(items, inputs[2])
    v[4] = get_item(items, inputs[3])

    return v

def get_2x1(items, inputs):
    v = table[:]
    v[0] = get_item(items, inputs[0])
    v[1] = get_item(items, inputs[1])

    return v

def get_1x1(items, inputs):
    v = table[:]
    v[0] = get_item(items, inputs[0])

    return v

def get_1x2(items, inputs):
    v = table[:]
    v[0] = get_item(items, inputs[0])
    v[3] = get_item(items, inputs[1])

    return v

craftTables = {}

for item in items:
    if item.get('recipes'):
        for recipe in item['recipes']:
            if recipe.get('tools'):
                try:
                    if recipe['tools'].index(101) > -1:
                        if recipe['width'] == 3:
                            craftTables[item['displayName']] = get_3xx(items, recipe['inputs'])
                        elif recipe['width'] == 1 and recipe['height'] == 3:
                            craftTables[item['displayName']] = get_1x3(items, recipe['inputs'])
                        elif recipe['width'] == 2 and recipe['height'] == 3:
                            craftTables[item['displayName']] = get_2x3(items, recipe['inputs'])
                except ValueError:
                    pass
                except Exception as e:
                    pass
                    # print('Error: ', recipe, e)
            else:
                try:
                    if recipe['width'] == 2 and recipe['height'] == 2:
                        craftTables[item['displayName']] = get_2x2(items, recipe['inputs'])
                    elif recipe['width'] == 2 and recipe['height'] == 1:
                        craftTables[item['displayName']] = get_2x1(items, recipe['inputs'])
                    elif recipe['width'] == 1 and recipe['height'] == 1:
                        craftTables[item['displayName']] = get_1x1(items, recipe['inputs'])
                    elif recipe['width'] == 1 and recipe['height'] == 2:
                        craftTables[item['displayName']] = get_1x2(items, recipe['inputs'])
                except Exception as e:
                    pass
                    # print('Error: ', item['displayName'], recipe, e)

# print(json.dumps(craftTables, indent=2))

# Advanced Solar Panels
# AgriCraft
# Applied Energistics 2
# Big Reactors
# BuildCraft
# Computer Craft
# Draconic Evolution
# Ender Storage
# EnderIO
# Extra Cells
# Extra Utilities
# Forestry
# Forge Multipart
# Galacticraft
# Hydraulicraft
# IC2 Classic
# Iron Chests
# JABBA
# Logistics Pipes
# Mekanism
# MineFactory Reloaded
# Modular PowerSuits
# ProjectRed
# Quantum Flux
# Redstone Arsenal
# Simply Jetpacks
# Solar Expansion
# Solar Flux
# Steve's Factory Manager
# Storage Drawers
# Thermal Dynamics
# Thermal Expansion
# Thermal Foundation
# Tinker's Construct

# Railcraft
# Minecraft
# Industrial Craft 2
# OpenComputers

def update(name):
    if name == 'Printed Circuit Board':
        return name + ' (PCB)'
    if name == 'Electronic Circuit':
        return 'Basic Control Circuit'
    return name

got = ['Railcraft', 'Minecraft', 'Industrial Craft 2', 'OpenComputers', 'Mekanism']

gotItems = []

for mod in mods:
    if mod['displayName'] in got:
        for item in mod['items']:
            gotItems.append(item['displayName'])

for k, v in craftTables.items():
    if k in gotItems:
        print('craftTables["' + update(k) + '"] = {"' + '", "'.join([update(vv) for vv in v]) + '"}')
