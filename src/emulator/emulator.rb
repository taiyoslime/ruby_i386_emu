class Emulator
	class EmulatorRuntimeError < StandardError; end

	MEMORY_SIZE = 1024 * 1024
	REGISTER_TABLE = %w(eax ecx edx ebx esp ebp esi edi).map(&:to_sym)

	attr_reader :registers
	def initialize size, eip, esp
		@state = {}
		@state[:memory] = Array.new(size, 0)
		@state[:registers] = {}
		REGISTER_TABLE.each { |e| @state[:registers][e] = 0 }
		@state[:registers][:esp] = esp
		@state[:eip] = eip
		@state[:eflags] = 0
	end

	def load data, size
		size = data.length if size > data.length
		size.times{|e|
			# String#unpack returns Array
			@state[:memory][e + @state[:eip]], = data[e].unpack("C")
		}
	end

	def exec debug = false
		@func_table = create_func_table

		while @state[:eip] < MEMORY_SIZE
			code = get_u_sign_8(0)
			puts "Code: #{p16(code)}" if debug
			raise EmulatorRuntimeError,"Unknown Operator code : #{p16(code)}" if !@func_table.key?(code)

			@func_table[code].call
			dump_registers if debug
		 	if @state[:eip] == 0x00
				puts "END"
				break
			end
		end
	end

	def exec_with_debug
		exec(true)
	end


	def dump_registers
		@state[:registers].each { |k,v| puts "#{k} : #{p16(v)}" }
		puts "eip : #{p16(@state[:eip])}"
		puts "eflags : #{p16(@state[:eflags])}"
	end

	def dump_memory from=0,to=@state[:memory].length
		from.upto(to-1) { |e| print "#{@state[:memory][e].to_s(16)}" }
		puts
	end

	private

	# function poninter table in C++
	def create_func_table
		table = {}
		8.times { |e| table[0xB8 + e] = method(:mov_r32_imm32) }
		table[0xE9] = method(:jmp_32)
		table[0xEB] = method(:jmp_8)
		table
	end

	def parse_modrm
		modrm = {}

		code = get_u_sign_8(0)
		modrm[:mod] = (code & 0xC0) >> 6
		modrm[:opecode] = (code & 0x38) >> 3
		modrm[:rm] = code & 0x07

		@state[:eip] += 1

		if modrm[:mod] != 3 && modrm[:rm] == 4
			modrm[:sib] = get_u_sign_8(0)
			@state[:eip] += 1
		end

		if (modrm[:mod] == 0 && mod[:rm] == 5) || modrn[:mod] == 2
			modrm[:disp32] = get_sign_32(0)
			@state[:eip] += 4
		elsif modrm[:mod] == 1
			modrm[:disp8] = get_sign_8(0)
			@state[:eip] += 1
		end

		modrm
	end

	# Instructions
	def mov_r32_imm32
		reg = get_u_sign_8(0) - 0xB8
		val = get_u_sign_32(1)
		@state[:registers][REGISTER_TABLE[reg]] = val
		@state[:eip] += 5
	end

	def mov_rm32_imm32
		@state[:eip] += 1
		modrm = parse_modrm
		val = get_sign_32(0)
		@state[:eip] += 4
		set_rm32(modrm, val)
	end

	# short jump
	def jmp_8
		diff = get_sign_8(1)
		@state[:eip] += ( diff + 2 )
	end

	#near jump
	def jmp_32
		diff = get_sign_32(1)
		@state[:eip] += ( diff + 5 )
	end

	# util

	def set_rm32 modrm, val
		if modrm[:mod] == 3
			set_reg32(modrm[:rm], val)
		else
			addr = calc_mem_addr(modrm)
			set_mem32(addr, val)
		end
	end

	def set_mem8 addr, val
		@state[:memory][addr] = val & 0xFF
	end

	def set_mem32 addr, val
		4.times{|e| set_mem8 ( addr + i, val >> ( i * 8 )) }
	end


	# 8bit
	def get_u_sign_8 index
		@state[:memory][@state[:eip]+index]
	end

	def get_sign_8 index
		((e = get_u_sign_8(index)) >> 7 & 1) == 1 ? e | -(1 << 8) : e
	end

	# 32bit
	def get_u_sign_32 index
		ret = 0
		4.times{|e| ret |= get_u_sign_8(index + e) << (e * 8) }
		ret
	end

	def get_sign_32 index
		((e = get_u_sign_32(index)) >> 31 & 1) == 1 ? e | -(1 << 32) : e
	end

	def p16 i
		"0x#{'0'*(8 - (d = i.to_s(16)).size)}#{d}"
	end

end
