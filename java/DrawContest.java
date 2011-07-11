import java.util.*;

class Global {
    public static boolean myrandom = false;
    public static int m_z = 12345;
    public static int m_w = 67890;
    public static Random gen = new Random();
    public static int nextInt(int n) {
	if (myrandom) {
	    m_z = 36969 * (m_z & 65535) + (m_z >> 16);
	    m_w = 18000 * (m_w & 65535) + (m_w >> 16);
	    int r = ((m_z << 16) + m_w) % n;  /* 32-bit result */
	    return r < 0 ? -r : r;
	}
	else {
	    return gen.nextInt(n);
	}
    }
    public static double nextDouble() {
	if (myrandom)
	    return (double)nextInt(65536) / 65536.0;
	else
	    return gen.nextDouble();
    }
}

class SimulatedAnnealing {
    public int ITERS_FIXED_T; // number of iterations for each T
    public double STEP_SIZE; // max step size in random walk
    public double K;  // Boltzmann constant
    public double T_INITIAL; // initial temperature
    public double MU_T;  // damping factor for temperature
    public double T_MIN; // minimum temperature
    double boltzmann(double E, double new_E, double T) {
	double x = -(new_E - E) / (K * T);
	return Math.exp(x);
    }
    double drandom() {
	return Global.nextDouble();
    }
    public Object anneal(Object x0) {
	Object x = new_copy(x0);
	Object new_x = new_copy(x0);
	Object best_x = new_copy(x0);

	double E = energy(x0);
	double best_E = E;

	double T = T_INITIAL;
	double T_factor = 1.0 / MU_T;

	System.out.print(T + " " + E + " " + best_E + " ");
	print(best_x);
	System.out.println("");

	while (T > T_MIN) {
	    for(int i = 0; i < ITERS_FIXED_T; i++) {
		new_x = copy(x);
		new_x = step(drandom(), new_x, STEP_SIZE);
		double new_E = energy(new_x);
		if (new_E < best_E) {
		    best_x = copy(new_x);
		    best_E = new_E;
		}
		if (new_E < E) {
		    if (new_E < best_E) {
			best_x = copy(new_x);
			best_E = new_E;
		    }
		    x = copy(new_x);
		    E = new_E;
		}
		else if (drandom() < boltzmann(E, new_E, T)) {
		    x = copy(new_x);
		    E = new_E;
		}
	    }
	    System.out.print(T + " " + E + " " + best_E + " ");
	    print(best_x);
	    System.out.println("");
	    T *= T_factor;
	}

	x0 = copy(best_x);
	destroy(x);
	destroy(new_x);
	destroy(best_x);
	return x0;
    }

    public SimulatedAnnealing() {
	ITERS_FIXED_T = 1000;
	STEP_SIZE = 100.0 ;
	K = 1.0;
	T_INITIAL = 0.008;
	MU_T = 1.003;
	T_MIN = 1.0e-5;
    }

    public double energy(Object xp) {
	return 0.0;
    }
    public Object step(double u, Object xp, double step_size) {
	return xp;
    }
    public void print(Object xp) {}
    public Object copy(Object source) {
	return source;
    }
    public Object new_copy(Object xp) {
	return xp;
    }
    public void destroy(Object xp) {}
}

class PilotPair implements Comparable {
    public Integer p;
    public Integer q;
    public PilotPair(Integer ip, Integer iq) {
	if (ip.intValue() <= iq.intValue()) {
	    p = ip;
	    q = iq;
	}
	else {
	    p = iq;
	    q = ip;
	}
    }
    public PilotPair(PilotPair pp) {
	p = new Integer(pp.p);
	q = new Integer(pp.q);
    }
    public boolean equals(Object obj) {
	if (this == obj)
	    return true;
	if (!(obj instanceof PilotPair))
	    return false;
	PilotPair pp = (PilotPair)obj;
	return p.equals(pp.p) && q.equals(pp.q);
    }
    public int hashCode() {
	int hash = 1;
	hash = hash * 31 + p.hashCode();
	hash = hash * 31 + q.hashCode();
	return hash;
    }
    public int compareTo(Object obj) {
	PilotPair tpp = (PilotPair)obj;
	if (p.intValue() == tpp.p.intValue()) {
	    if (q.intValue() == tpp.q.intValue())
		return 0;
	    else if (q.intValue() < tpp.q.intValue())
		return -1;
	    else
		return 1;
	}
	else if (p.intValue() < tpp.p.intValue()) {
	    return -1;
	}
	else
	    return 1;
    }
}

class StepResult {
    public boolean stepped;
    public HashMap<PilotPair, Integer> cduels;
    public StepResult(HashMap<PilotPair, Integer> icduels) {
	stepped = false;
	cduels = icduels;
    }
}

class GroupIndex {
    public Integer group;
    public Integer index;
    GroupIndex() {
	group = new Integer(-1);
	index = new Integer(-1);
    }
    GroupIndex(Integer igroup, Integer iindex) {
	group = igroup;
	index = iindex;
    }
}

class DuelOccurences {
    HashMap<Integer, Integer> ov;
    int mov;
    int Mov;
    DuelOccurences() {
	ov = new HashMap<Integer, Integer>();
	Mov = -1;
	mov = 1000000000;
    }
}


class Group {
    public Vector<Integer> pilots;
    public Group() {
	pilots = new Vector<Integer>();
    }
    public Group(Group g) {
	pilots = new Vector<Integer>();
	for(Iterator itr = g.pilots.iterator(); itr.hasNext();)
	    pilots.add(new Integer((Integer)itr.next()));
    }
    public HashMap<PilotPair, Integer> draw(Contest contest, Round round, Integer npilots, HashMap<PilotPair, Integer> cduels) {
    	int max_draws = 1000;
	int curr_draw = 0;
	pilots.clear();
	do {
	    Integer p = new Integer(Global.nextInt(contest.npilots));
	    if (!round.in_round(p) && !in_group(p) && !conflicting(contest, p)) {
		for(Iterator itr = pilots.iterator(); itr.hasNext();) {
		    PilotPair pp = new PilotPair(p, (Integer)itr.next());
		    cduels.put(pp, cduels.get(pp) + 1);
		}
		pilots.add(p);
	    }
	    curr_draw++;
	} while (pilots.size() < npilots && curr_draw < max_draws);
	return cduels;
    }
    public boolean in_group(Integer p) {
	return pilots.indexOf(p) != -1;
    }
    public boolean conflicting(Contest contest, Integer p) {
	return false; // TBD
    }
    public boolean conflicting(Contest contest, Integer p, Integer q) {
	return false; // TBD
    }
    public void print() {
	boolean first = true;
	for(Iterator itr = pilots.iterator(); itr.hasNext();) {
	    if (!first)
		System.out.print(" ");
	    else
		first = false;
	    System.out.print(itr.next());
	}
    }
}

class Round {
    public Vector<Group> groups;
    public Round() {
	groups = new Vector<Group>();
    }
    public Round(Round r) {
	groups = new Vector<Group>();
	for(Iterator itr = r.groups.iterator(); itr.hasNext();)
	    groups.add(new Group((Group)itr.next()));
    }
    public HashMap<PilotPair, Integer> worst_case(Contest contest, HashMap<PilotPair, Integer> cduels) {
	groups.clear();
	Integer p = new Integer(0);
	for(Iterator itr = contest.group_npilots.iterator(); itr.hasNext();) {
	    Group group = new Group();
	    Integer np = (Integer)itr.next();
	    for(int i = 0; i < np.intValue(); i++) {
		for(Iterator pitr = group.pilots.iterator(); pitr.hasNext();) {
		    PilotPair pp = new PilotPair(p, (Integer)pitr.next());
		    cduels.put(pp, cduels.get(pp).intValue() + 1);
		}
		group.pilots.add(p++);
	    }
	    groups.add(group);
	}
	return cduels;
    }
    public HashMap<PilotPair, Integer> draw(Contest contest, HashMap<PilotPair, Integer> cduels) {
	HashMap<PilotPair, Integer> tduels = cduels;
	while(groups.size() != contest.group_npilots.size()) {
	    groups.clear();
	    cduels = tduels;
	    for(Iterator itr = contest.group_npilots.iterator(); itr.hasNext();) {
		Group group = new Group();
		cduels = group.draw(contest, this, (Integer)itr.next(), cduels);
		groups.add(group);
	    }
	}
	return cduels;
    }
    public boolean in_round(Integer p) {
	for(Iterator itr = groups.iterator(); itr.hasNext();) {
	    if (((Group)itr.next()).in_group(p))
		return true;
	}
	return false; // TBD
    }
    public void print() {
	boolean first = true;
	for(Iterator itr = groups.iterator(); itr.hasNext();) {
	    if (first)
		first = false;
	    else
		System.out.print(" ");
	    System.out.print("{");
	    ((Group)itr.next()).print();
	    System.out.print("}");
	}
    }
    HashMap<PilotPair, Integer> remove_duels(Integer p, Integer g, HashMap<PilotPair, Integer> cduels) {
	for(Iterator itr = groups.elementAt(g).pilots.iterator(); itr.hasNext();) {
	    Integer i = (Integer)itr.next();
	    if (i.intValue() != p.intValue()) {
		PilotPair pp = new PilotPair(p, i);
		cduels.put(pp, cduels.get(pp).intValue() - 1);
	    }
	}
	return cduels;
    }
    HashMap<PilotPair, Integer> add_duels(Integer p, Integer g, HashMap<PilotPair, Integer> cduels) {
	for(Iterator itr = groups.elementAt(g).pilots.iterator(); itr.hasNext();) {
	    Integer i = (Integer)itr.next();
	    if (i.intValue() != p.intValue()) {
		PilotPair pp = new PilotPair(p, i);
		cduels.put(pp, cduels.get(pp).intValue() + 1);
	    }
	}
	return cduels;
    }
    public StepResult stepr(Contest contest, HashMap<PilotPair, Integer> cduels) {
	StepResult sr = new StepResult(cduels);
	Integer rg0 = new Integer(Global.nextInt(groups.size()));
	Integer rg1 = rg0;
	if (groups.size() > 1) {
	    do {
		rg1 = new Integer(Global.nextInt(groups.size()));
	    } while (rg0.equals(rg1));
	}
	Integer rp0 =  new Integer(Global.nextInt(groups.elementAt(rg0).pilots.size()));
	Integer rp1 =  new Integer(Global.nextInt(groups.elementAt(rg1).pilots.size()));
	Integer p = groups.elementAt(rg0).pilots.elementAt(rp0);
	Integer q = groups.elementAt(rg1).pilots.elementAt(rp1);
	if (groups.elementAt(rg0).conflicting(contest, q, p))
	    return sr;
	if (groups.elementAt(rg1).conflicting(contest, p, q))
	    return sr;
	sr.cduels = remove_duels(p, rg0, sr.cduels);
	sr.cduels = remove_duels(q, rg1, sr.cduels);
	groups.elementAt(rg0).pilots.set(rp0, q);
	groups.elementAt(rg1).pilots.set(rp1, p);
	sr.cduels = add_duels(p, rg1, sr.cduels);
	sr.cduels = add_duels(q, rg0, sr.cduels);
	sr.stepped = true;
	return sr;
    }
    GroupIndex group_and_index(Integer p) {
	Integer pg = new Integer(0);
	for(Iterator gitr = groups.iterator(); gitr.hasNext();) {
	    Group g = (Group)gitr.next();
	    Integer pi = new Integer(0);
	    for(Iterator itr = g.pilots.iterator(); itr.hasNext();) {
		Integer q = (Integer)itr.next();
		if (p.equals(q)) {
		    return new GroupIndex(pg, pi);
		}
		pi++;
	    }
	    pg++;
	}
	return new GroupIndex();
    }
    public StepResult step0(Contest contest, Integer p, Integer q, HashMap<PilotPair, Integer> cduels) {
	StepResult sr = new StepResult(cduels);
	GroupIndex pgi = group_and_index(p);
	GroupIndex qgi = group_and_index(q);
	Integer r = new Integer(0);
	do {
	    r = new Integer(Global.nextInt(groups.elementAt(pgi.group).pilots.size()));
	} while (r.equals(pgi.index));
	Integer rtmp = groups.elementAt(pgi.group).pilots.elementAt(r);
	Integer qtmp = groups.elementAt(qgi.group).pilots.elementAt(qgi.index);
	if (groups.elementAt(pgi.group).conflicting(contest, qtmp, rtmp))
	    return sr;
	if (groups.elementAt(qgi.group).conflicting(contest, rtmp, qtmp))
	    return sr;
	sr.cduels = remove_duels(rtmp, pgi.group, sr.cduels);
	sr.cduels = remove_duels(qtmp, qgi.group, sr.cduels);
	groups.elementAt(pgi.group).pilots.set(r, qtmp);
	groups.elementAt(qgi.group).pilots.set(qgi.index, rtmp);
	sr.cduels = add_duels(rtmp, qgi.group, sr.cduels);
	sr.cduels = add_duels(qtmp, pgi.group, sr.cduels);
	sr.stepped = true;	
	return sr;
    }
    public StepResult stepm(Contest contest, Integer p, Integer q, HashMap<PilotPair, Integer> cduels) {
	StepResult sr = new StepResult(cduels);
	GroupIndex pgi = group_and_index(p);
	GroupIndex qgi = group_and_index(q);
	if (!pgi.group.equals(qgi.group))
	    return sr;
	Integer rg = new Integer(0);
	do {
	    rg = new Integer(Global.nextInt(groups.size()));
	} while (rg.equals(pgi.group));
	int ri = new Integer(Global.nextInt(groups.elementAt(rg).pilots.size()));
	Integer ptmp = groups.elementAt(pgi.group).pilots.elementAt(pgi.index);
	Integer rtmp = groups.elementAt(rg).pilots.elementAt(ri);
	if (groups.elementAt(pgi.group).conflicting(contest, rtmp, ptmp))
	    return sr;
	if (groups.elementAt(rg).conflicting(contest, ptmp, rtmp))
	    return sr;
	sr.cduels = remove_duels(ptmp, pgi.group, sr.cduels);
	sr.cduels = remove_duels(rtmp, rg, sr.cduels);
	groups.elementAt(pgi.group).pilots.set(pgi.index, rtmp);
	groups.elementAt(rg).pilots.set(ri, ptmp);
	sr.cduels = add_duels(rtmp, pgi.group, sr.cduels);
	sr.cduels = add_duels(ptmp, rg, sr.cduels);
	sr.stepped = true;	
	return sr;
    }
}

class Contest {
    public Vector<Round> rounds;
    public HashMap<PilotPair, Integer> cduels;
    public Integer npilots;
    public Integer nrounds;
    public Integer ngroups;
    public String cost_method;
    public Integer max_duels;
    public Integer max_conflicted_step_tries;
    public Vector<Integer> group_npilots;

    public Contest(Integer inpilots, Integer inrounds, Integer ingroups, String icost_method, Integer imax_duels) {
	npilots = inpilots;
	nrounds = inrounds;
	ngroups = ingroups;
	cost_method = icost_method;
	max_duels = imax_duels;
	max_conflicted_step_tries = new Integer(1000);
	rounds = new Vector<Round>();
	cduels = new HashMap<PilotPair, Integer>();
	group_npilots = new Vector<Integer>();
	Integer d = npilots.intValue() / ngroups.intValue();
	Integer r = npilots.intValue() % ngroups.intValue();
	int i = 0;
	for(; i < r.intValue(); i++)
	    group_npilots.add(new Integer(d.intValue() + 1));
	for(; i < ngroups.intValue(); i++)
	    group_npilots.add(d);
	init_duels();
    }
    public Contest(Contest c) {
	rounds = new Vector<Round>();
	for(Iterator itr = c.rounds.iterator(); itr.hasNext();)
	    rounds.add(new Round((Round)itr.next()));
	cduels = new HashMap<PilotPair, Integer>();
	for(Iterator itr = c.cduels.entrySet().iterator(); itr.hasNext();) {
	    Map.Entry entry = (Map.Entry)itr.next();
	    PilotPair pp = (PilotPair)entry.getKey();
	    Integer f = (Integer)entry.getValue();
	    cduels.put(new PilotPair(pp), new Integer(f));
	}
	npilots = new Integer(c.npilots);
	nrounds = new Integer(c.nrounds);
	ngroups = new Integer(c.ngroups);
	cost_method = new String(c.cost_method);
	max_duels = new Integer(c.max_duels);
	max_conflicted_step_tries = new Integer(c.max_conflicted_step_tries);
    }
    public void init_duels() {
	cduels.clear();
	for(int i = 0; i < (npilots.intValue() - 1); i++)
	    for(int j = i + 1; j < npilots.intValue(); j++)
		cduels.put(new PilotPair(new Integer(i), new Integer(j)), new Integer(0));
    }
    public void worst_case() {
	rounds.clear();
	init_duels();
 	for(int r = 0; r < nrounds.intValue(); r++) {
 	    Round round = new Round();
 	    cduels = round.worst_case(this, cduels);
 	    rounds.add(round);
 	}
    }
    public void draw() {
	rounds.clear();
	init_duels();
 	for(int r = 0; r < nrounds.intValue(); r++) {
 	    Round round = new Round();
 	    cduels = round.draw(this, cduels);
 	    rounds.add(round);
 	}
    }
    public void print() {
	for(Iterator itr = rounds.iterator(); itr.hasNext();) {
	    ((Round)itr.next()).print();
	    System.out.println();
	}
	DuelOccurences docc = sum_duel_occurences();
	System.out.print("Cost: " + cost() + " MAD: " + mean_absolute_deviation(docc.ov));
 	for(Iterator itr = docc.ov.entrySet().iterator(); itr.hasNext();) {
 	    Map.Entry entry = (Map.Entry)itr.next();
 	    Integer first = (Integer)entry.getKey();
 	    Integer second = (Integer)entry.getValue();
 	    System.out.print(" " + first + ":" + second);
 	}
	System.out.println("");
    }
    public DuelOccurences sum_duel_occurences() {
	DuelOccurences docc = new DuelOccurences();
	for(Iterator itr = cduels.entrySet().iterator(); itr.hasNext();) {
	    Map.Entry entry = (Map.Entry)itr.next();
	    PilotPair pp = (PilotPair)entry.getKey();
	    Integer f = (Integer)entry.getValue();
	    if (!pp.p.equals(pp.q)) {
		if (docc.ov.containsKey(f))
		    docc.ov.put(f, new Integer(docc.ov.get(f).intValue() + 1));
		else
		    docc.ov.put(f, new Integer(1));
	    }
	    if (f.intValue() < docc.mov)
		docc.mov = f.intValue();
	    if (f.intValue() > docc.Mov)
		docc.Mov = f.intValue();
	}
	return docc;
    }
    public double mean_absolute_deviation() {
	DuelOccurences docc = sum_duel_occurences();
	return mean_absolute_deviation(docc.ov);
    }
    public double mean_absolute_deviation(HashMap<Integer, Integer> ov) {
	double tm = 0;
	double md = 0;
	for(Iterator itr = ov.entrySet().iterator(); itr.hasNext();) {
	    Map.Entry entry = (Map.Entry)itr.next();
	    int first = ((Integer)entry.getKey()).intValue();
	    int second = ((Integer)entry.getValue()).intValue();
	    tm = tm + second;
	    md = md + first * second;
	}
	double wad = md / tm;
	double ad = 0;
	for(Iterator itr = ov.entrySet().iterator(); itr.hasNext();) {
	    Map.Entry entry = (Map.Entry)itr.next();
	    int first = ((Integer)entry.getKey()).intValue();
	    int second = ((Integer)entry.getValue()).intValue();
	    ad = ad + Math.abs(first - wad) * second;
	}
	return ad / tm;
    }
    public double cost_function() {
	DuelOccurences docc = sum_duel_occurences();
	return cost_function(docc.ov, docc.Mov);
    }
    public double cost_function(HashMap<Integer, Integer> ov, int Mov) {
	double cost = Mov * 1e10;
	if (Mov <= max_duels.intValue()) {
	    if (ov.containsKey(new Integer(0)))
		cost = cost + ov.get(new Integer(0)).intValue() * 1e7;
	    for(Integer i = new Integer(0); i <= max_duels; i++)
		if (ov.containsKey(i))
		    cost = cost - ov.get(i) * 1e3;
	}
	else
	    cost = cost + 1e6 * ov.get(Mov).intValue();
	return cost;
    }
    public double cost() {
	DuelOccurences docc = sum_duel_occurences();
	if (cost_method.equals(new String("m"))) {
	    double cost = mean_absolute_deviation(docc.ov);
	    if (max_duels.intValue() >= 0) {
		if (docc.ov.containsKey(new Integer(0))) {
		    cost += docc.ov.get(new Integer(0)).intValue() * 0.002;
		}
		for(int i = max_duels.intValue(); i <= docc.Mov; i++)
		    if (docc.ov.containsKey(new Integer(i))) {
			cost += docc.ov.get(new Integer(i)).intValue() * 0.002 * Math.pow(10.0, i - max_duels.intValue());
		    }
	    }
	    return cost;
	}
	else {
	    return cost_function(docc.ov, docc.Mov);
	}
    }
    Integer step0(double u, Integer ii) {
	int i = ii.intValue();
	Vector<PilotPair> eduels0 = new Vector<PilotPair>();
	for(Iterator itr = cduels.entrySet().iterator(); itr.hasNext();) {
	    Map.Entry entry = (Map.Entry)itr.next();
	    PilotPair pp = (PilotPair)entry.getKey();
	    Integer f = (Integer)entry.getValue();
	    if (f.intValue() == 0)
		eduels0.add(pp);
	}
//	Collections.sort(eduels0);
	for(; i < u && eduels0.size() > 0; i++) {
	    boolean stepped = false;
	    int curr_try = new Integer(0);
	    do {
		curr_try++;
		int rr = Global.nextInt(nrounds);
		int r0 = Global.nextInt(eduels0.size());
		StepResult sr = rounds.elementAt(rr).step0(this, eduels0.elementAt(r0).p, eduels0.elementAt(r0).q, cduels);
		if (sr.stepped) {
		    stepped = sr.stepped;
		    cduels = sr.cduels;
		    eduels0.remove(r0);
		}
	    } while(!stepped && curr_try < max_conflicted_step_tries.intValue());
	}
	return new Integer(i);
    }
    Integer stepm(double u, Integer mov, Integer ii) {
	int i = ii.intValue();
	Vector<PilotPair> eduelsm = new Vector<PilotPair>();
	for(Iterator itr = cduels.entrySet().iterator(); itr.hasNext();) {
	    Map.Entry entry = (Map.Entry)itr.next();
	    PilotPair pp = (PilotPair)entry.getKey();
	    Integer f = (Integer)entry.getValue();
	    if (f.equals(mov))
		eduelsm.add(pp);
	}
//	Collections.sort(eduelsm);
	for(; i < u && eduelsm.size() > 0; i++) {
	    boolean stepped = false;
	    int curr_try = 0;
	    do {
		curr_try++;
		int rr = Global.nextInt(nrounds);
		int r0 = Global.nextInt(eduelsm.size());
		StepResult sr = rounds.elementAt(rr).stepm(this, eduelsm.elementAt(r0).p, eduelsm.elementAt(r0).q, cduels);
		if (sr.stepped) {
		    stepped = sr.stepped;
		    cduels = sr.cduels;
		    eduelsm.remove(r0);
		}
	    } while(!stepped && curr_try < max_conflicted_step_tries.intValue());
	}
	return new Integer(i);
    }
    Integer stepr(double u, Integer i) {
	for(; i < u; i++) {
	    boolean stepped = false;
	    int curr_try = 0;
	    do {
		curr_try++;
		int rr = Global.nextInt(nrounds);
		StepResult sr = rounds.elementAt(rr).stepr(this, cduels);
		if (sr.stepped) {
		    stepped = sr.stepped;
		    cduels = sr.cduels;
		}
	    } while (!stepped && curr_try < max_conflicted_step_tries.intValue());
	}
	return i;
    }
    public void step(double u, double step_size) {
	DuelOccurences docc = sum_duel_occurences();
	if (cost_method.equals(new String("m"))) {
	    Integer i = new Integer(0);
	    i = step0(1+u*100, i);
	    i = stepm(1+u*100, new Integer(docc.Mov), i);
	    i = stepm(1+u*100, new Integer(docc.mov), i);
	    i = stepr(1+u*10, i);
	}
	else if (docc.Mov > max_duels.intValue()) {
	    Integer i = new Integer(0);
	    i = stepr(u*100, i);
	}
	else {
	    if (docc.ov.containsKey(new Integer(0))) {
		Integer i = new Integer(0);
		i = step0(u*10, i);
		i = stepm(u*10, new Integer(docc.Mov), i);
	    }
	    else {
		Integer i = new Integer(0);
		i = stepm(u*10, new Integer(docc.Mov), i);
		i = stepr(u*10, i);
	    }
	}
	
    }
}

class F3KSA extends SimulatedAnnealing {
    public double energy(Object xp) {
	return ((Contest)xp).cost();
    }
    public Object step(double u, Object xp, double step_size) {
	((Contest)xp).step(u, step_size);
	return xp;
    }
    public void print(Object xp) {
	Contest c = (Contest)xp;
	DuelOccurences docc = c.sum_duel_occurences();
	System.out.print(" " + c.cost() + " " + c.mean_absolute_deviation(docc.ov));
	for(Iterator itr = docc.ov.entrySet().iterator(); itr.hasNext();) {
	    Map.Entry entry = (Map.Entry)itr.next();
	    Integer first = (Integer)entry.getKey();
	    Integer second = (Integer)entry.getValue();
	    System.out.print(" " + first + ":" + second);
	}
    }
    public Object copy(Object source) {
	return new Contest((Contest)source);
    }
    public Object new_copy(Object xp) {
	return new Contest((Contest)xp);
    }
}

public class DrawContest {
    public static void draw_worst_case(Integer npilots, Integer nrounds, Integer ngroups, String costmethod, Integer max_duels) {
	double cost = 10e21;
	Contest contest = new Contest(npilots, nrounds, ngroups, costmethod, max_duels);
	contest.worst_case();
	contest.print();
	System.out.println("Cost = " + contest.cost_function() + "/" + contest.mean_absolute_deviation());
    }
    public static void draw_random(Integer npilots, Integer nrounds, Integer ngroups, String costmethod, Integer ndraws, Integer max_duels) {
	double cost = 10e21 ;
	for(int i = 0; i < ndraws.intValue(); i++) {
	    Contest contest = new Contest(npilots, nrounds, ngroups, costmethod, max_duels);
	    contest.draw();
	    double ccost = contest.cost();
	    if (ccost < cost) {
		contest.print();
		System.out.println("Cost(" + i + ") = " + ccost + "/" + contest.cost_function() + "/" + contest.mean_absolute_deviation());
		cost = ccost;
	    }
	}
    }
    public static void draw_siman(Integer npilots, Integer nrounds, Integer ngroups, String costmethod, Integer max_duels) {
	F3KSA f3ksa = new F3KSA();
	Contest contest = new Contest(npilots, nrounds, ngroups, costmethod, max_duels);
	contest.draw();
	contest = (Contest)f3ksa.anneal(contest);
	contest.print();
	System.out.println("Cost = " + contest.cost_function());
    }
    public static void usage() {
	System.out.println("Usage: DrawContest <npilots> <nrounds> <ngroups> <costmethod> <max_duels> <drawmethod> ?<args>?");
    }
    public static void main(String[] args) {
	if (args.length < 6) {
	    usage();
	    System.exit(1);
	}
	Integer npilots = Integer.parseInt(args[0]);
	Integer nrounds = Integer.parseInt(args[1]);
	Integer ngroups = Integer.parseInt(args[2]);
	String costmethod = args[3];
	Integer max_duels = Integer.parseInt(args[4]);
	String drawmethod = args[5];

	if (drawmethod.equals(new String("w")))
	    draw_worst_case(npilots, nrounds, ngroups, costmethod, max_duels);
	else if (drawmethod.equals(new String("r"))) {
	    if (args.length < 7) {
		usage();
		System.out.println("       <args> = <ndraws>");
		System.exit(1);
	    }
	    Integer ndraws = Integer.parseInt(args[6]);
	    draw_random(npilots, nrounds, ngroups, costmethod, ndraws, max_duels);
	}
	else if (drawmethod.equals(new String("s"))) {
	    draw_siman(npilots, nrounds, ngroups, costmethod, max_duels);
	}
    }
}
