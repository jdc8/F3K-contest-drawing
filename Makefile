f3ksa: f3ksa.cpp
	g++ f3ksa.cpp -lm -o f3ksa -O3

test: f3ksa
	./f3ksa 19 6 m1 7 6 6

clean:
	rm f3ksa
