#include <cmath>
#include <cstdlib>
#include <cstring>
#include <vector>
#include <iostream>
#include <fstream>
#include <sstream>
#include <iomanip>
#include <map>
#include <cmath>
#include <set>

#ifdef _WIN32
#include "process.h"
#endif

int use_mad = 0;
const int max_conflicted_step_tries = 1000;

inline std::pair<int,int> mangle(int p, int q)
{
    return p < q ? std::pair<int,int>(p, q) : std::pair<int,int>(q, p);
}

struct Group;
struct Round;
struct Contest;

struct Group {
    std::vector<int> pilots;
    int draw(const Contest*, const Round*, int, std::map<std::pair<int, int>, int>&);
    int in_group(int p) const;
    int conflicting(const Contest* contest,int p, int q=-1) const;
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
    int step(const Contest*, std::map<std::pair<int, int>, int>&);
    int step0(const Contest*,int p, int q, std::map<std::pair<int, int>, int>&);
    int stepm(const Contest*,int p, int q, std::map<std::pair<int, int>, int>&);
    void get_group_and_index(int p, int& pg, int& pi) const;
    Round() {}
};

struct Contest {
    std::vector<Round> rounds;
    std::map<std::pair<int, int>, int> cduels;
    int npilots;
    std::vector<int> group_npilots;
    std::map<int, std::set<int> > conflicts;
    std::vector<std::pair<int, int> > conflicts_list;
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
    void step0(double, int&);
    void stepm(double, int, int&);
    void step(double, int&);
    void report(std::string rpath);
    void init_duels();
    void add_conflict(const std::pair<int, int>& c) {
	conflicts[c.first].insert(c.second);
	conflicts[c.second].insert(c.first);
	conflicts_list.push_back(c);
    }
    int conflicting(int a, int b) const {
	std::map<int, std::set<int> >::const_iterator I = conflicts.find(a);
	if (I == conflicts.end())
	    return 0;
	return I->second.count(b);
    }
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
		cost += ov[i] * 0.002 * std::pow(double(10),i-max_duels);
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

//    for(int i = 0; i <= mov; i++)
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

void Contest::report(std::string rpath)
{
    if (rpath.size() ==0)
	rpath = "f3k.txt";
    else if (rpath == "data") {
	std::ostringstream fos;
	fos << "data/f3k_" << npilots << "p_" << nrounds << "r";
	for(std::vector<int>::const_iterator I = group_npilots.begin(); I != group_npilots.end(); I++)
	    fos << "_" << *I;
	fos << "_";
	if (max_duels == 0)
	    fos << "worstcase";
	else if (max_duels < 0)
	    fos << (-max_duels) << "random";
	else if (use_mad && max_duels == 1000000)
	    fos << "siman";
	else
	    fos << max_duels << "siman";
	if (use_mad)
	    fos << "_mad";
	fos << ".txt";
	rpath = fos.str();
    }
    std::cout << "Writing results to file '" << rpath << "'" << std::endl;
    std::ofstream os(rpath.c_str());
    os << "pilots " << npilots << "\n";
    os << "rounds " << nrounds << "\n";
    os << "groups";
    for(std::vector<int>::const_iterator I = group_npilots.begin(); I != group_npilots.end(); I++)
	os << " " << *I;
    os << "\n";
    if (max_duels == 0)
	os << "method worst_case\n";
    else if (use_mad) {
	if (max_duels < 0)
	    os << "method random_mean_absolute_deviation\nnumber_of_draws " << (-max_duels) << "\n";
	else
	    os << "method simulated_annealing_mean_absolute_deviation\nmax_duels " << max_duels << "\n";
    }
    else {
	if (max_duels < 0)
	    os << "method random\nnumber_of_draws " << (-max_duels) << "\n";
	else
	    os << "method simulated_annealing\nmax_duels " << max_duels << "\n";
    }
    if (conflicts.size()) {
	os << "conflicts";
	for(std::vector<std::pair<int, int> >::const_iterator I = conflicts_list.begin(); I != conflicts_list.end(); I++)
	    os << " " << I->first << "," << I->second;
	os << "\n";
    }
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
    os << "cost " << cost() << "\n";
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
		os << " " << std::setw(2) << cduels[k];
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

int Group::conflicting(const Contest* contest,int p, int q) const
{
    // Check if pilots p is not conflicting with other pilots in the group, conflict with pilot q is allowed
    for(std::vector<int>::const_iterator I = pilots.begin(); I != pilots.end(); I++)
	if (*I != q && contest->conflicting(p, *I))
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

int Group::draw(const Contest* contest, const Round* round, int npilots, std::map<std::pair<int, int>, int>& cduels)
{
    const int max_draws = 1000;
    int curr_draw = 0;
    pilots.clear();
    do {
	int p = rand() % contest->npilots;
	if (!round->in_round(p) && !this->in_group(p) && !conflicting(contest, p)) {
	    for(std::vector<int>::const_iterator I = pilots.begin(); I != pilots.end(); I++)
		cduels[mangle(p, *I)]++;
	    pilots.push_back(p);
	}
	curr_draw++;
    } while (pilots.size() < npilots && curr_draw < max_draws);
    return pilots.size() == npilots;
}

void Round::draw(const Contest* contest, std::map<std::pair<int, int>, int>& cduels)
{
    std::map<std::pair<int, int>, int> tduels = cduels;
    while(groups.size() != contest->group_npilots.size()) {
	groups.clear();
	cduels = tduels;
	for(std::vector<int>::const_iterator I = contest->group_npilots.begin(); I != contest->group_npilots.end(); I++) {
	    Group group;
	    if (!group.draw(contest, this, *I, cduels))
		break;
	    groups.push_back(group);
	}
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

int Round::step(const Contest* contest, std::map<std::pair<int, int>, int>& cduels)
{
    // Swap 2 pilots from different groups
    int rg0 = rand() % groups.size();
    int rg1 = rg0;
    if (groups.size() > 1) {
	do {
	    rg1 = rand() % groups.size();
	} while (rg0 == rg1);
    }
    int rp0 = rand() % groups[rg0].pilots.size();
    int rp1 = rand() % groups[rg1].pilots.size();
    int p = groups[rg0].pilots[rp0];
    int q = groups[rg1].pilots[rp1];
    if (groups[rg0].conflicting(contest, q, p))
	return 0;
    if (groups[rg1].conflicting(contest, p, q))
	return 0;
    remove_duels(p, rg0, cduels);
    remove_duels(q, rg1, cduels);
    groups[rg0].pilots[rp0] = q;
    groups[rg1].pilots[rp1] = p;
    add_duels(p, rg1, cduels);
    add_duels(q, rg0, cduels);
    return 1;
}

int Round::step0(const Contest* contest, int p, int q, std::map<std::pair<int, int>, int>& cduels)
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
	r = rand() % groups[pg].pilots.size();
    } while (r == pi);
    int rtmp = groups[pg].pilots[r];
    int qtmp = groups[qg].pilots[qi];
    if (groups[pg].conflicting(contest, qtmp, rtmp))
	return 0;
    if (groups[qg].conflicting(contest, rtmp, qtmp))
	return 0;
    remove_duels(rtmp, pg, cduels);
    remove_duels(qtmp, qg, cduels);
    groups[pg].pilots[r] = qtmp;
    groups[qg].pilots[qi] = rtmp;
    add_duels(rtmp, qg, cduels);
    add_duels(qtmp, pg, cduels);
    return 1;
}

int Round::stepm(const Contest* contest, int p, int q, std::map<std::pair<int, int>, int>& cduels)
{
    // When pilots p and q are in same group, swap pilots p with pilot from other group
    int pg = 0;
    int pi = 0;
    get_group_and_index(rand() % 2 ? p : q, pg, pi);
    int qg = 0;
    int qi = 0;
    get_group_and_index(q, qg, qi);
    if (pg != qg)
	return 0;
    int rg = 0;
    do {
	rg = rand() % groups.size();
    } while (rg == pg);
    
    int ri = rand() % groups[rg].pilots.size();
    int ptmp = groups[pg].pilots[pi];
    int rtmp = groups[rg].pilots[ri];
    if (groups[pg].conflicting(contest, rtmp, ptmp))
	return 0;
    if (groups[rg].conflicting(contest, ptmp, rtmp))
	return 0;
    remove_duels(ptmp, pg, cduels);
    remove_duels(rtmp, rg, cduels);
    groups[pg].pilots[pi] = rtmp;
    groups[rg].pilots[ri] = ptmp;
    add_duels(rtmp, pg, cduels);
    add_duels(ptmp, rg, cduels);
    return 1;
}

void Contest::stepm(double u, int mov, int& i) 
{
    std::vector<std::pair<int, int> > eduelsm;
    for(std::map<std::pair<int, int>, int>::const_iterator I = cduels.begin(); I != cduels.end(); I++)
	if (I->second == mov)
	    eduelsm.push_back(I->first);
    for(; i < u && eduelsm.size(); i++) {
	int curr_try = 0;
	int stepped = 0;
	do {
	    int rr = rand() % nrounds;
	    int r0 = rand() % eduelsm.size();
	    curr_try++;
	    if (stepped = rounds[rr].stepm(this, eduelsm[r0].first, eduelsm[r0].second, cduels))
		eduelsm.erase(eduelsm.begin()+r0);
	} while(!stepped && curr_try < max_conflicted_step_tries);
    }
}

void Contest::step0(double u, int& i)
{
    std::vector<std::pair<int, int> > eduels0;
    for(std::map<std::pair<int, int>, int>::const_iterator I = cduels.begin(); I != cduels.end(); I++)
	if (I->second == 0)
	    eduels0.push_back(I->first);
    for(; i < u && eduels0.size(); i++) {
	int curr_try = 0;
	int stepped = 0;
	do {
	    int rr = rand() % nrounds;
	    int r0 = rand() % eduels0.size();
	    curr_try++;
	    if (stepped = rounds[rr].step0(this, eduels0[r0].first, eduels0[r0].second, cduels))
		eduels0.erase(eduels0.begin()+r0);
	} while(!stepped && curr_try < max_conflicted_step_tries);
    }
}

void Contest::step(double u, int& i)
{
    for(; i < u; i++) {
	int stepped = 0;
	int curr_try = 0;
	do {
	    int rr = rand() % nrounds;
	    curr_try++;
	    stepped = rounds[rr].step(this, cduels);
	} while(!stepped && curr_try < max_conflicted_step_tries);
    }
}

void Contest::step(double u, double step_size)
{
    std::map<int, int> ov;
    int mov = sum_duel_occurences(cduels, ov);
    if (use_mad) {
	int i = 0;
	stepm(u*100, mov, i);
	step0(u*10, i);
    }
    else if (mov >= max_duels) {
	int i = 0;
	step(u*100, i);
    }
    else {
	if (ov.count(0)) {
	    int i = 0;
	    step0(u*10, i);
	    stepm(u*10, mov, i);
 	}
	else {
	    int i = 0;
	    stepm(u*10, mov, i);
	    step(u*10, i);
	}
    }
}

class SimulatedAnnealing {
public:
    
    int ITERS_FIXED_T; // number of iterations for each T
    double STEP_SIZE; // max step size in random walk
    double K;  // Boltzmann constant
    double T_INITIAL; // initial temperature
    double MU_T;  // damping factor for temperature
    double T_MIN; // minimum temperature

    virtual double energy(void* xp) = 0;
    virtual void step(double u, void* xp, double step_size) = 0;
    virtual void print(void *xp) = 0;
    virtual void copy(void *source, void *dest) = 0; 
    virtual void* new_copy(void *xp) = 0;
    virtual void destroy(void *xp) = 0;

    void anneal(void*);

    SimulatedAnnealing() : ITERS_FIXED_T(1000), STEP_SIZE(100.0), K(1.0), T_INITIAL(0.008),
			   MU_T(1.003), T_MIN(1.0e-5) {}

private:
    double boltzmann(double E, double new_E, double T) {
	double x = -(new_E - E) / (K * T);
	return exp(x);
    }

    double drandom() {
	return double(rand()) / double(RAND_MAX);
    }
};

void SimulatedAnnealing::anneal(void* x0)
{
    void* x = new_copy(x0);
    void* new_x = new_copy(x0);
    void* best_x = new_copy(x0);

    double E = energy(x0);
    double best_E = E;

    double T = T_INITIAL;
    double T_factor = 1.0 / MU_T;

    while (T > T_MIN) {
	for(int i = 0; i < ITERS_FIXED_T; i++) {
	    copy(x, new_x);
	    step(drandom(), new_x, STEP_SIZE);
	    double new_E = energy(new_x);
	    if (new_E < best_E) {
		copy(new_x, best_x);
		best_E = new_E;
	    }
	    if (new_E < E) {
		if (new_E < best_E) {
		    copy(new_x, best_x);
		    best_E = new_E;
		}
		copy(new_x, x);
		E = new_E;
	    }
	    else if (drandom() < boltzmann(E, new_E, T)) {
		copy(new_x, x);
		E = new_E;
	    }
	}

	std::cout << std::fixed << std::setw(13) << std::setprecision(8) << T
		  << "  " << std::setw(13) << E
		  << "  " << std::setw(13) << best_E
		  << "  ";
	print(x);
	std::cout << "\n";
		
	T *= T_factor;
    }

    copy(best_x, x0);
    destroy(x);
    destroy(new_x);
    destroy(best_x);
}

class F3KSA : public SimulatedAnnealing {
public:
    double energy(void *xp) {
	return ((Contest*)xp)->cost();
    }
    void step(double u, void *xp, double step_size) {
	((Contest *) xp)->step(u, step_size);
    }
    void print(void *xp) {
	Contest* c = (Contest*)xp;
	std::map<int, int> ov;
	int mov = c->sum_duel_occurences(c->cduels, ov);
	std::cout << " " << std::fixed << std::setw(13) << c->mad(ov);
	for(int i = 0; i <= mov; i++)
	    if (ov.count(i))
		std::cout << " " << i << ":" << ov[i];
    }
    void copy(void *source, void *dest) {
	*((Contest*) dest) = *((Contest*) source);
    }
    void* new_copy(void *xp) {
	Contest* c = new Contest();
	*c = *((Contest*) xp);
	return c;
    }
    void destroy(void *xp) {
	delete ((Contest*) xp);
    }

    F3KSA() {}
};  

int main(int argc, char *argv[])
{
#ifdef _WIN32
    srand(_getpid());
#else    
    srand(getpid());
#endif

    F3KSA f3ksa;

    if (argc < 5) {
	std::cerr << "usage: f3ksa #pilots #rounds #method #pilots_in_group1 ?#pilots_in_group2? ..." << std::endl;
	std::cerr << std::endl;
	std::cerr << "  #pilots                    Number of pilots in the contest" << std::endl;
	std::cerr << "  #rounds                    Number of rounds/tasks in the contest" << std::endl;
	std::cerr << "  #method                    Method used to draw the contest" << std::endl;
	std::cerr << "    f<integer>                 Use built-in cost fucntion" << std::endl;
	std::cerr << "    < 0                          Best of abs(specified number) of drawings" << std::endl;
	std::cerr << "    0                            Worst case" << std::endl;
	std::cerr << "    1                            Minimize number of duels with highest frequency" << std::endl;
	std::cerr << "    > 1                          Minimize number of duels with highest frequency until" << std::endl;
	std::cerr << "                                 specified number is reached, then try to maximize that" << std::endl;
	std::cerr << "                                 number of duels while trying to avoid pilots not duelling" << std::endl;
	std::cerr << "    m?<integer>?               Use mean absolute deviation" << std::endl;
	std::cerr << "    no integer                   Minimize the mean absolute deviation" << std::endl;
	std::cerr << "    < 0                          Best of abs(specified number) of drawings" << std::endl;
	std::cerr << "    > 0                          Minimize the mean absolute deviation with extra cost for" << std::endl;
	std::cerr << "                                 duels with frequency 0 and with frequency >= specified" << std::endl;
	std::cerr << "                                 integer" << std::endl;
	std::cerr << "  #pilots_in_group1          Number of pilots in first group" << std::endl;
	std::cerr << "  ?#pilots_in_group2?        Number of pilots in second group" << std::endl;
	std::cerr << "  ...                        ..." << std::endl;
	std::cerr << "  ?c<integer>,<integer>?     Conflicting pilots" << std::endl;
	std::cerr << "  ..." << std::endl;
	std::cerr << "  ?T<integer>,<integer>,...? Team pilots" << std::endl;
	std::cerr << "  ..." << std::endl;
	std::cerr << "  ?t<double>?                Minimum temperature when using simulated annealing (< " << f3ksa.T_MIN << ")" << std::endl;
	std::cerr << "  ?o<path>?                  Output file, default is 'f3k.txt', use 'data' to add to 'data' directory" << std::endl;
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
    else if (argv[3][0] == 'f') {
	std::istringstream is3(&argv[3][1]);
	is3 >> max_duels;
    }
    else {
	std::cerr << "Unknown method: " << argv[3] << std::endl;
	return 1;
    }

    std::vector<int> groups;
    int tpilots = 0;
    std::vector<std::pair<int, int> > conflicts;
    std::vector<std::vector<int> > teams;
    std::string rpath;
    for(int i = 4; i < argc; i++) {
	if (argv[i][0] == 'c') {
	    std::istringstream is3(&argv[i][1]);
	    int p1 = -1;
	    int p2 = -1;
	    char c = 0;
	    is3 >> p1 >> c >> p2;
	    conflicts.push_back(std::make_pair(p1, p2));
	}
	else if (argv[i][0] == 'T') {
	    std::istringstream is3(&argv[i][1]);
	    std::vector<int> team;
	    while(is3) {
		int m;
		char c;
		is3 >> m;
		if (is3)
		    team.push_back(m);
		is3 >> c;
	    }
	    teams.push_back(team);
	}
	else if (argv[i][0] == 't') {
	    std::istringstream is3(&argv[i][1]);
	    is3 >> f3ksa.T_MIN;
	}
	else if (argv[i][0] == 'o') {
	    std::istringstream is3(&argv[i][1]);
	    is3 >> rpath;	    
	}
	else {
	    int t = 0;
	    std::istringstream is3(argv[i]);
	    is3 >> t;
	    groups.push_back(t);
	    tpilots += t;
	}
    }

    if (pilots != tpilots) {
	std::cerr << "Number of pilots not equal to sum of number of pilots per group" << std::endl;
	return 1;
    }

    Contest contest(pilots, rounds, max_duels);
    for(std::vector<int>::const_iterator I = groups.begin(); I != groups.end(); I++)
	contest.add_group_npilots(*I);
    for(std::vector<std::pair<int, int> >::const_iterator I = conflicts.begin(); I != conflicts.end(); I++) {
	if (I->first < 0 || I->first >= tpilots) {
	    std::cerr << "Invalid pilot in conflict: " << I->first << std::endl;
	    return 0;
	}
	if (I->second < 0 || I->second >= tpilots) {
	    std::cerr << "Invalid pilot in conflict: " << I->second << std::endl;
	    return 0;
	}
	contest.add_conflict(*I);
    }
    std::set<int> in_team;
    for(std::vector<std::vector<int> >::const_iterator I = teams.begin(); I != teams.end(); I++) {
	if (I->size() > groups.size()) {
	    std::cerr << "Insufficient groups (" << groups.size() << ") for team with " << I->size() << " members" << std::endl;
	    return 0;
	}
	for(std::vector<int>::const_iterator J = I->begin(); J != I->end(); J++) {
	    if (*J < 0 || *J >= tpilots) {
		std::cerr << "Invalid pilot in team: " << *J << std::endl;
		return 0;
	    }
    	    if (in_team.count(*J)) {
		std::cerr << "Invalid pilot in multiple teams: " << *J << std::endl;
		return 0;
	    }
   	    in_team.insert(*J);		
 	    std::vector<int>::const_iterator L = J;
 	    L++;
 	    for(; L != I->end(); L++) {
 		contest.add_conflict(std::make_pair(*J, *L));
 	    }
	}
    }

    if (max_duels == 0) {
	contest.worst_case();
    }
    else if (max_duels < 0) {
	contest.draw();
	if (groups.size() > 1) {
	    double cost = contest.cost();
	    Contest ccontest = contest;
	    std::cout << max_duels << " " << cost << std::endl;
	    max_duels++;
	    while(max_duels < 0) {
		ccontest.draw();
		double ccost = ccontest.cost();
		if (ccost < cost) {
		    contest = ccontest;
		    cost = ccost;
		    std::cout << max_duels << " " << cost << std::endl;
		}
		max_duels++;
	    }
	}
    }
    else {
	contest.draw();
	if (groups.size() > 1)
	    f3ksa.anneal(&contest);
    }
    
    contest.report(rpath);

    return 0;
}
