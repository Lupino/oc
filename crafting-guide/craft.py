import json

from crafttables import craftTables as origin_craft_tables

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
    v[3] = get_item(items, inputs[1])
    v[6] = get_item(items, inputs[2])

    v[1] = get_item(items, inputs[3])
    v[4] = get_item(items, inputs[4])
    v[7] = get_item(items, inputs[5])

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

name_map = {
    'Printed Circuit Board': 'Printed Circuit Board (PCB)',
    'Electronic Circuit': 'Basic Control Circuit',
    'Advanced Circuit': 'Advanced Control Circuit',
    'Empty Cell': 'Universal Fluid Cell',
    'Coolant Cell': 'Universal Fluid Cell',
    'Insulated Gold Cable': '2x Ins. Gold Cable',
    'Hard Disk Drive (Tier 1)': 'Hard Disk Drive (Tier 1) (1MB)',
    'Hard Disk Drive (Tier 2)': 'Hard Disk Drive (Tier 2) (2MB)',
    'Hard Disk Drive (Tier 3)': 'Hard Disk Drive (Tier 3) (4MB)',
}

def update(name):

    new_name = name_map.get(name, None)
    if new_name:
        return new_name

    if name.find('Planks') > -1:
        return 'Planks'
    if name.find('Wood') > -1:
        return 'Wood'
    return name

ignore = ['Electronic Circuit', 'Basic Control Circuit']
needed = ['Block of Chamelium', 'Block of Coal']


got = ['Minecraft', 'Industrial Craft 2', 'OpenComputers', 'Mekanism']

gotItems = []

for mod in mods:
    if mod['displayName'] in got:
        for item in mod['items']:
            gotItems.append(item['displayName'])

got_craftTables = {}

for k, v in craftTables.items():
    if k in gotItems:
        got_craftTables[update(k)] = [update(vv) for vv in v]

got_craftTables.update(origin_craft_tables)
# got_craftTables = origin_craft_tables

print('craftTables = {}')
for k, v in sorted(list(got_craftTables.items()), key=lambda x: x[0]):
    if k.find('Block of') > -1:
        if k not in needed:
            continue

    if k in ignore:
        continue

    print('craftTables["' + k + '"] = ["' + '", "'.join(v) + '"]')

print('return craftTables')
