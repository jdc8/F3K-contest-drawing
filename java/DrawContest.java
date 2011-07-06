import java.util.*;

class PilotPair {
    public Integer p;
    public Integer q;
    public PilotPair(Integer ip, Integer iq) {
	if (ip <= iq) {
	    p = ip;
	    q = iq;
	}
	else {
	    p = iq;
	    q = ip;
	}
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
}

class Group {
    public Vector<Integer> pilots;
    public Group() {
	pilots = new Vector<Integer>();
    }
    public HashMap<PilotPair, Integer> draw(Contest contest, Round round, Integer npilots, HashMap<PilotPair, Integer> cduels) {
    	int max_draws = 1000;
	int curr_draw = 0;
	pilots.clear();
	Random gen = new Random();
	do {
	    Integer p = new Integer(gen.nextInt(contest.npilots));
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
    public HashMap<PilotPair, Integer> worst_case(Contest contest, HashMap<PilotPair, Integer> cduels) {
	groups.clear();
	Integer p = new Integer(0);
	for(Iterator itr = contest.group_npilots.iterator(); itr.hasNext();) {
	    Group group = new Group();
	    Integer np = (Integer)itr.next();
	    for(Integer i = 0; i < np; i++) {
		for(Iterator pitr = group.pilots.iterator(); pitr.hasNext();) {
		    PilotPair pp = new PilotPair(p, (Integer)pitr.next());
		    cduels.put(pp, cduels.get(pp) + 1);
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
}

class Contest {
    public Vector<Round> rounds;
    public HashMap<PilotPair, Integer> cduels;
    public Integer npilots;
    public Integer nrounds;
    public Integer ngroups;
    public Vector<Integer> group_npilots;

    public Contest(Integer inpilots, Integer inrounds, Integer ingroups) {
	npilots = inpilots;
	nrounds = inrounds;
	ngroups = ingroups;
	rounds = new Vector<Round>();
	cduels = new HashMap<PilotPair, Integer>();
	group_npilots = new Vector<Integer>();
	Integer d = npilots / ngroups;
	Integer r = npilots % ngroups;
	Integer i = new Integer(0);
	for(; i < r; i++)
	    group_npilots.add(d + 1);
	for(; i < ngroups; i++)
	    group_npilots.add(d);
	init_duels();
    }

    public void init_duels() {
	cduels.clear();
	for(Integer i = new Integer(0); i < (npilots - 1); i++)
	    for(Integer j = new Integer(i+1); j < npilots; j++)
		cduels.put(new PilotPair(i, j), new Integer(0));
    }
    public void worst_case() {
	rounds.clear();
	init_duels();
 	for(Integer r = 0; r < nrounds; r++) {
 	    Round round = new Round();
 	    cduels = round.worst_case(this, cduels);
 	    rounds.add(round);
 	}
    }
    public void draw() {
	rounds.clear();
	init_duels();
 	for(Integer r = 0; r < nrounds; r++) {
 	    Round round = new Round();
 	    cduels = round.draw(this, cduels);
 	    rounds.add(round);
 	}
    }
    public void print() {
	for(Iterator itr = rounds.iterator(); itr.hasNext();) {
	    System.out.print("{");
	    ((Round)itr.next()).print();
	    System.out.println("}");
	}
    }
    HashMap<Integer, Integer> sum_duel_occurences(HashMap<PilotPair, Integer> cduels) {
	HashMap<Integer, Integer> ov = new HashMap<Integer, Integer>();
	for(Iterator itr = cduels.entrySet().iterator(); itr.hasNext();) {
	    Map.Entry entry = (Map.Entry)itr.next();
	    PilotPair pp = (PilotPair)entry.getKey();
	    Integer f = (Integer)entry.getValue();
	    if (pp.p != pp.q) {
		if (ov.containsKey(f))
		    ov.put(f, ov.get(f) + 1);
		else
		    ov.put(f, new Integer(1));
	    }
	}
	return ov;
    }
    public Double cost(String costmethod) {
	HashMap<Integer, Integer> ov = sum_duel_occurences(cduels);
	if (costmethod.equals(new String("m"))) {
	    Double tm = new Double(0);
	    Double md = new Double(0);
	    for(Iterator itr = ov.entrySet().iterator(); itr.hasNext();) {
		Map.Entry entry = (Map.Entry)itr.next();
		Integer first = (Integer)entry.getKey();
		Integer second = (Integer)entry.getValue();
		tm = tm + second;
		md = md + first * second;
	    }
	    Double wad = md / tm;
	    Double ad = new Double(0);
	    for(Iterator itr = ov.entrySet().iterator(); itr.hasNext();) {
		Map.Entry entry = (Map.Entry)itr.next();
		Integer first = (Integer)entry.getKey();
		Integer second = (Integer)entry.getValue();
		ad = ad + Math.abs(first - wad) * second;
	    }
	    return ad / tm;
	}
	else {
	    Double cost = new Double(10);
	    return cost;
	}
    }
}

public class DrawContest {
    public static void draw_worst_case(Integer npilots, Integer nrounds, Integer ngroups, String costmethod) {
	Double cost = new Double(10e21);
	Integer i = new Integer(0);
	Contest contest = new Contest(npilots, nrounds, ngroups);
	contest.worst_case();
	contest.print();
	System.out.println("Cost(" + i + ") = " + contest.cost(costmethod));
    }
    public static void draw_random(Integer npilots, Integer nrounds, Integer ngroups, String costmethod, Integer ndraws) {
	Double cost = new Double(10e21);
	for(Integer i = new Integer(0); i < ndraws; i++) {
	    Contest contest = new Contest(npilots, nrounds, ngroups);
	    contest.draw();
	    Double ccost = contest.cost(costmethod);
	    if (ccost < cost) {
		contest.print();
		System.out.println("Cost(" + i + ") = " + ccost);
		cost = ccost;
	    }
	}
    }
    public static void usage() {
	System.out.println("Usage: DrawContest <npilots> <nrounds> <ngroups> <drawmethod> <costmethod> ?<args>?");
    }
    public static void main(String[] args) {
	if (args.length < 5) {
	    usage();
	    System.exit(1);
	}
	Integer npilots = Integer.parseInt(args[0]);
	Integer nrounds = Integer.parseInt(args[1]);
	Integer ngroups = Integer.parseInt(args[2]);
	String drawmethod = args[3];
	String costmethod = args[4];
	if (drawmethod.equals(new String("w")))
	    draw_worst_case(npilots, nrounds, ngroups, costmethod);
	else if (drawmethod.equals(new String("r"))) {
	    if (args.length < 6) {
		usage();
		System.out.println("       <args> = <ndraws>");
		System.exit(1);
	    }
	    Integer ndraws = Integer.parseInt(args[5]);
	    draw_random(npilots, nrounds, ngroups, costmethod, ndraws);
	}
    }
}
