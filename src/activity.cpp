#include "entity.h"
#include "simulator.h"
#include "activity.h"

template <typename T>
inline T execute_call(Rcpp::Function call, Arrival* arrival, bool provide_attrs) {
  if (provide_attrs)
    return Rcpp::as<T>(call(Rcpp::wrap(*arrival->get_attributes())));
  else return Rcpp::as<T>(call());
}

template <>
void Seize<int>::print(int indent) {
  Activity::print(indent);
  Rcpp::Rcout << "amount: " << amount << " }" << std::endl;
}

template <>
void Seize<Rcpp::Function>::print(int indent) {
  Activity::print(indent);
  Rcpp::Rcout << "amount: function() }" << std::endl;
}

template <>
double Seize<int>::run(Arrival* arrival) {
  return arrival->sim->get_resource(resource)->seize(arrival, amount, 
                                    priority, preemptible, restart);
}

template <>
double Seize<Rcpp::Function>::run(Arrival* arrival) {
  return arrival->sim->get_resource(resource)->seize(arrival, 
                                    execute_call<int>(amount, arrival, provide_attrs), 
                                    priority, preemptible, restart);
}

template <>
void Release<int>::print(int indent) {
  Activity::print(indent);
  Rcpp::Rcout << "amount: " << amount << " }" << std::endl;
}

template <>
void Release<Rcpp::Function>::print(int indent) {
  Activity::print(indent);
  Rcpp::Rcout << "amount: function() }" << std::endl;
}

template <>
double Release<int>::run(Arrival* arrival) {
  return arrival->sim->get_resource(resource)->release(arrival, amount);
}

template <>
double Release<Rcpp::Function>::run(Arrival* arrival) {
  return arrival->sim->get_resource(resource)->release(arrival, 
                                    execute_call<int>(amount, arrival, provide_attrs));
}

template <>
void Timeout<double>::print(int indent) {
  Activity::print(indent);
  Rcpp::Rcout << "delay: " << delay << " }" << std::endl;
}

template <>
void Timeout<Rcpp::Function>::print(int indent) {
  Activity::print(indent);
  Rcpp::Rcout << "task: function() }" << std::endl;
}

template <>
double Timeout<double>::run(Arrival* arrival) { return std::abs(delay); }

template <>
double Timeout<Rcpp::Function>::run(Arrival* arrival) {
  return std::abs(execute_call<double>(delay, arrival, provide_attrs));
}

template <>
void SetAttribute<double>::print(int indent) {
  Activity::print(indent);
  Rcpp::Rcout << "key: " << key << ", value: " << value << " }" << std::endl;
}

template <>
void SetAttribute<Rcpp::Function>::print(int indent) {
  Activity::print(indent);
  Rcpp::Rcout << "key: " << key << ", value: function() }" << std::endl;
}

template <>
double SetAttribute<double>::run(Arrival* arrival) {
  return arrival->set_attribute(key, value);
}

template <>
double SetAttribute<Rcpp::Function>::run(Arrival* arrival) {
  return arrival->set_attribute(key, 
                                execute_call<double>(value, arrival, provide_attrs));
}

double Branch::run(Arrival* arrival) {
  if (pending.find(arrival) != pending.end())
    pending.erase(arrival);
  else {
    unsigned int i = execute_call<unsigned int>(option, arrival, provide_attrs);
    if (i < 1 || i > path.size())
      Rcpp::stop("index out of range");
    selected = path[i-1];
    if (merge[i-1])
      pending.insert(arrival);
  }
  return 0;
}

template <>
void Rollback<int>::print(int indent) {
  if (!cached) cached = goback();
  Activity::print(indent);
  Rcpp::Rcout << "amount: " << amount << " (" << cached->name << "), ";
  if (times >= 0)
    Rcpp::Rcout << "times: " << times << " }" << std::endl;
  else
    Rcpp::Rcout << "times: Inf }" << std::endl;
}

template <>
void Rollback<Rcpp::Function>::print(int indent) {
  if (!cached) cached = goback();
  Activity::print(indent);
  Rcpp::Rcout << "amount: " << amount << " (" << cached->name << "), ";
  Rcpp::Rcout << "check: function() }" << std::endl;
}

template <>
double Rollback<int>::run(Arrival* arrival) {
  if (times >= 0) {
    if (pending.find(arrival) == pending.end()) 
      pending[arrival] = times;
    if (!pending[arrival]) {
      pending.erase(arrival);
      return 0;
    }
    pending[arrival]--;
  }
  
  if (!cached) cached = goback();
  selected = cached;
  return 0;
}

template <>
double Rollback<Rcpp::Function>::run(Arrival* arrival) {
  if (!execute_call<bool>(times, arrival, provide_attrs)) return 0;
  if (!cached) cached = goback();
  selected = cached;
  return 0;
}
