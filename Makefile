CC=gcc
CFLAGS=-Wall
LDFLAGS=-Wall -lfl -lm
EXEC=tpc

all: $(EXEC) clean

$(EXEC): $(EXEC).o lex.yy.o
	gcc  -o $@ $^ $(LDFLAGS)

$(EXEC).c: $(EXEC).y
	bison -v -d -o $(EXEC).c $(EXEC).y

$(EXEC).h: $(EXEC).c

lex.yy.c: $(EXEC).lex $(EXEC).h
	flex $(EXEC).lex

%.o: %.c
	gcc -o $@ -c $< $(CFLAGS)

clean:
	rm -f *.o lex.yy.c $(EXEC).[ch]
