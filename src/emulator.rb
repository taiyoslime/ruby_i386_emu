class Emulator
	class EmulatorRuntimeError < StandardError; end


	MEMORY_SIZE = 1024 * 1024
	REGISTERS_NAME = ["eax","ecx","edx","ebx","esp","ebp","esi","edi"]

	attr_reader :registers
	def initialize size,eip,esp
		@memory = Array.new(size,0)
		@registers = {}
		REGISTERS_NAME.each{|nm|
			@registers[nm] = 0
		}
		@registers["esp"] = esp
		@eip = eip
		@eflags = nil
		@func_table = create_func_table

	end

	def load data,size
		size = data.length if size > data.length
		size.times{|e|
			# String#unpack returns Array
			@memory[e], = data[e].unpack("C")
		}
	end

	def exec
		while @eip < MEMORY_SIZE
			code = get_u_sign_8(0)
			raise EmulatorRuntimeError,"Unknown Operator code : #{code.to_s(16)}" if !@func_table.key?(code)

			@func_table[code].call
		 	if @eip == 0x00
				puts "END"
				break
			end
		end
	end

	def dump_registers
		@registers.each{|k,v| puts "#{k} : 0x#{v.to_s(16)}" }
	end
	def dump_memory from=0,to=@memory.length
		from.upto(to-1){|e|
			print "#{@memory[e].to_s(16)} "
		}
		puts
	end

	private
	def create_func_table
		table = {}
		8.times{ |e|
			table[0xB8 + e] = method(:mov_r_32)
		}
		table[0xE9] = method(:jmp_32)
		table[0xEB] = method(:jmp_8)
		table
	end
	def mov_r_32
		reg = get_u_sign_8(0) - 0xB8
		val = get_u_sign_32(1)
		@registers[REGISTERS_NAME[reg]] = val
		@eip += 5
	end


	# short jump
	def jmp_8
		diff = get_sign_8(1)
		@eip += ( diff + 2 )
	end

	#near jump
	def jmp_32
		diff = get_sign_32(1)
		@eip += ( diff + 5 )
	end

	# util
	def get_u_sign_8 index
		@memory[@eip+index]
	end

	def get_sign_8 index
		((e = get_u_sign_8(index)) >> 7 & 1) == 1 ? e | -(1 << 8) : e
	end

	def get_u_sign_32 index
		ret = 0
		4.times{|e| ret |= get_u_sign_8(index + e) << (e * 8) }
		ret
	end

	def get_sign_32 index
		((e = get_u_sign_32(index)) >> 31 & 1) == 1 ? e | -(1 << 32) : e
	end


end
