#GSLFLAGS = -IGSL_INCLUDE_PATH -L GSL_LIB_PATH

f3ksa: f3ksa.cpp
	g++ f3ksa.cpp -lgsl -lgslcblas -lm -o f3ksa -g -O3

clean:
	rm f3ksa
