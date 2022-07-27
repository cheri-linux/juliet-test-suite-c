# Bins
MAKE=make
CC?=gcc
CXX?=g++
CFLAGS=-g
LD?=ld
LDFLAGS=-lpthread
BIN_DIR?=./

support-lib: io.o std_thread.o
	$(AR) rc $(BIN_DIR)/libjuliet-support.a $^

clean:
	rm -f *.o *.so