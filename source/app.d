import std.stdio;
import std.algorithm;
import std.array;
import std.mmfile;
import std.format;
import std.conv;
import std.range;

enum offsets_start = 0x71CC8;
enum data_start = 0x73382;
enum data_end = 0x7C7BC;

ushort[] offsets;

void main() {
    File f = File("raw/en_oos.gbc", "rb");
    offsets           = f.array_from_file!(ushort, offsets_start, data_start); //.sort().array;
    char[] table_data = f.array_from_file!(char, data_start, data_end);
    f.close();
    writefln("Found %d entries.", offsets.length);

    File output_file = File("dump.txt", "wb");

    foreach (index, o; offsets) {
        output_file.writefln("%d: at $%06X\n%s\n",
            index,
            0x73382 + o,
            get_string(table_data, o)
        );
    }
    writefln("File has been dumped to \"%s\".", output_file.name);
}

auto array_from_file(E, size_t start, int stop)(ref File file) {
    static assert(stop > start);
    enum section_size = stop - start;
    static assert(section_size % E.sizeof == 0);

    E[] output_array = new E[section_size / E.sizeof];
    file.seek(start);
    output_array = file.rawRead!E(output_array);
    return output_array;
}

/++ 
    Get the offsets that precedes the data at 0x73382
    which have been pulled out into a separate file.
+/
ushort[] get_offsets_0x73382_isolated() {
    File offsets_file = File("raw/table offsets 0x73382.dat", "rb");
    ushort[] offsets = new ushort[offsets_file.size / 2];
    offsets = offsets_file.rawRead!ushort(offsets);
    offsets_file.close();
    return offsets.sort().array;
}

/++ 
    Get the string data at 0x73382
    which has been pulled out into a separate file.
+/
char[] get_data_0x73382_isolated() {
    File table_file = File("raw/table data 0x73382.dat", "rb");
    char[] table_data = new char[table_file.size];
    table_data = table_file.rawRead(table_data);
    table_file.close();
    return table_data;
}

string get_string(const char[] table_data, int offset) {
    string text = "";
    int j = offset;
    while (table_data[j] != 0x0) {
        auto codepoint = parse_codepoint_usa(table_data, j);
        text ~= codepoint;
        j += 1;
    }
    return text;
}

string parse_codepoint_usa(const char[] table_data, ref int offset) {
    // writeln(offset);
    char ch0 = table_data[offset];
    char ch = table_data[offset];
    switch (ch) {
        case 0x00:
            assert(0, "Value cannot be $00!");
        case 0x01:
            return "\n";
        case 0x02: .. case 0x05: {
            offset += 1;
            return //format!"{%02X:%s}"(ch0, 
            table_data.get_string(offsets[
                ((ch - 2) << 8) | table_data[offset]
            ]);
            //);
        }
         
        case 0x06: { /// Special characters
            offset += 1;
            // goto case 0x02;
            return "[Picture]";
        }
        case 0x07: return ""; // No idea
        case 0x08: { /// Branch
            offset += 1;
            switch (table_data[offset]) {
                case 0x0F:
                    return "[if yes, go to next]";
                case 0x0D:
                    return "[if yes, go to one after next]";
                default:
                    return format!"[if idk $%02X]"(table_data[offset]);
            }
            
        }
        
        case 0x09: { /// Color
            offset += 1;
            return "";
            // return format!"[color $%X]"(table_data[offset]);
        }
        case 0x0A: {
            offset += 1;
            switch (table_data[offset]) {
                case 0x00: return "Link";
                case 0x02: return "[secret]";
                default: return format!"[preset %02X]"(table_data[offset]);
            }
        }
        case 0x0B: {
            ///Check condition first
            offset += 1;
            // goto case 0x02;
            return format!"[$%02X, $%02X?]"(ch, table_data[offset]);
        }
        case 0x0C: { /// Selections
            offset += 1;
            return "[]";
            // return format!"[option $%02X]"(table_data[offset]);
        }
        
        case 0x0D: { /// Some kind of branch label?
            offset += 1;
            return "";
        }
        case 0x0E: { /// Play a sound probably. shows up in item get and ricky's dialogue.
            offset += 1;
            return "";
        }
        case 0x0F: /// No idea but its not for strings.
        { // Double
            offset += 1;
            return "";
        }

        case 0x10:
            return "●";
        case 0x11:
            return "♣";
        case 0x12:
            return "♦";
        case 0x13:
            return "♠";
        case 0x14:
            return "♥";
        case 0x15:
            return "↑";
        case 0x16:
            return "↓";
        case 0x17:
            return "←";

        case 0x18:
            return "→";
        case 0x19:
            return "×";
        case 0x1A:
            return "“";
        case 0x1B:
            return "「";
        case 0x1C:
            return "」";
        case 0x1D:
            return "．";
        case 0x1E:
            return "、";
        case 0x1F:
            return "。";

        case 0x22:
            return "”";

        case 0x91: .. case 0x9F:
        case 0xB1: .. case 0xB7:
        case 0xBC:
        case 0xBE: .. case 0xFF: {
            return format!"[$%02X?]"(ch);
        }

        case 0xB8: {
            if (table_data[offset+1] == 0xB9) {
                offset += 1;
                return "(A)";
            } else {return "(A";}
        }

        case 0xBA: {
            if (table_data[offset+1] == 0xBC) {
                offset += 1;
                return "(B)";
            } else {return "(B";}
        }

        default: {
            return format!"%s"(ch);
        }
    }
}
