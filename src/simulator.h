#ifndef SIMULATOR_H
#define SIMULATOR_H

#include "simmer.h"
#include "process.h"
#include "resource.h"

/**
 * The simulator.
 */
class Simulator {
  /**
   * Event container. Encapsulates future processes in the event queue.
   */
  struct Event {
    double time;
    Process* process;
    int priority;
    
    Event(double time, Process* process, int priority):
      time(time), process(process), priority(priority) {}
    
    bool operator<(const Event& other) const {
      if (time == other.time)
        return priority > other.priority;
      return time > other.time;
    }
  };
  
  typedef PQUEUE<Event> PQueue;
  typedef UMAP<std::string, Entity*> EntMap;
  
public:
  std::string name;
  bool verbose;
  
  /**
   * Constructor.
   * @param name    simulator name
   * @param verbose verbose flag
   */
  Simulator(std::string name, bool verbose): name(name), verbose(verbose), now_(0) {}
  
  ~Simulator() {
    while (!event_queue.empty()) {
      if (event_queue.top().process->is_arrival())
        delete event_queue.top().process;
      event_queue.pop();
    }
  }
  
  /**
   * Reset the simulation: time, event queue, resources, processes and statistics.
   */
  void reset() {
    now_ = 0;
    while (!event_queue.empty()) {
      if (event_queue.top().process->is_arrival())
        delete event_queue.top().process;
      event_queue.pop();
    }
    foreach_ (EntMap::value_type& itr, resource_map)
      ((Resource*)itr.second)->reset();
    foreach_ (EntMap::value_type& itr, process_map) {
      ((Process*)itr.second)->reset();
      ((Process*)itr.second)->run();
    }
  }
  
  double now() { return now_; }
  
  /**
   * Schedule a future event.
   * @param   delay     delay from now()
   * @param   process   the process to schedule
   * @param   priority  additional key to execute releases before seizes if they coincide
   */
  void schedule(double delay, Process* process, int priority=0) {
    event_queue.push(Event(now_ + delay, process, priority));
  }
  
  /**
   * Get the time of the next scheduled event.
   */
  double peek() { 
    if (!event_queue.empty())
      return event_queue.top().time;
    else return -1;
  }
  
  /**
   * Process the next event. Only one step, a giant leap for mankind.
   */
  bool step() {
    if (event_queue.empty()) return 0;
    now_ = event_queue.top().time;
    event_queue.top().process->run();
    event_queue.pop();
    return 1;
    // ... and that's it! :D
  }
  
  /**
   * Executes steps until the given criterion is met.
   * @param   until   time of ending
   */
  void run(double until) {
    long int nsteps = 0;
    while ((now_ < until) && step())
      if (++nsteps % 100000 == 0)
        Rcpp::checkUserInterrupt();
  }
  
  /**
   * Add a generator of arrivals to the simulator.
   * @param   name_prefix     prefix for the arrival names
   * @param   first_activity  the first activity of a user-defined R trajectory
   * @param   dis             an user-defined R function that provides random numbers
   * @param   mon             monitoring level
   */
  bool add_generator(std::string name_prefix, 
                     Activity* first_activity, Rcpp::Function dist, int mon) {
    if (process_map.find(name_prefix) == process_map.end()) {
      Generator* gen = new Generator(this, name_prefix, mon, first_activity, dist);
      process_map[name_prefix] = gen;
      gen->run();
      return TRUE;
    }
    Rcpp::warning("process " + name + " already defined");
    return FALSE;
  }
  
  /**
   * Add a resource to the simulator.
   * @param   name          the name
   * @param   capacity      server capacity (-1 means infinity)
   * @param   queue_size    room in the queue (-1 means infinity)
   * @param   mon           whether this entity must be monitored
   * @param   preemptive    whether the resource is preemptive
   * @param   preempt_order fifo or lifo
   */
  bool add_resource(std::string name, int capacity, int queue_size, bool mon,
                    bool preemptive, std::string preempt_order) {
    if (resource_map.find(name) == resource_map.end()) {
      Resource* res;
      if (!preemptive)
        res = new Resource(this, name, mon, capacity, queue_size);
      else {
        if (preempt_order.compare("fifo") == 0)
          res = new PreemptiveResource<FIFO>(this, name, mon, capacity, queue_size);
        else
          res = new PreemptiveResource<LIFO>(this, name, mon, capacity, queue_size);
      }
      resource_map[name] = res;
      return TRUE;
    }
    Rcpp::warning("resource " + name + " already defined");
    return FALSE;
  }
  
  /**
   * Add a process that manages the capacity or the queue_size of a resource
   * given a scheduling.
   * @param   name      the resource name
   * @param   param     "capacity" or "queue_size"
   * @param   duration  vector of durations until the next value change
   * @param   value     vector of values
   */
  bool add_resource_manager(std::string name, std::string param, 
                            VEC<double> duration, VEC<int> value) {
    if (process_map.find(name) == process_map.end()) {
      EntMap::iterator search = resource_map.find(name);
      if (search == resource_map.end())
        Rcpp::stop("resource '" + name + "' not found (typo?)");
      Resource* res = (Resource*)search->second;
      
      Manager* manager;
      if (param.compare("capacity") == 0)
        manager = new Manager(this, name + "_" + param, duration, value,
                                   boost::bind(&Resource::set_capacity, res, _1));
      else manager = new Manager(this, name + "_" + param, duration, value, 
                                      boost::bind(&Resource::set_queue_size, res, _1));
      process_map[name + "_" + param] = manager;
      manager->run();
      return TRUE;
    }
    Rcpp::warning("process " + name + " already defined");
    return FALSE;
  }
  
  /**
   * Get a generator by name.
   */
  Generator* get_generator(std::string name) {
    EntMap::iterator search = process_map.find(name);
    if (search == process_map.end())
      Rcpp::stop("generator '" + name + "' not found (typo?)");
    return (Generator*)search->second;
  }
  
  /**
   * Get a resource by name.
   */
  Resource* get_resource(std::string name) {
    EntMap::iterator search = resource_map.find(name);
    if (search == resource_map.end())
      Rcpp::stop("resource '" + name + "' not found (typo?)");
    return (Resource*)search->second;
  }
  
private:
  double now_;              /**< simulation time */
  PQueue event_queue;       /**< the event queue */
  EntMap resource_map;      /**< map of resources */
  EntMap process_map;       /**< map of processes */
};

#endif
