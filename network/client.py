import requests
from urllib.parse import urlencode
import os
import json
import re
import sqlite3
from collections import defaultdict
import math

from crafttables import craftTables

maxCraftCount = {}
maxCraftCount['Forge Hammer'] = 1
maxCraftCount['Cutter'] = 1

label_map = {}

re_key = re.compile('([^{=,]+=)')
def parse_table(s):
    keys = re_key.findall(s)

    for key in keys:
        new_key = '"{}":'.format(key[:-1])

        s = s.replace(key, new_key)

    return json.loads(s)


class Client(object):
    def __init__(self, host, uuid):
        self.host = host
        self.uuid = uuid

    def api(self, cmd, query=None):
        url = '{}/api/{}/{}/'.format(self.host, cmd, self.uuid)
        if query:
            url = '{}?{}'.format(url, urlencode(query))

        return url

    def run(self, data, show=True):
        rsp = requests.post(self.api('run'), data=data)

        if show:
            print(rsp.text)
        else:
            data = rsp.text

            if data == 'nil':
                return None

            return parse_table(data)

    def upload(self, data, filename, append=False, show=True):
        cmd = 'append' if append else 'upload'
        rsp = requests.put(self.api(cmd, {'fileName': filename}), data=data)
        if show:
            print(rsp.text)
        else:
            return rsp.text

    def uploadWith(self, fn, filename=None, show=True):
        data = open(fn, 'r').read()
        batch_size = 10240  # 10k
        if filename is None:
            filename = os.path.basename(fn)
        ret = self.upload(data[:batch_size], filename, False, show)
        while True:
            data = data[batch_size:]
            if not data:
                break
            self.upload(data[:batch_size], filename, True, True)

        return ret

    def download(self, filename, show=True):
        rsp = requests.get(self.api('download', {'fileName': filename}))
        if show:
            print(rsp.text)
        else:
            return rsp.text

    def end(self, show=True):
        rsp = requests.post(self.api('end'))
        if show:
            print(rsp.text)
        else:
            return rsp.text

    @property
    def robot(self):
        return Module(self, 'robot')

    @property
    def computer(self):
        return Module(self, 'computer')

    @property
    def inventory_controller(self):
        return Module(self, 'inventory_controller', True)

    @property
    def crafting(self):
        return Module(self, 'crafting', True)

    @property
    def craft(self):
        return Craft(self)

class Module(object):
    def __init__(self, client, module, component=False):
        self.client = client
        self.module = module
        self.component = component

    def get_func(self, func):
        def run(*args):
            if self.component:
                code = gen_component_code(self.module, func, *args)
            else:
                code = gen_module_code(self.module, func, *args)
            print(code)
            return self.client.run(code, False)

        return run

    def __getattr__(self, func):
        return self.get_func(func)


class Component(object):
    def __init__(self, client, component):
        self.client = client
        self.component = component


def encode(arg):
    if isinstance(arg, str):
        return '"{}"'.format(arg)
    return str(arg)


def gen_module_code(module, func, *args):
    return '''
local {module} = require('{module}')
local serialization = require('serialization')
return serialization.serialize({module}.{func}({args}))
    '''.format(module=module,
               func=func,
               args=', '.join([encode(arg) for arg in args]))

def gen_component_code(component, func, *args):
    return '''
local component = require('component')
local serialization = require('serialization')
return serialization.serialize(component.{component}.{func}({args}))
    '''.format(component=component,
               func=func,
               args=', '.join([encode(arg) for arg in args]))


def normal(label):
    if label.find('Planks') > -1:
        return 'Planks'
    if label.find('Wood') > -1:
        return 'Wood'
    return label

def get_label(item):
    if item is None:
        return ''
    label = item.get('label', '')

    if label == 'Clay':
        return item['name']

    return normal(label)

class Craft(object):
    def __init__(self, client, db_path='data.db'):
        self.craft_table = [1, 2, 3, 5, 6, 7, 9, 10, 11]
        self.sides = [0, 1, 3] # down, up, forward

        self.robot = client.robot
        self.ic = client.inventory_controller
        self.crafting_lib = client.crafting

        self.max_slot = int(self.robot.inventorySize())

        self.conn = sqlite3.connect(db_path)
        self.create_table()

    def create_table(self):
        self.conn.execute('''
            CREATE TABLE IF NOT EXISTS items (
                side INTEGER,
                slot INTEGER,
                label CHAR(256),
                name CHAR(256),
                size INTEGER,
                maxSize INTEGER,
                PRIMARY KEY (side, slot)
            )''')

        self.conn.execute('''
            CREATE TABLE IF NOT EXISTS craft_tables (
                label CHAR(256),
                items TEXT,
                PRIMARY KEY (label)
            )''')

        self.conn.commit()

    def get_craft_table(self, label):
        cur = self.conn.cursor()

        cur.execute('SELECT items FROM craft_tables WHERE label = ?', (label, ))
        r = cur.fetchone()

        cur.close()

        if r:
            return json.loads(r[0])
        return None


    def save_craft_table(self, label, items):
        old = self.get_craft_table(label)

        cur = self.conn.cursor()

        if old is None:
            cur.execute('''INSERT INTO craft_tables (label, items) VALUES (?, ?)''', (label, json.dumps(items)))
        else:
            cur.execute('''UPDATE craft_tables set items = ? WHERE label = ?''', (json.dumps(items), label))

        cur.close()
        self.conn.commit()


    def delete_craft_table(self, label):
        cur = self.conn.cursor()
        cur.execute('''DELETE items WHERE label = ?''', (label, ))
        cur.close()
        self.conn.commit()

    def get_item_size(self, side, slot, default = 0):
        cur = self.conn.cursor()

        cur.execute('SELECT size FROM items WHERE side = ? AND slot = ?', (side, slot))
        r = cur.fetchone()

        cur.close()

        if r:
            return r[0]
        return default

    def save_item(self, side, slot, item):
        item_size = self.get_item_size(side, slot, None)

        item = item or {}

        label = get_label(item)
        name = item.get('name', '')
        size = int(item.get('size', 0))
        maxSize = int(item.get('maxSize', 0))

        cur = self.conn.cursor()

        if item_size is None:
            cur.execute('''INSERT INTO items (side, slot, label, name, size, maxSize) VALUES (?, ?, ?, ?, ?, ?)''', (side, slot, label, name, size, maxSize))
        else:
            cur.execute('''UPDATE items set label = ?, name = ?, size = ?, maxSize = ? WHERE side = ? AND slot = ?''', (label, name, size, maxSize, side, slot))

        cur.close()
        self.conn.commit()

    def find_empty_slot(self, side):
        slot = 0

        if side == -1:
            item_size = self.get_item_size(-1, 4)
            if item_size == 0:
                return 4

            item_size = self.get_item_size(-1, 8)
            if item_size == 0:
                return 8

            slot = 12

        cur = self.conn.cursor()

        cur.execute('SELECT slot FROM items WHERE side = ? AND size = 0 AND slot >= ?', (side, slot))
        r = cur.fetchone()

        cur.close()

        if r:
            return r[0]
        return None

    def find_item_slot(self, side, label, slot = 0):
        ret = []
        if side == -1 and slot == 0:
            item_size = self.get_item_size(-1, 4)
            if item_size > 0:
                item = self.ic.getStackInInternalSlot(4)
                if get_label(item) == label:
                    ret.append(4)

            item_size = self.get_item_size(-1, 8)
            if item_size > 0:
                item = self.ic.getStackInInternalSlot(8)
                if get_label(item) == label:
                    ret.append(8)

            slot = 12
        cur = self.conn.cursor()

        cur.execute('SELECT slot FROM items WHERE side = ? AND slot >= ? AND label = ? AND size > 0', (side, slot, label))
        r = cur.fetchall()

        cur.close()

        return ret + [v[0] for v in r]

    def find_not_full_item_slot(self, side):
        cur = self.conn.cursor()

        cur.execute('SELECT label, slot FROM items WHERE side = ? AND size > 0 AND size < maxSize', (side, ))
        r = cur.fetchall()

        cur.close()

        ret = defaultdict(list)

        for v in r:
            ret[v[0]].append(v[1])

        return ret

    def find_full_item_slot(self, side):
        cur = self.conn.cursor()

        cur.execute('SELECT label, slot FROM items WHERE side = ? AND size > 0 AND size == maxSize', (side, ))
        r = cur.fetchall()

        cur.close()

        ret = defaultdict(list)

        for v in r:
            ret[v[0]].append(v[1])

        return ret

    def remove_slot(self, side, slot):
        self.conn.execute('DELETE FROM items WHERE side = ? AND slot = ?', (side, slot))
        self.conn.commit()

    def update_slot_info(self, side, side_slot, *slots):
        if side == -1:
            item = self.ic.getStackInInternalSlot(side_slot)
        else:
            item = self.ic.getStackInSlot(side, side_slot)

        self.save_item(side, side_slot, item)

        for slot in slots:
            item = self.ic.getStackInInternalSlot(slot)
            self.save_item(-1, slot, item)

    def suck_from_slot(self, side, slot):
        new_slot = self.find_empty_slot(-1)
        if new_slot is None:
            return False

        self.robot.select(new_slot)
        self.ic.suckFromSlot(side, slot)

        self.update_slot_info(side, slot, new_slot)

        return new_slot

    def drop_into_slot(self, slot):
        self.robot.select(slot)
        for side in self.sides:
            new_slot = self.find_empty_slot(side)
            if new_slot is not None:
                self.ic.dropIntoSlot(side, new_slot)
                self.update_slot_info(side, new_slot, slot)
                return True

        return False

    def transfer_to(self, from_slot, to_slot, *args):
        self.robot.select(from_slot)
        self.robot.transferTo(to_slot, *args)

        self.update_slot_info(-1, from_slot, to_slot)

    def clean_full_slots(self):
        item_slots = self.find_full_item_slot(-1)
        for slots in item_slots.values():
            for slot in slots:
                self.drop_into_slot(slot)

    def clean_slots(self):
        item_slots = self.find_not_full_item_slot(-1)
        for slots in item_slots.values():
            for slot in slots:
                self.drop_into_slot(slot)

        self.clean_full_slots()

    def make_craft_slots(self):
        for slot in self.craft_table:
            item_size = self.get_item_size(-1, slot)
            if item_size == 0:
                continue

            new_slot = self.find_empty_slot(-1)
            if new_slot is None:
                self.merge_items()
                new_slot = self.find_empty_slot(-1)
                if new_slot is None:
                    self.clean_full_slots()
                    new_slot = self.find_empty_slot(-1)
                    if new_slot is None:
                        self.clean_slots()
                        new_slot = self.find_empty_slot(-1)
                        if new_slot is None:
                            return False

            self.transfer_to(slot, new_slot)

        return True

    def merge_items(self, side = -1):
        item_slots = self.find_not_full_item_slot(side)

        for slots in item_slots.values():
            if len(slots) < 2:
                continue

            length = len(slots)
            tmp_slot = None
            for i in range(length - 1):
                slot_to = slots[i]
                item_size = self.get_item_size(side, slot_to)
                if item_size == 0:
                    continue

                for j in range(i + 1, length):
                    slot_from = slots[j]
                    if side == -1:
                        self.transfer_to(slot_from, slot_to)
                    else:
                        if not tmp_slot:
                            tmp_slot = self.suck_from_slot(side, slot_from)
                            if not tmp_slot:
                                self.merge_items()
                                self.clean_full_slots()
                                tmp_slot = self.suck_from_slot(side, slot_from)
                                if tmp_slot is None:
                                    return False

                        self.robot.select(tmp_slot)
                        self.ic.dropIntoSlot(side, slot_to)
                        self.update_slot_info(side, slot_to, tmp_slot)

                        tmp_slot_size = self.get_item_size(-1, tmp_slot)
                        if tmp_slot_size == 0:
                            tmp_slot = None

                    item_size = self.get_item_size(side, slot_from)

                    if item_size > 0:
                        break

    def merge_all_items(self):

        not_full_item_slots = defaultdict(list)

        item_slots = self.find_not_full_item_slot(-1)
        for item, slots in item_slots.items():
            for slot in slots:
                not_full_item_slots[item].append((-1, slot))

        for side in self.sides:
            item_slots = self.find_not_full_item_slot(side)
            for item, slots in item_slots.items():
                for slot in slots:
                    not_full_item_slots[item].append((side, slot))

        for slots in not_full_item_slots.values():
            if len(slots) < 2:
                continue

            length = len(slots)
            tmp_slot = None

            for i in range(length - 1):
                side_to, slot_to = slots[i]
                item_size = self.get_item_size(side_to, slot_to)
                if item_size == 0:
                    continue

                for j in range(i + 1, length):
                    side_from, slot_from = slots[j]
                    if side_from == -1 and side_to == -1:
                        self.transfer_to(slot_from, slot_to)
                    elif side_from == -1:
                        self.robot.select(slot_from)
                        self.ic.dropIntoSlot(side_to, slot_to)
                        self.update_slot_info(side_to, slot_to, slot_from)
                    elif side_to == -1:
                        if not tmp_slot:
                            tmp_slot = self.suck_from_slot(side_from, slot_from)
                            if not tmp_slot:
                                self.merge_items()
                                self.clean_full_slots()
                                tmp_slot = self.suck_from_slot(side_from, slot_from)
                                if tmp_slot is None:
                                    return False

                        self.transfer_to(tmp_slot, slot_to)
                        tmp_slot_size = self.get_item_size(-1, tmp_slot)
                        if tmp_slot_size == 0:
                            tmp_slot = None
                    else:
                        if not tmp_slot:
                            tmp_slot = self.suck_from_slot(side_from, slot_from)
                            if not tmp_slot:
                                self.merge_items()
                                self.clean_full_slots()
                                tmp_slot = self.suck_from_slot(side_from, slot_from)
                                if tmp_slot is None:
                                    return False

                        self.robot.select(tmp_slot)
                        self.ic.dropIntoSlot(side_to, slot_to)
                        self.update_slot_info(side_to, slot_to, tmp_slot)

                        tmp_slot_size = self.get_item_size(-1, tmp_slot)
                        if tmp_slot_size == 0:
                            tmp_slot = None

                    item_size = self.get_item_size(side_from, slot_from)

                    if item_size > 0:
                        break

    def quick_scan(self, slots=16):
        for slot in range(slots):
            item = self.ic.getStackInInternalSlot(slot + 1)
            self.save_item(-1, slot + 1, item)

    def scan(self):
        self.quick_scan(self.max_slot)

        for side in self.sides:
            max = int(self.ic.getInventorySize(side))
            for slot in range(max):
                item = self.ic.getStackInSlot(side, slot + 1)
                self.save_item(side, slot + 1, item)

    def run_crafting(self, items, total=1, item_label=''):
        if len(items) != 9:
            print('crafting failed', items)
            return False, '', 0

        if not self.make_craft_slots():
            return False, '', 0

        item_slots = defaultdict(list)

        for idx, item in enumerate(items):
            if item:
                item_slots[item].append(idx)

        for item, slots in item_slots.items():
            count = len(slots)
            while True:
                size = 0
                found_slots = self.find_item_slot(-1, item)
                for slot in found_slots:
                    size += self.get_item_size(-1, slot)

                if size >= count:
                    part_size = math.floor(size / count)
                    if part_size > 64:
                        part_size = 64

                    part_size = min(part_size, total)
                    for i in slots:
                        to_slot = self.craft_table[i]
                        from_slot = 0
                        while True:
                            if len(found_slots) == 0:
                                break

                            to_size = self.get_item_size(-1, to_slot)

                            if to_size >= part_size:
                                break

                            from_slot = found_slots.pop()

                            self.transfer_to(from_slot, to_slot, part_size)

                            to_size1 = self.get_item_size(-1, to_slot)

                            if to_size == to_size1:
                                break

                            from_size = self.get_item_size(-1, from_slot)

                            if from_size > 0:
                                found_slots.append(from_slot)
                                from_slot = 0

                        if from_slot > 0:
                            from_size = self.get_item_size(-1, from_slot)

                            if from_size > 0:
                                found_slots.append(from_slot)
                                from_slot = 0
                    break
                else:
                    for side in self.sides:
                        found_slots = self.find_item_slot(side, item)

                        for slot in found_slots:
                            size1 = self.get_item_size(side, slot)
                            if not self.suck_from_slot(side, slot):
                                self.merge_items()
                                if not self.suck_from_slot(side, slot):
                                    break

                            size += size1

                        if size >= count:
                            break

                    if size < count:
                        return False, item, (count - size) * total

        return self.do_craft(items, total, item_label)

    def do_craft(self, items = None, total = 1, item_label = ''):
        out_slot = self.find_empty_slot(-1)
        if out_slot is None:
            self.clean_full_slots()
            out_slot = self.find_empty_slot(-1)
            if out_slot is None:
                return False, '', 0

        self.robot.select(out_slot)
        self.crafting_lib.craft(total)

        info = self.ic.getStackInInternalSlot(out_slot)

        label = get_label(info)

        if item_label and label != item_label:
            label_map[item_label] = label
            self.delete_craft_table(item_label)

        if items is None:
            items = []
            for slot in self.craft_table:
                info = self.ic.getStackInInternalSlot(out_slot)
                items.append(get_label(info))

        self.save_craft_table(label, items)

        self.update_slot_info(-1, out_slot, *self.craft_table)

        return True, '', 0


    def count_items(self, item):
        size = 0

        for side in self.sides:
            found_slots = self.find_item_slot(side, item)
            for slot in found_slots:
                size += self.get_item_size(side, slot)
        found_slots = self.find_item_slot(-1, item, 1)
        for slot in found_slots:
            size += self.get_item_size(-1, slot)

        return size


    def run_craft(self, item, count):
        if maxCraftCount.get(item):
            count = maxCraftCount['item']

        if label_map.get(item):
            item = label_map[item]

        print('run_craft', item, count)
        items = self.get_craft_table(item)

        if not items:
            items = craftTables.get(item)
            if not items:
                print('not fount craftable:', item)
                return False

        self.merge_items()
        ret, needName, needCount = self.run_crafting(items, count, item)

        if ret:
            return True

        if needName:
            ret = self.run_craft(needName, needCount)
            if ret:
                return self.run_craft(item, count)

        return False


    def crafting(self, item, total=1, scan_size = 16):
        self.quick_scan(scan_size)
        size = 0
        have = self.count_items(item)
        total = have + total
        print(have, total)

        while True:
            size = total - have

            if size > 64:
                size = 64

            running = self.run_craft(item, size)
            if not running:
                self.clean_slots()
                running = self.run_craft(item, size)

            if not running:
                print('craft failed')
                break

            have = self.count_items(item)
            print(have, total)

            if have >= total:
                print('crafted')
                break


# def craft_microcontroller():
#     craft.crafting('Microcontroller Case (Tier 1)', 1)
#     craft.crafting('Central Processing Unit (CPU) (Tier 1)', 1)
#     craft.crafting('Memory (Tier 1.5)', 1)
#     craft.crafting('EEPROM', 1)
#     craft.crafting('Redstone Card (Tier 1)', 1)


if __name__ == '__main__':
    client = Client('http://example.com', 'my-uuid')

    craft = client.craft

    # craft.scan()
    # craft.merge_items()
    # craft.clean_slots()
    # craft.merge_all_items()
    # craft.crafting('Microchip (Tier 1)', 1)
    # craft.do_craft()
    # craft.crafting('Advanced Bin', 1)
    # craft.crafting('Ultimate Bin', 1)
    # print(client.inventory_controller.getStackInInternalSlot(1))
    # craft.crafting('Ultimate Logistical Transporter', 1)
    # craft.crafting('Energy Tablet', 1)
    # craft.crafting('Computer Case (Tier 1)', 1)

    # craft.crafting('Microcontroller Case (Tier 1)', 1)
    # craft.crafting('Central Processing Unit (CPU) (Tier 1)', 1)
    # craft.crafting('Memory (Tier 1.5)', 1)
    # craft.crafting('EEPROM', 1)
    # craft.crafting('Redstone Card (Tier 1)', 1)

    # craft.crafting('EEPROM', 1)
    # craft.crafting('Internet Card', 1)

    # client.uploadWith('./remote-control-client.lua')
    # client.end()

    # craft.crafting('Computer Case (Tier 3)', 1)
    # craft.crafting('Accelerated Processing Unit (APU) (Tier 3)', 1)
    # craft.crafting('Internet Card', 1)
    craft.crafting('Memory (Tier 3.5)', 2)
    # craft.crafting('Screen (Tier 3)', 1)
