import java.util.*;

class Group {
    public Vector pilots;
    public Group() {
	pilots = new Vector();
    }
    public Map draw(Contest contest, Round round, Integer npilots, Map cduels) {
    	int max_draws = 1000;
	int curr_draw = 0;
	pilots.clear();
	Random gen = new Random();
	do {
	    int p = gen.nextInt(contest.npilots);
	    if (!round.in_round(p) && !in_group(p) && !conflicting(contest, p)) {
		pilots.add(p);
//		PilotPair pp = new PilotPair(i, j);
//		cduels[] = cduels[] + 1;
	    }
	    curr_draw++;
	} while (pilots.size() < npilots && curr_draw < max_draws);
	return cduels;
    }
    public boolean in_group(int p) {
	return pilots.indexOf(p) != -1;
    }
    public boolean conflicting(Contest contest, int p) {
	return false; // TBD
    }
    public void print() {
	Iterator itr = pilots.iterator();
	boolean first = true;
	while(itr.hasNext()) {
	    if (!first)
		System.out.print(" ");
	    else
		first = false;
	    System.out.print(itr.next());
	}
    }
}

class Round {
    public Vector groups;
    public Round() {
	groups = new Vector();
    }
    public Map draw(Contest contest, Map cduels) {
	Map tduels = cduels;
	while(groups.size() != contest.group_npilots.size()) {
	    groups.clear();
	    cduels = tduels;
	    Iterator itr = contest.group_npilots.iterator();
	    while(itr.hasNext()) {
		Group group = new Group();
		cduels = group.draw(contest, this, (Integer)itr.next(), cduels);
		groups.add(group);
	    }
	}
	return cduels;
    }
    public boolean in_round(int p) {
	Iterator itr = groups.iterator();
	while(itr.hasNext()) {
	    if (((Group)itr.next()).in_group(p))
		return true;
	}
	return false; // TBD
    }
    public void print() {
	Iterator itr = groups.iterator();
	boolean first = true;
	while(itr.hasNext()) {
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
}

class Contest {
    public Vector rounds;
    public Map cduels;
    public Integer npilots;
    public Integer nrounds;
    public Integer ngroups;
    public Vector group_npilots;

    public Contest(Integer inpilots, Integer inrounds, Integer ingroups) {
	npilots = inpilots;
	nrounds = inrounds;
	ngroups = ingroups;
	rounds = new Vector();
	cduels = new HashMap();
	group_npilots = new Vector();
	Integer d = npilots / ngroups;
	Integer r = npilots % ngroups;
	Integer i = new Integer(0);
	for(; i < r; i++)
	    group_npilots.add(d + 1);
	for(; i < ngroups; i++)
	    group_npilots.add(d);
    }

    public void init_duels() {
	cduels.clear();
	for(Integer i = new Integer(0); i < (npilots - 1); i++)
	    for(Integer j = new Integer(i+1); j < npilots; j++)
		cduels.put(new PilotPair(i, j), new Integer(0));
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
	Iterator itr = rounds.iterator();
	while(itr.hasNext()) {
	    System.out.print("{");
	    ((Round)itr.next()).print();
	    System.out.println("}");
	}
    }
}

public class DrawContest {

   public static void main(String[] args) {
       if (args.length != 4) {
	   System.out.println("Usage: DrawContest <npilots> <nrounds> <ngroups>");
	   System.exit(1);
       }
       Integer npilots = Integer.parseInt(args[0]);
       Integer nrounds = Integer.parseInt(args[1]);
       Integer ngroups = Integer.parseInt(args[2]);
       Contest contest = new Contest(npilots, nrounds, ngroups);
       contest.draw();
       contest.print();
   }
}
