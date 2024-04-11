import sys
import os.path
from nbt import nbt 

TAG_END = 0
TAG_BYTE = 1
TAG_SHORT = 2
TAG_INT = 3
TAG_LONG = 4
TAG_FLOAT = 5
TAG_DOUBLE = 6
TAG_BYTE_ARRAY = 7
TAG_STRING = 8
TAG_LIST = 9
TAG_COMPOUND = 10
TAG_INT_ARRAY = 11
TAG_LONG_ARRAY = 12

def nbt2lua(tag, do_indent=True, indentation=0):
    indent_str = ' ' * indentation if do_indent else ''
    tag_type = tag.id

    if tag_type == TAG_END:
        return 'nil'
    elif tag_type == TAG_BYTE:
        return str(tag.value) + 'b'
    elif tag_type == TAG_SHORT:
        return str(tag.value) + 's'
    elif tag_type == TAG_INT:
        return str(tag.value)
    elif tag_type == TAG_LONG:
        return str(tag.value) + 'L'
    elif tag_type == TAG_FLOAT:
        return str(tag.value) + 'f'
    elif tag_type == TAG_DOUBLE:
        return str(tag.value)
    elif tag_type == TAG_BYTE_ARRAY:
        return '{' + ', '.join(str(x) + 'b' for x in tag) + '}'
    elif tag_type == TAG_STRING:
        return '"' + tag.value.replace('"', '\\"') + '"'
    elif tag_type == TAG_LIST:
        lua_data = '{\n' if do_indent else '{'
        for value in tag:
            lua_data += (indent_str + ' ' * 4) + nbt2lua(value, do_indent, indentation + 4) + ',\n' if do_indent else nbt2lua(value, do_indent) + ','
        lua_data += indent_str + '}' if do_indent else '}'
        return lua_data
    elif tag_type == TAG_COMPOUND:
        lua_data = '{\n' if do_indent else '{'
        for name, value in tag.items():
            lua_data += (indent_str + ' ' * 4) + '[' + nbt2lua(nbt.TAG_String(name), do_indent) + '] = ' + nbt2lua(value, do_indent, indentation + 4) + ',\n' if do_indent else '[' + nbt2lua(nbt.TAG_String(name), do_indent) + '] = ' + nbt2lua(value, do_indent) + ','
        lua_data += indent_str + '}' if do_indent else '}'
        return lua_data
    elif tag_type == TAG_INT_ARRAY:
        return '{' + ', '.join(str(x) for x in tag) + '}'
    elif tag_type == TAG_LONG_ARRAY:
        return '{' + ', '.join(str(x) + 'L' for x in tag) + '}'
    else:
        return 'nil'


def print_help():
    print("Usage: python convert_nbt_to_lua.py <input_filename> [<output_filename>]")
    print("Converts an NBT file to a Lua table.")
    print("Arguments:")
    print("  <input_filename>: The filename of the NBT file to convert.")
    print("  <output_filename> (optional): The filename of the Lua table to save. If not provided, the output filename will be the same as the input filename with a .luatable extension.")


if __name__ == "__main__":
    # Check if the correct number of arguments are provided
    if len(sys.argv) < 2 or len(sys.argv) > 3:
        print("Error: Incorrect number of arguments.")
        print_help()
        sys.exit(1)

    input_filename = sys.argv[1]
    output_filename = sys.argv[2] if len(sys.argv) == 3 else os.path.splitext(input_filename)[0] + ".luatable"

    try:
        # Load NBT file
        nbt_file = nbt.NBTFile(input_filename)

        # Convert to Lua table with indentation disabled
        lua_data = nbt2lua(nbt_file, do_indent=False)

        # Dump Lua table to a file
        with open(output_filename, "w") as lua_file:
            lua_file.write(lua_data)

        print("Conversion completed. Lua table saved to", output_filename)

    except FileNotFoundError:
        print("Error: Input file not found:", input_filename)
        sys.exit(1)
