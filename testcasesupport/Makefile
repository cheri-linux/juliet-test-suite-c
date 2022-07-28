# Bins
MAKE=make
CC?=gcc
CXX?=g++
CFLAGS=-g
LD?=ld
LDFLAGS=-lpthread
BIN_DIR?=./

support-lib: io.o std_thread.o
	$(AR) rc $(BIN_DIR)/libjuliet-support.a $(addprefix $(BIN_DIR)/,$^)

%.o: %.c
	$(CC) -g -c -o $(BIN_DIR)/$@ $^

clean:
	rm -f *.o *.so *.a