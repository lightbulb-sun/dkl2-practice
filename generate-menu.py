#!/usr/bin/python3

MENU_INPUT = 'menu.txt'
MENU_OUTPUT = 'menu.tilemap'
STRINGS_OUTPUT = 'strings.asm'

TILE_A = 0xa0
TILE_0 = 0xba
TILE_DASH = 0xca
TILE_SPACE = 0x00
TILE_PERIOD = 0xc9
TILE_APOSTROPHE = 0xc7
TILE_COLON = 0xcb
TILE_SLASH = 0xc4

COLS = 20
ROWS = 18


WORLDS = [
        "Gangplank Galleon",
        "Krem Cauldron",
        "Krazy Kremland",
        "Gloomy Gulch",
        "K.Rool's Keep",
        "The Flying Krock",
        "Lost World",
        ]

LEVELS = [
        [
            "Pirate Panic",
            "Mainbrace Mayhem",
            "Gangplank Galley",
            "Lockjaw's Locker",
            "Topsail Trouble",
            "Krow's Nest",
            ],
        [
            "Hothead Hop",
            "Kannon's Klaim",
            "Lava Lagoon",
            "Redhot Ride",
            "Squawk's Shaft",
            "Barrel Bayou",
            "Glimmer's Galleon",
            "Krockhead Klamber",
            "Rattle Battle",
            "Slime Climb",
            "Kleaver's Kiln",
            ],
        [
            "Hornet Hole",
            "Target Terror",
            "Bramble Blast",
            "Rickety Race",
            "Bramble Scramble",
            "Mudhole Marsh",
            "Rambi Rumble",
            "King Zing Sting",
            ],
        [
            "Ghostly Grove",
            "Krazy Koaster",
            "Gusty Glade",
            "Parrot Chute Panic",
            "Web Woods",
            "Kreepy Krow",
            ],
        [
            "Arctic Abyss",
            "Windy Well",
            "Dungeon Danger",
            "Clapper's Cavern",
            "Chain Link Chamber",
            "Toxic Tower",
            #"Stronghold Showdown",
            "Stronghold Showdwn",
            ],
        [
            "Screech's Sprint",
            "K.Rool Duel",
            ],
        [
            "Jungle Jinx",
            "Black Ice Battle",
            "Fiery Furnace",
            "Klobber Karnage",
            "Animal Antics",
            "Krocodile Kore",
            ],
]


def char_to_tile(char):
    o = ord(char)
    if ord('A') <= o <= ord('Z'):
        return TILE_A + o - ord('A')
    if ord('0') <= o <= ord('9'):
        return TILE_0 + o - ord('0')
    if char == ' ':
        return TILE_SPACE
    if char == '-':
        return TILE_DASH
    if char == '.':
        return TILE_PERIOD
    if char == "'":
        return TILE_APOSTROPHE
    if char == ":":
        return TILE_COLON
    if char == "/":
        return TILE_SLASH
    raise Exception(f'Unknown character: {char}')


def chars_to_asm(chars):
    arr = list(map(char_to_tile, chars.upper()))
    return 'db ' + str(len(arr)) + ', ' + ', '.join(f'${x:02x}' for x in arr)


def generate_menu(lines):
    result = bytearray()
    assert(len(lines) == ROWS)
    for line in lines:
        assert(len(line) <= COLS)
        line = f'{line:{COLS}}'
        result.extend(bytearray(map(char_to_tile, line)))
    return result


def generate_strings():
    result = []
    result.append('num_levels::')
    num_levels = '    db ' + ', '.join(f'${len(world):02x}' for world in LEVELS)
    result.append(num_levels + '\n\n')
    result.append('world_strings::')
    pointers = '    dw ' + ', '.join(f'world{n}_string' for n, _ in enumerate(WORLDS, 1))
    result.append(pointers)
    for n, world in enumerate(WORLDS, 1):
        world_text = f'{n}:{world}'
        assert(len(world_text) <= COLS)
        result.append(f'world{n}_string::')
        result.append(f'    {chars_to_asm(world_text)}')
    result.append('\n\n\nlevel_strings::')
    pointers = '    dw ' + ', '.join(f'level_strings_w{n}' for n, _ in enumerate(WORLDS, 1))
    result.append(pointers)
    for n, world in enumerate(LEVELS, 1):
        result.append(f'level_strings_w{n}::')
        pointers = '    dw ' + ', '.join(f'level_string_{n}x{m}' for m, _ in enumerate(world, 1))
        result.append(pointers)
        for m, level in enumerate(world, 1):
            x = m if m < len(world) else 'B'
            level_text = f'{x}:{level}'
            assert(len(level_text) <= COLS)
            result.append(f'level_string_{n}x{m}::')
            result.append(f'    {chars_to_asm(level_text)}')
        result.append('')
    return '\n'.join(result)


def main():
    with open(MENU_INPUT, 'r') as inf:
        lines = [line.rstrip() for line in inf]
    tilemap = generate_menu(lines)
    with open(MENU_OUTPUT, 'wb') as outf:
        outf.write(tilemap)

    strings = generate_strings()
    with open(STRINGS_OUTPUT, 'w') as outf:
        outf.write(strings)


if __name__ == '__main__':
    main()
