# Bins
MAKE=make
CC?=gcc
CXX?=g++
CFLAGS=-g
LD?=ld
LDFLAGS=-lpthread
BIN_DIR?=./

support-lib: io.o std_thread.o
	$(LD) $(LDFLAGS) --shared -o $(BIN_DIR)/libjuliet-support.so $^

clean:
	rm -f *.o *.so