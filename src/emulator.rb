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

	def load data,size
		size = data.length if size > data.length
		size.times{|e|
			# String#unpack returns Array
			@state[:memory][e], = data[e].unpack("C")
		}
	end

	def exec debug = false
		@func_table = create_func_table

		while @state[:eip] < MEMORY_SIZE
			code = get_u_sign_8(0)
			puts "Code: #{code}" if debug
			raise EmulatorRuntimeError,"Unknown Operator code : #{code.to_s(16)}" if !@func_table.key?(code)

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
		@state[:registers].each { |k,v| puts "#{k} : 0x#{v.to_s(16)}" }
		puts "eip : 0x#{@state[:eip].to_s(16)}"
#		puts "eflags : 0x#{@state[:eflags] .to_s(16)}"
	end

	def dump_memory from=0,to=@state[:memory].length
		from.upto(to-1) { |e| print "#{@state[:memory][e].to_s(16)}" }
		puts
	end

	private

	# function poninter table in C++
	def create_func_table
		table = {}
		8.times { |e| table[0xB8 + e] = method(:mov_r_32) }
		table[0xE9] = method(:jmp_32)
		table[0xEB] = method(:jmp_8)
		table
	end

	# Instructions
	def mov_r_32
		reg = get_u_sign_8(0) - 0xB8
		val = get_u_sign_32(1)
		@state[:registers][REGISTER_TABLE[reg]] = val
		@state[:eip] += 5
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


end
