#include <math.h>
#include <stdlib.h>
#include <string.h>
#include <gsl/gsl_siman.h>
#include <vector>
#include <iostream>
#include <fstream>
#include <sstream>
#include <iomanip>
#include <map>
#include <cmath>

/* set up parameters for this simulated annealing run */
     
/* how many points do we try before stepping */
#define N_TRIES 200             

/* how many iterations for each T? */
#define ITERS_FIXED_T 1000

/* max step size in random walk */
#define STEP_SIZE 100.0            

/* Boltzmann constant */
#define K 1.0                   

/* initial temperature */
#define T_INITIAL 0.008         

/* damping factor for temperature */
#define MU_T 1.003              
#define T_MIN 1.0e-5
//#define T_MIN 2.0e-6

gsl_siman_params_t params = {N_TRIES, ITERS_FIXED_T, STEP_SIZE,
			     K, T_INITIAL, MU_T, T_MIN};

int use_mad = 0;

inline std::pair<int,int> mangle(int p, int q)
{
    return p < q ? std::pair<int,int>(p, q) : std::pair<int,int>(q, p);
}

struct Group;
struct Round;
struct Contest;

struct Group {
    std::vector<int> pilots;
    void draw(const Contest*, const Round*, int, std::map<std::pair<int, int>, int>&);
    int in_group(int p) const;
    void duels(std::map<std::pair<int, int>, int>& eduels) const;
};

struct Round {
    std::vector<Group> groups;
    void draw(const Contest*, std::map<std::pair<int, int>, int>&);
    void worst_case(const Contest*);
    int in_round(int p) const;
    void duels(std::map<std::pair<int, int>, int>& eduels) const;
    void remove_duels(int, int, std::map<std::pair<int, int>, int>& eduels) const;
    void add_duels(int, int, std::map<std::pair<int, int>, int>& eduels) const;
    void step(std::map<std::pair<int, int>, int>&);
    void step0(int p, int q, std::map<std::pair<int, int>, int>&);
    int stepm(int p, int q, std::map<std::pair<int, int>, int>&);
    void get_group_and_index(int p, int& pg, int& pi) const;
    Round() {}
};

struct Contest {
    std::vector<Round> rounds;
    std::map<std::pair<int, int>, int> cduels;
    int npilots;
    std::vector<int> group_npilots;
    int nrounds;
    int max_duels;
    void draw();
    void worst_case();
    void add_group_npilots(int i) { group_npilots.push_back(i); }
    void duels(std::map<std::pair<int, int>, int>& eduels) const;
    int sum_duel_occurences(const std::map<std::pair<int, int>, int>& eduels,
			    std::map<int, int>& ov) const;
    double mad(const std::map<int, int>&) const;
    double cost() const;
    void step(double u, double step_size);
    void report();
    void init_duels();
    Contest() {}
    Contest(int inpilots, int inrounds, int imax_duels) : npilots(inpilots), nrounds(inrounds), max_duels(imax_duels) {
	init_duels();
    }
};

void Group::duels(std::map<std::pair<int, int>, int>& eduels) const
{
    for(std::vector<int>::const_iterator P = pilots.begin(); P != pilots.end(); P++) {
	std::vector<int>::const_iterator Q = P;
	Q++;
	for(; Q != pilots.end(); Q++) {
	    std::pair<int,int> k = mangle(*P, *Q);
	    if (eduels.count(k))
		eduels[k]++;
	    else
		eduels[k] = 1;
	}
    }
}

void Round::duels(std::map<std::pair<int, int>, int>& eduels) const
{
    for(std::vector<Group>::const_iterator I = groups.begin(); I != groups.end(); I++)
	I->duels(eduels);
}

void Contest::duels(std::map<std::pair<int, int>, int>& eduels) const
{
//    eduels.clear();
    for(int i = 0; i < (npilots - 1); i++)
	for(int j = i+1; j < npilots; j++)
	    eduels[mangle(i, j)] = 0;
    for(std::vector<Round>::const_iterator I = rounds.begin(); I != rounds.end(); I++)
	I->duels(eduels);
}

int Contest::sum_duel_occurences(const std::map<std::pair<int, int>, int>& eduels,
				 std::map<int, int>& ov) const
{
    int mov = 0;
    for(std::map<std::pair<int, int>, int>::const_iterator I = eduels.begin(); I != eduels.end(); I++) {
	if (I->first.first != I->first.second) {
	    if (ov.count(I->second))
		ov[I->second]++;
	    else
		ov[I->second] = 1;
	    if (I->second > mov)
		mov = I->second;
	}
    }
    return mov;
}

double Contest::mad(const std::map<int, int>& ov) const
{
    double tm = 0;
    double md = 0;
    for(std::map<int, int>::const_iterator I = ov.begin(); I != ov.end(); I++) {
	tm = tm + I->second;
	md = md +I->first * I->second;
    }
    double wad = md / tm;
    double ad = 0;
    for(std::map<int, int>::const_iterator I = ov.begin(); I != ov.end(); I++)
	ad = ad + std::abs(I->first - wad) *  I->second;
    double mad = ad / tm;
    return mad;
}

double Contest::cost() const 
{
    std::map<int, int> ov;
    int mov = sum_duel_occurences(cduels, ov);
    double cost = 0;

    if (use_mad) {
	double m = mad(ov);
	cost = m;
	if (max_duels >= 0) {
	    if (max_duels != 1000000 && ov.count(0))
		cost += ov[0] * 0.002;
	    for(int i = max_duels; i <= mov; i++)
		cost += ov[i] * 0.002 * pow(10,i-max_duels);
	}
    }
    else {
//     cost = cost + mov * 10e9; // don't like many duels
//     cost = cost - ov[mov]; // like many occurences of max number of duels
//     if (ov.count(0))
//  	cost = cost + ov[0] * 1000; // don't like pilots not dueling

	cost = cost + mov * 10e9; // don't like many duels
	if (mov <= max_duels) {
	    if (ov.count(0))
		cost += ov[0] * 10000000; // Try again with 10e6
	    for(int i = 1; i <= max_duels; i++)
		if (ov.count(i))
		    cost -= ov[i] * (i == 2 ? 20000 : 1000);
	}
	else
	    cost += ov[mov] * 10000000; // Try again with 10e6

//     for(int i = 0; i <= mov; i++)
// 	if (ov.count(i))
// 	    cost += ov[i] * pow(10, 3*i);
    }
    
    return cost;
}

inline std::ostream& operator<<(std::ostream& os, const Group& c)
{
    os << "{";
    int first = 1;
    for(std::vector<int>::const_iterator I = c.pilots.begin(); I != c.pilots.end(); I++) {
	if (!first)
	    os << " ";
	first = 0;
	os << *I;
    }
    os << "}";
    return os;
}

inline std::ostream& operator<<(std::ostream& os, const Round& r)
{
    int first = 1;
    for(std::vector<Group>::const_iterator I = r.groups.begin(); I != r.groups.end(); I++) {
	if (!first)
	    os << " ";
	first = 0;
	os << *I;
    }
    return os;
}

inline std::ostream& operator<<(std::ostream& os, const Contest& c)
{
    for(std::vector<Round>::const_iterator I = c.rounds.begin(); I != c.rounds.end(); I++)
	os << *I << "\n";
    return os;
}

void Contest::report()
{
    std::ostringstream fos;
    fos << "data/f3k_" << npilots << "p_" << nrounds << "r";
    for(std::vector<int>::const_iterator I = group_npilots.begin(); I != group_npilots.end(); I++)
	fos << "_" << *I;
    fos << "_";
    if (max_duels == 0)
	fos << "worstcase";
    else if (max_duels < 0)
	fos << (-max_duels) << "random";
    else
	fos << max_duels << "siman";
    if (use_mad)
	fos << "_mad";
    fos << ".txt";
    std::ofstream os(fos.str().c_str());
    os << "pilots " << npilots << "\n";
    os << "rounds " << nrounds << "\n";
    os << "groups";
    for(std::vector<int>::const_iterator I = group_npilots.begin(); I != group_npilots.end(); I++)
	os << " " << *I;
    os << "\n";
    if (max_duels < 0)
	os << "method random\nnumber_of_draws " << (-max_duels) << "\n";
    else
	os << "method simulated_annealing\nmax_duels " << max_duels << "\n";
    int r = 1;
    for(std::vector<Round>::const_iterator I = rounds.begin(); I != rounds.end(); I++)
	os << "round " << r++ << " {" << *I << "}\n";
    std::map<std::pair<int, int>, int> eduels;
    std::map<int, int> ov;
    int mov = sum_duel_occurences(cduels, ov);
    os << "duel_frequencies";
    for(int i = 0; i <= mov; i++)
	if (ov.count(i))
	    os << " " << i << ":" << ov[i];
    os << "\n";
    os << "mean_absolute_deviation " << mad(ov) << "\n";
    os << "matrix  -";
    for(int p = 0; p < npilots; p++)
	os << " " << std::setw(2) << p;
    os << "\n";
    for(int p = 0; p < npilots; p++) {
	os << "matrix " << std::setw(2) << p;
	for(int q = 0; q < npilots; q++) {
	    std::pair<int, int> k = mangle(p, q);
	    if (p == q)
		os << "  -";
	    else if (cduels.count(k))
		os << " " << std::setw(2) << cduels.at(k);
	    else
		os << "  0";
	}
	os << "\n";
    }

}

int Group::in_group(int p) const
{
    for(std::vector<int>::const_iterator I = pilots.begin(); I != pilots.end(); I++)
	if (*I == p)
	    return 1;
    return 0;
}

int Round::in_round(int p) const
{
    for(std::vector<Group>::const_iterator I = groups.begin(); I != groups.end(); I++)
	if (I->in_group(p))
	    return 1;
    return 0;
}

void Group::draw(const Contest* contest, const Round* round, int npilots, std::map<std::pair<int, int>, int>& cduels)
{
    pilots.clear();
    do {
	int p = random() % contest->npilots;
	if (!round->in_round(p) && !this->in_group(p)) {
	    for(std::vector<int>::const_iterator I = pilots.begin(); I != pilots.end(); I++)
		cduels[mangle(p, *I)]++;
	    pilots.push_back(p);
	}
    } while (pilots.size() < npilots);
}

void Round::draw(const Contest* contest, std::map<std::pair<int, int>, int>& cduels)
{
    groups.clear();
    for(std::vector<int>::const_iterator I = contest->group_npilots.begin(); I != contest->group_npilots.end(); I++) {
	Group group;
	group.draw(contest, this, *I, cduels);
	groups.push_back(group);
    }
}

void Round::worst_case(const Contest* contest)
{
    groups.clear();
    int p = 0;
    for(std::vector<int>::const_iterator I = contest->group_npilots.begin(); I != contest->group_npilots.end(); I++) {
	Group group;
	for(int i = 0; i < *I; i++)
	    group.pilots.push_back(p++);
	groups.push_back(group);
    }
}

void Contest::init_duels()
{
    cduels.clear();
    for(int i = 0; i < (npilots - 1); i++)
	for(int j = i+1; j < npilots; j++)
	    cduels[mangle(i, j)] = 0;
}

void Contest::worst_case()
{
    rounds.clear();
    init_duels();
    for(int r = 0; r < nrounds; r++) {
	Round round;
	round.worst_case(this);
	rounds.push_back(round);
    }
    duels(cduels);
}

void Contest::draw()
{
    rounds.clear();
    init_duels();
    for(int r = 0; r < nrounds; r++) {
	Round round;
	round.draw(this, cduels);
	rounds.push_back(round);
    }
}

void Round::get_group_and_index(int p, int& pg, int& pi) const
{
    pg = 0;
    for(std::vector<Group>::const_iterator I = groups.begin(); I != groups.end(); I++) {
	pi = 0;
	for(std::vector<int>::const_iterator J = I->pilots.begin(); J != I->pilots.end(); J++) {
	    if (*J == p)
		return;
	    pi++;
	}
	pg++;
    }
}

inline void Round::remove_duels(int p, int g, std::map<std::pair<int, int>, int>& cduels) const
{
    for(std::vector<int>::const_iterator I = groups[g].pilots.begin(); I != groups[g].pilots.end(); I++)
	if (*I != p)
	    cduels[mangle(*I, p)]--;
}

inline void Round::add_duels(int p, int g, std::map<std::pair<int, int>, int>& cduels) const
{
    for(std::vector<int>::const_iterator I = groups[g].pilots.begin(); I != groups[g].pilots.end(); I++)
	if (*I != p)
	    cduels[mangle(*I, p)]++;
}

void Round::step(std::map<std::pair<int, int>, int>& cduels)
{
    // Swap 2 pilots from different groups
    int rg0 = random() % groups.size();
    int rg1 = rg0;
    if (groups.size() > 1) {
	do {
	    rg1 = random() % groups.size();
	} while (rg0 == rg1);
    }
    int rp0 = random() % groups[rg0].pilots.size();
    int rp1 = random() % groups[rg1].pilots.size();
    int p = groups[rg0].pilots[rp0];
    int q = groups[rg1].pilots[rp1];
    remove_duels(p, rg0, cduels);
    remove_duels(q, rg1, cduels);
    groups[rg0].pilots[rp0] = q;
    groups[rg1].pilots[rp1] = p;
    add_duels(p, rg1, cduels);
    add_duels(q, rg0, cduels);
}

void Round::step0(int p, int q, std::map<std::pair<int, int>, int>& cduels)
{
    // Get random pilots from same group as p and swap it with pilot q
    int pg = 0;
    int pi = 0;
    get_group_and_index(p, pg, pi);
    int qg = 0;
    int qi = 0;
    get_group_and_index(q, qg, qi);
    int r = 0;
    do {
	r = random() % groups[pg].pilots.size();
    } while (r == pi);
    int rtmp = groups[pg].pilots[r];
    int qtmp = groups[qg].pilots[qi];
    remove_duels(rtmp, pg, cduels);
    remove_duels(qtmp, qg, cduels);
    groups[pg].pilots[r] = qtmp;
    groups[qg].pilots[qi] = rtmp;
    add_duels(rtmp, qg, cduels);
    add_duels(qtmp, pg, cduels);
}

int Round::stepm(int p, int q, std::map<std::pair<int, int>, int>& cduels)
{
    // When pilots p and q are in same group, swap pilots p with pilot from other group
    int pg = 0;
    int pi = 0;
    get_group_and_index(random() % 2 ? p : q, pg, pi);
    int qg = 0;
    int qi = 0;
    get_group_and_index(q, qg, qi);
    if (pg != qg)
	return 0;
    int rg = 0;
    do {
	rg = random() % groups.size();
    } while (rg == pg);
    
    int ri = random() % groups[rg].pilots.size();
    int ptmp = groups[pg].pilots[pi];
    int rtmp = groups[rg].pilots[ri];
    remove_duels(ptmp, pg, cduels);
    remove_duels(rtmp, rg, cduels);
    groups[pg].pilots[pi] = rtmp;
    groups[rg].pilots[ri] = ptmp;
    add_duels(rtmp, pg, cduels);
    add_duels(ptmp, rg, cduels);
    return 1;
}

void Contest::step(double u, double step_size)
{
    std::map<int, int> ov;
    int mov = sum_duel_occurences(cduels, ov);
    if (use_mad) {
	int i = 0;
	std::vector<std::pair<int, int> > eduelsm;
	for(std::map<std::pair<int, int>, int>::const_iterator I = cduels.begin(); I != cduels.end(); I++)
	    if (I->second == mov)
		eduelsm.push_back(I->first);
	for(; i < (u * 100) && eduelsm.size(); i++) {
	    int rr = 0;
	    int r0 = 0;
	    do {
		rr = random() % nrounds;
		r0 = random() % eduelsm.size();
	    } while(!rounds[rr].stepm(eduelsm[r0].first, eduelsm[r0].second, cduels));
	    eduelsm.erase(eduelsm.begin()+r0);
	}
// 	for(; i < (u * 100); i++) {
// 	    int rr = random() % nrounds;
// 	    rounds[rr].step(cduels);
// 	}
	std::vector<std::pair<int, int> > eduels0;
	for(std::map<std::pair<int, int>, int>::const_iterator I = cduels.begin(); I != cduels.end(); I++)
	    if (I->second == 0)
		eduels0.push_back(I->first);
	for(; i < (u * 10) && eduels0.size(); i++) {
	    int rr = random() % nrounds;
	    int r0 = random() % eduels0.size();
	    rounds[rr].step0(eduels0[r0].first, eduels0[r0].second, cduels);
	    eduels0.erase(eduels0.begin()+r0);
	}
//	for(; i < (u * 10) && eduels0.size(); i++) {
//		int rr = random() % nrounds;
//		rounds[rr].step(cduels);
//	    }
    }
    else if (mov >= max_duels) {
 	for(int i = 0; i < (u*100); i++) {
 	    int rr = random() % nrounds;
 	    rounds[rr].step(cduels);
 	}
    }
    else {
	if (ov.count(0)) {
	    std::vector<std::pair<int, int> > eduels0;
	    for(std::map<std::pair<int, int>, int>::const_iterator I = cduels.begin(); I != cduels.end(); I++)
		if (I->second == 0)
		    eduels0.push_back(I->first);
	    int i = 0;
	    for(; i < (u * 10) && eduels0.size(); i++) {
		int rr = random() % nrounds;
		int r0 = random() % eduels0.size();
		rounds[rr].step0(eduels0[r0].first, eduels0[r0].second, cduels);
		eduels0.erase(eduels0.begin()+r0);
	    }
	    for(; i < (u * 10) && eduels0.size(); i++) {
		int rr = random() % nrounds;
		rounds[rr].step(cduels);
	    }
 	}
	else {
	    std::vector<std::pair<int, int> > eduelsm;
	    for(std::map<std::pair<int, int>, int>::const_iterator I = cduels.begin(); I != cduels.end(); I++)
		if (I->second == mov)
		    eduelsm.push_back(I->first);
	    int i = 0;
	    for(; i < (u * 10) && eduelsm.size(); i++) {
		int rr = 0;
		int r0 = 0;
		do {
		    rr = random() % nrounds;
		    r0 = random() % eduelsm.size();
		} while(!rounds[rr].stepm(eduelsm[r0].first, eduelsm[r0].second, cduels));
		eduelsm.erase(eduelsm.begin()+r0);
	    }
	    for(; i < (u * 10); i++) {
		int rr = random() % nrounds;
		rounds[rr].step(cduels);
	    }
	}
    }
}

double E1(void *xp)
{
    return ((Contest*)xp)->cost();
}
     
double M1(void *xp, void *yp)
{
    double x = ((Contest *) xp)->cost();
    double y = ((Contest *) yp)->cost();
    
    return fabs(x - y);
}
     
void S1(const gsl_rng * r, void *xp, double step_size)
{
    double u = gsl_rng_uniform(r);
    ((Contest *) xp)->step(u, step_size);
}

void P1(void *xp)
{
    Contest* c = (Contest*)xp;
    std::map<int, int> ov;
    int mov = c->sum_duel_occurences(c->cduels, ov);
    std::cout << "#";
    for(int i = 0; i <= mov; i++)
	if (ov.count(i))
	    std::cout << "," << i << ":" << ov[i];
    std::cout << "%" << c->mad(ov);
//    std::cout << "\n" << *c << std::endl;
}

void C1(void *source, void *dest)
{
    *((Contest*) dest) = *((Contest*) source);
}

void* CC1(void *xp)
{
    Contest* c = new Contest();
    *c = *((Contest*) xp);
    return c;
}

void D1(void *xp)
{
    delete ((Contest*) xp);
}

int main(int argc, char *argv[])
{
    srandom(getpid());

    if (argc < 5) {
	std::cerr << "usage: f3ksa #pilots #rounds #method #pilots_in_group1 ?#pilots_in_group2? ..." << std::endl;
	std::cerr << std::endl;
	std::cerr << "  #pilots              Number of pilots in the contest" << std::endl;
	std::cerr << "  #rounds              Number of rounds/tasks in the contest" << std::endl;
	std::cerr << "  #method              Method used to draw the contest" << std::endl;
	std::cerr << "    <integer>            Use built-in cost fucntion" << std::endl;
	std::cerr << "    < 0                    Best of abs(specified number) of drawings" << std::endl;
	std::cerr << "    0                      Worst case" << std::endl;
	std::cerr << "    1                      Minimize number of duels with highest frequency" << std::endl;
	std::cerr << "    > 1                    Minimize number of duels with highest frequency until" << std::endl;
	std::cerr << "                           specified number is reached, then try to maximize that" << std::endl;
	std::cerr << "                           number of duels while trying to avoid pilots not duelling" << std::endl;
	std::cerr << "    m?<integer>?         Use mean absolute deviation" << std::endl;
	std::cerr << "    no integer             Minimize the mean absolute deviation" << std::endl;
	std::cerr << "    < 0                    Best of abs(specified number) of drawings" << std::endl;
	std::cerr << "    > 0                    Minimize the mean absolute deviation with extra cost for" << std::endl;
	std::cerr << "                           duels with frequency 0 and with frequency >= specified" << std::endl;
	std::cerr << "                           integer" << std::endl;
	std::cerr << "  #pilots_in_group1    Number of pilots in first group" << std::endl;
	std::cerr << "  ?#pilots_in_group2?  Number of pilots in second group" << std::endl;
	std::cerr << "  ...                  ..." << std::endl;
	return 1;
    }

    int do_sa = 1;

    int pilots = 0;
    std::istringstream is1(argv[1]);
    is1 >> pilots;

    int rounds = 0;
    std::istringstream is2(argv[2]);
    is2 >> rounds;

    int max_duels = 0;
    if (argv[3][0] == 'm') {
	use_mad = 1;
	if (strlen(argv[3]) > 1) {
	    std::istringstream is3(&argv[3][1]);
	    is3 >> max_duels;
	}
	else
	    max_duels = 1000000;
    }
    else {
	std::istringstream is3(argv[3]);
	is3 >> max_duels;
    }

    std::vector<int> groups;
    int tpilots = 0;
    for(int i = 4; i < argc; i++) {
	int t = 0;
	std::istringstream is3(argv[i]);
	is3 >> t;
	groups.push_back(t);
	tpilots += t;
    }

    if (pilots != tpilots) {
	std::cerr << "Number of pilots not equal to sum of number of pilots per group" << std::endl;
	return 1;
    }

    Contest contest(pilots, rounds, max_duels);
    for(std::vector<int>::const_iterator I = groups.begin(); I != groups.end(); I++)
	contest.add_group_npilots(*I);

    if (max_duels == 0) {
	contest.worst_case();
    }
    else if (max_duels < 0) {
	contest.draw();
	if (groups.size() > 1) {
	    double cost = contest.cost();
	    Contest ccontest = contest;
	    std::cout << max_duels; P1(&contest); std::cout << std::endl;
	    max_duels++;
	    while(max_duels < 0) {
		ccontest.draw();
		double ccost = ccontest.cost();
		if (ccost < cost) {
		    contest = ccontest;
		    cost = ccost;
		    std::cout << max_duels; P1(&contest); std::cout << std::endl;
		}
		max_duels++;
	    }
	}
    }
    else {
	contest.draw();
	if (groups.size() > 1) {
	    const gsl_rng_type * T;
	    gsl_rng * r;
     
	    gsl_rng_env_setup();
     
	    T = gsl_rng_default;
	    r = gsl_rng_alloc(T);
     
	    gsl_siman_solve(r, &contest, E1, S1, M1, P1, C1, CC1, D1, 
			    sizeof(double), params);
    
	    gsl_rng_free (r);
	}
    }
    
    contest.report();

    return 0;
}
