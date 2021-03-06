#!/usr/bin/ruby
# -*- coding: utf-8 -*-

def test1 threads
  db = Database::new

  algos = ["dpll","wl"]
  h = ["rand_rand","rand_mf"]
  n = (1..5).map {|x| 10*x}
  l = [3]
  k = (1..5).map {|x| 10*x}
  sample = 5                    # nombres de passages (*nb de proc)

  threads.times do 
    Thread::new do
      run_tests_cnf(n,l,k,algos,h,sample) { |problem, report| db.record(problem, report) if problem and report}  
    end
  end
  
  filter = select_data({:l => 3, :k => 10}) { |p,r| ["#{p[:algo]}+#{p[:heuristic]}", p[:n], r["Time (s)"]]}
  names = {:title => "l = 3, k = 10", :xlabel=>"n", :ylabel => "Time (s)"}

  (Thread::list - [Thread::current]).each do |t|
    t.join
  end

  db.to_gnuplot(filter,names)
end


# Avec et sans cl!
def test2(name, threads)
  db = Database::new

  algos = ["dpll"]
  h = ["jewa"]
  n = [80]
  l = [3]
  k = (1..20).map {|x| 50*x}
  cl = [true,false]
  sample = 2                    # nombres de passages (*nb de proc)
  timeout = nil
  
  threads.times do 
    Thread::new do
      run_tests_cnf(n,l,k,algos,h,cl,sample,timeout) { |problem, report| db.record(problem, report) if report}  # and problem ?
    end
  end

  (Thread::list - [Thread::current]).each do |t|
    t.join
  end

  puts "Saving"
  db.save name
  puts "Done"
end

# A lancer après test2 avec le nom de la base de données créée

def analyze_test2 name
  db = Database::new name

  filter = select_data({:l => 3},2) { |p,r| ["Cl:#{p[:cl]}", p[:k], r["Total execution (s)"]]}
  names = {:title => "n = 80, l = 3, algo dpll+jewa", :xlabel => "k", :ylabel => "Time (s)"}
  db.to_gnuplot(filter,names)
end
