#' Seize/Release Resources
#'
#' Activities for seizing/releasing a resource, by name or a previously selected one.
#'
#' @param .trj the trajectory object.
#' @inheritParams select
#' @param resource the name of the resource.
#' @param amount the amount to seize/release, accepts either a numeric or a callable object
#' (a function) which must return a numeric.
#' @param continue a boolean (if \code{post.seize} OR \code{reject} is defined) or a pair of booleans
#' (if \code{post.seize} AND \code{reject} are defined) to indicate whether these subtrajectories
#' should continue to the next activity in the main trajectory.
#' @param post.seize an optional trajectory object which will be followed after a successful seize.
#' @param reject an optional trajectory object which will be followed if the arrival is rejected.
#'
#' @return Returns the trajectory object.
#' @seealso \code{\link{select}}, \code{\link{set_capacity}}, \code{\link{set_queue_size}},
#' \code{\link{set_capacity_selected}}, \code{\link{set_queue_size_selected}}.
#' @export
seize <- function(.trj, resource, amount=1, continue=NULL, post.seize=NULL, reject=NULL)
  UseMethod("seize")

#' @export
seize.trajectory <- function(.trj, resource, amount=1, continue=NULL, post.seize=NULL, reject=NULL)
  .trj$seize(resource, amount, 0, continue, post.seize, reject)

#' @rdname seize
#' @export
seize_selected <- function(.trj, amount=1, id=0, continue=NULL, post.seize=NULL, reject=NULL)
  UseMethod("seize_selected")

#' @export
seize_selected.trajectory <- function(.trj, amount=1, id=0, continue=NULL, post.seize=NULL, reject=NULL)
  .trj$seize(NA, amount, id, continue, post.seize, reject)

#' @rdname seize
#' @export
release <- function(.trj, resource, amount=1) UseMethod("release")

#' @export
release.trajectory <- function(.trj, resource, amount=1) .trj$release(resource, amount)

#' @rdname seize
#' @export
release_selected <- function(.trj, amount=1, id=0) UseMethod("release_selected")

#' @export
release_selected.trajectory <- function(.trj, amount=1, id=0) .trj$release(NA, amount, id)

#' Set Resource Parameters
#'
#' Activities for modifying a resource's server capacity or queue size, by name
#' or a previously selected one.
#'
#' @inheritParams seize
#' @inheritParams select
#' @inheritParams set_attribute
#' @param resource the name of the resource.
#' @param value new value to set.
#'
#' @return Returns the trajectory object.
#' @seealso \code{\link{select}}, \code{\link{seize}}, \code{\link{release}},
#' \code{\link{seize_selected}}, \code{\link{release_selected}},
#' \code{\link{get_capacity}}, \code{\link{get_queue_size}}.
#' @export
set_capacity <- function(.trj, resource, value, mod=c(NA, "+", "*"))
  UseMethod("set_capacity")

#' @export
set_capacity.trajectory <- function(.trj, resource, value, mod=c(NA, "+", "*"))
  .trj$set_capacity(resource, value, mod=mod)

#' @rdname set_capacity
#' @export
set_capacity_selected <- function(.trj, value, id=0, mod=c(NA, "+", "*"))
  UseMethod("set_capacity_selected")

#' @export
set_capacity_selected.trajectory <- function(.trj, value, id=0, mod=c(NA, "+", "*"))
  .trj$set_capacity(NA, value, id, mod=mod)

#' @rdname set_capacity
#' @export
set_queue_size <- function(.trj, resource, value, mod=c(NA, "+", "*"))
  UseMethod("set_queue_size")

#' @export
set_queue_size.trajectory <- function(.trj, resource, value, mod=c(NA, "+", "*"))
  .trj$set_queue_size(resource, value, mod=mod)

#' @rdname set_capacity
#' @export
set_queue_size_selected <- function(.trj, value, id=0, mod=c(NA, "+", "*"))
  UseMethod("set_queue_size_selected")

#' @export
set_queue_size_selected.trajectory <- function(.trj, value, id=0, mod=c(NA, "+", "*"))
  .trj$set_queue_size(NA, value, id, mod=mod)

#' Select Resources
#'
#' Activity for selecting a resource for a subsequent seize/release or setting
#' its parameters (capacity or queue size).
#'
#' @inheritParams seize
#' @param resources one or more resource names, or a callable object (a function) which
#' must return one or more resource names.
#' @param policy if \code{resources} is a character vector, this parameter determines
#' the criteria for selecting a resource among the set of policies available:
#' 'shortest-queue' selects the least busy resource, 'round-robin' selects the resources
#' in order cyclically, 'first-available' selects the first resource available,
#' and 'random' selects one at random.
#' @param id selection identifier for nested usage.
#'
#' @return Returns the trajectory object.
#' @seealso \code{\link{seize_selected}}, \code{\link{release_selected}},
#' \code{\link{set_capacity_selected}}, \code{\link{set_queue_size_selected}}.
#' @export
select <- function(.trj, resources, policy=c("shortest-queue", "round-robin",
                                             "first-available", "random"), id=0)
  UseMethod("select")

#' @export
select.trajectory <- function(.trj, resources, policy=c("shortest-queue", "round-robin",
                                             "first-available", "random"), id=0)
  .trj$select(resources, policy, id)

#' Delay
#'
#' Activity for inserting delays and execute user-defined tasks.
#'
#' @inheritParams seize
#' @param task the timeout duration supplied by either passing a numeric or a
#' callable object (a function) which must return a numeric (negative values are
#' automatically coerced to positive).
#'
#' @return Returns the trajectory object.
#' @export
timeout <- function(.trj, task) UseMethod("timeout")

#' @export
timeout.trajectory <- function(.trj, task) {
  check_args(task=c("number", "function"))
  .trj$timeout(task)
}

#' @rdname timeout
#' @inheritParams set_attribute
#' @param key the attribute name, or a callable object (a function) which
#' must return the attribute name.
#' @export
timeout_from_attribute <- function(.trj, key, global=FALSE)
  UseMethod("timeout_from_attribute")

#' @export
timeout_from_attribute.trajectory <- function(.trj, key, global=FALSE) {
  check_args(key="string", global="flag")
  .trj$timeout(key, global)
}

#' @rdname timeout
#' @details \code{timeout_from_global} is a shortcut for
#' \code{timeout_from_attribute(global=TRUE)}.
#' @export
timeout_from_global <- function(.trj, key) timeout_from_attribute(.trj, key, TRUE)

#' Set Attributes
#'
#' Activity for modifying an arrival's attributes.
#'
#' @inheritParams seize
#' @param keys the attribute name(s), or a callable object (a function) which
#' must return attribute name(s).
#' @param values numeric value(s) to set, or a callable object (a function) which
#' must return numeric value(s).
#' @param global if \code{TRUE}, the attribute will be global instead of per-arrival.
#' @param mod if set, \code{values} modify the attributes rather than substituting them.
#'
#' @return Returns the trajectory object.
#' @seealso \code{\link{get_attribute}}.
#' @export
set_attribute <- function(.trj, keys, values, global=FALSE, mod=c(NA, "+", "*"))
  UseMethod("set_attribute")

#' @export
set_attribute.trajectory <- function(.trj, keys, values, global=FALSE, mod=c(NA, "+", "*"))
  .trj$set_attribute(keys, values, global, mod=mod)

#' @rdname set_attribute
#' @details \code{set_global} is a shortcut for \code{set_attribute(global=TRUE)}.
#' @export
set_global <- function(.trj, keys, values, mod=c(NA, "+", "*"))
  set_attribute(.trj, keys, values, TRUE, mod=mod)

#' Activate/Deactivate Generators
#'
#' Activities for activating or deactivating the generation of arrivals by name.
#'
#' @inheritParams seize
#' @param generator the name of the generator or a function returning a name.
#'
#' @return Returns the trajectory object.
#' @seealso \code{\link{set_trajectory}}, \code{\link{set_distribution}}.
#' @export
activate <- function(.trj, generator) UseMethod("activate")

#' @export
activate.trajectory <- function(.trj, generator) .trj$activate(generator)

#' @rdname activate
#' @export
deactivate <- function(.trj, generator) UseMethod("deactivate")

#' @export
deactivate.trajectory <- function(.trj, generator) .trj$deactivate(generator)

#' Set Generator Parameters
#'
#' Activities for modifying a generator's trajectory or distribution by name.
#'
#' @inheritParams seize
#' @inheritParams activate
#' @param trajectory the trajectory that the generated arrivals will follow.
#'
#' @return Returns the trajectory object.
#' @seealso \code{\link{activate}}, \code{\link{deactivate}}.
#' @export
set_trajectory <- function(.trj, generator, trajectory) UseMethod("set_trajectory")

#' @export
set_trajectory.trajectory <- function(.trj, generator, trajectory)
  .trj$set_trajectory(generator, trajectory)

#' @rdname set_trajectory
#' @param distribution a function modelling the interarrival times (returning a
#' negative value stops the generator).
#' @export
set_distribution <- function(.trj, generator, distribution) UseMethod("set_distribution")

#' @export
set_distribution.trajectory <- function(.trj, generator, distribution)
  .trj$set_distribution(generator, distribution)

#' Set Prioritization Values
#'
#' Activity for modifying an arrival's prioritization values.
#'
#' @inheritParams seize
#' @inheritParams set_attribute
#' @param values expects either a vector/list or a callable object (a function)
#' returning a vector/list of three values \code{c(priority, preemptible, restart)}.
#' A negative value leaves the corresponding parameter unchanged.
#' See \code{\link{add_generator}} for more information about these parameters.
#'
#' @return Returns the trajectory object.
#' @seealso \code{\link{get_prioritization}}.
#' @export
set_prioritization <- function(.trj, values, mod=c(NA, "+", "*"))
  UseMethod("set_prioritization")

#' @export
set_prioritization.trajectory <- function(.trj, values, mod=c(NA, "+", "*"))
  .trj$set_prioritization(values, mod=mod)

#' Fork the Trajectory Path
#'
#' Activity for defining a fork with \code{N} alternative sub-trajectories.
#'
#' @inheritParams seize
#' @param option a callable object (a function) which must return an integer between
#' \code{0} and \code{N}. A return value equal to \code{0} skips the branch and
#' continues to the next activity. A returning value between \code{1} to \code{N}
#' makes the arrival to follow the corresponding sub-trajectory.
#' @param continue a vector of \code{N} booleans that indicate whether the arrival must
#' continue to the main trajectory after each sub-trajectory or not.
#' @param ... \code{N} trajectory objects describing each sub-trajectory.
#'
#' @return Returns the trajectory object.
#' @export
branch <- function(.trj, option, continue, ...) UseMethod("branch")

#' @export
branch.trajectory <- function(.trj, option, continue, ...) .trj$branch(option, continue, ...)

#' Rollback a Number of Activities
#'
#' Activity for going backwards to a previous point in the trajectory. Useful to implement loops.
#'
#' @inheritParams seize
#' @param amount the amount of activities (of the same or parent trajectories) to roll back.
#' @param times the number of repetitions until an arrival may continue.
#' @param check a callable object (a function) which must return a boolean. If
#' present, the \code{times} parameter is ignored, and the activity uses this
#' function to check whether the rollback must be done or not.
#'
#' @return Returns the trajectory object.
#' @export
rollback <- function(.trj, amount, times=Inf, check=NULL) UseMethod("rollback")

#' @export
rollback.trajectory <- function(.trj, amount, times=Inf, check=NULL) .trj$rollback(amount, times, check)

#' Leave the Trajectory
#'
#' Activity for leaving the trajectory with some probability.
#'
#' @inheritParams seize
#' @param prob a probability or a function returning a probability.
#'
#' @return Returns the trajectory object.
#' @export
leave <- function(.trj, prob) UseMethod("leave")

#' @export
leave.trajectory <- function(.trj, prob) .trj$leave(prob)

#' Renege on some Condition
#'
#' Activities for setting or unsetting a timer or a signal after which the arrival will abandon.
#'
#' @inheritParams seize
#' @param t timeout to trigger reneging, accepts either a numeric or a callable object
#' (a function) which must return a numeric.
#' @param out optional sub-trajectory in case of reneging.
#'
#' @return Returns the trajectory object.
#' @export
renege_in <- function(.trj, t, out=NULL) UseMethod("renege_in")

#' @export
renege_in.trajectory <- function(.trj, t, out=NULL) .trj$renege_in(t, out)

#' @param signal signal to trigger reneging, accepts either a string or a callable object
#' (a function) which must return a string.
#'
#' @rdname renege_in
#' @seealso \code{\link{send}}
#' @export
renege_if <- function(.trj, signal, out=NULL) UseMethod("renege_if")

#' @export
renege_if.trajectory <- function(.trj, signal, out=NULL) .trj$renege_if(signal, out)

#' @rdname renege_in
#' @export
renege_abort <- function(.trj) UseMethod("renege_abort")

#' @export
renege_abort.trajectory <- function(.trj) .trj$renege_abort()

#' Clone/Synchronize Arrivals
#'
#' Activities for defining a parallel fork and removing the copies. \code{clone}
#' replicates an arrival \code{n} times (the original one + \code{n-1} copies).
#' \code{synchronize} removes all but one clone for each set of clones.
#'
#' @inheritParams seize
#' @param n number of clones, accepts either a numeric or a callable object
#' (a function) which must return a numeric.
#' @param ... optional parallel sub-trajectories. Each clone will follow
#' a different sub-trajectory if available.
#'
#' @return Returns the trajectory object.
#' @export
clone <- function(.trj, n, ...) UseMethod("clone")

#' @export
clone.trajectory <- function(.trj, n, ...) .trj$replicate(n, ...)

#' @inheritParams seize
#' @param wait if \code{FALSE}, all clones but the first to arrive are removed.
#' if \code{TRUE} (default), all clones but the last to arrive are removed.
#' @param mon_all if \code{TRUE}, \code{get_mon_arrivals} will show one
#' line per clone.
#'
#' @rdname clone
#' @export
synchronize <- function(.trj, wait=TRUE, mon_all=FALSE) UseMethod("synchronize")

#' @export
synchronize.trajectory <- function(.trj, wait=TRUE, mon_all=FALSE) .trj$synchronize(wait, mon_all)

#' Batch/Separate Arrivals
#'
#' Activities for collecting a number of arrivals before they can continue processing
#' and splitting a previously established batch.
#'
#' @inheritParams seize
#' @param n batch size, accepts a numeric.
#' @param timeout set an optional timer which triggers batches every \code{timeout} time
#' units even if the batch size has not been fulfilled, accepts a numeric or a callable
#' object (a function) which must return a numeric (0 = disabled).
#' @param permanent if \code{TRUE}, batches cannot be split.
#' @param name optional string. Unnamed batches from different \code{batch} activities are
#' independent. However, if you want to feed arrivals from different trajectories into a
#' same batch, you need to specify a common name across all your \code{batch} activities.
#' @param rule an optional callable object (a function) which will be applied to
#' every arrival to determine whether it should be included into the batch, thus
#  it must return a boolean.
#'
#' @return Returns the trajectory object.
#' @export
batch <- function(.trj, n, timeout=0, permanent=FALSE, name="", rule=NULL) UseMethod("batch")

#' @export
batch.trajectory <- function(.trj, n, timeout=0, permanent=FALSE, name="", rule=NULL)
  .trj$batch(n, timeout, permanent, name, rule)

#' @inheritParams seize
#'
#' @rdname batch
#' @export
separate <- function(.trj) UseMethod("separate")

#' @export
separate.trajectory <- function(.trj) .trj$separate()

#' Inter-arrival Communication
#'
#' These activities enable asynchronous programming. \code{send()} broadcasts a signal or a list
#' of signals. Arrivals can subscribe to signals and (optionally) assign a handler with
#' \code{trap()}. Note that, while inside a batch, all the signals subscribed before entering
#' the batch are ignored. Upon a signal reception, the arrival stops the current activity and
#' executes the handler (if provided). Then, the execution returns to the activity following the
#' point of the interruption. \code{untrap()} can be used to unsubscribe from signals.
#' \code{wait()} blocks until a signal is received.
#'
#' @inheritParams seize
#' @param signals signal or list of signals, accepts either a string, a list of strings or a
#' callable object (a function) which must return a string or a list of strings.
#' @param delay optional timeout to trigger the signals, accepts either a numeric or a callable
#' object (a function) which must return a numeric.
#'
#' @return Returns the trajectory object.
#' @seealso \code{\link{renege_if}}
#' @export
send <- function(.trj, signals, delay=0) UseMethod("send")

#' @export
send.trajectory <- function(.trj, signals, delay=0) .trj$send(signals, delay)

#' @param handler optional trajectory object to handle a signal received.
#' @param interruptible whether the handler can be interrupted by signals.
#'
#' @rdname send
#' @export
trap <- function(.trj, signals, handler=NULL, interruptible=TRUE) UseMethod("trap")

#' @export
trap.trajectory <- function(.trj, signals, handler=NULL, interruptible=TRUE)
  .trj$trap(signals, handler, interruptible)

#' @rdname send
#' @export
untrap <- function(.trj, signals) UseMethod("untrap")

#' @export
untrap.trajectory <- function(.trj, signals) .trj$untrap(signals)

#' @rdname send
#' @export
wait <- function(.trj) UseMethod("wait")

#' @export
wait.trajectory <- function(.trj) .trj$wait()

#' Logging
#'
#' Activity for displaying messages preceded by the simulation time and the name of the arrival.
#'
#' @inheritParams seize
#' @param message the message to display, accepts either a string or a callable object
#' (a function) which must return a string.
#'
#' @return Returns the trajectory object.
#' @export
log_ <- function(.trj, message) UseMethod("log_")

#' @export
log_.trajectory <- function(.trj, message) .trj$log(message)
