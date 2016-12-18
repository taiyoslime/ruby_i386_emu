if [ $# -ne 1 ]; then
	echo "Wrong arguments."
else
	nasm -f bin $1.asm -o $1.bin
fi
