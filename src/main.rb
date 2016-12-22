require_relative "./emulator"

if ARGV.size == 1
	emu = Emulator.new(1024,0x7c00,0x7c00)
	emu.load(File.binread(ARGV[0]),0x200)
	emu.exec_with_debug
	emu.dump_registers
else
	puts "too many arguments."
end
