#ifndef THREADING_H
#define THREADING_H

#include <stdbool.h>
#include <pthread.h>

/**
 * This structure should be dynamically allocated and passed as
 * an argument to your thread using pthread_create.
 * It should be returned by your thread so it can be freed by
 * the joiner thread.
 */
struct thread_data {
    // Mutex pointer used for locking and unlocking
    pthread_mutex_t *mutex;

    // Wait time before trying to obtain the mutex (in milliseconds)
    int wait_to_obtain_ms;

    // Wait time before releasing the mutex (in milliseconds)
    int wait_to_release_ms;

    // True if thread completed successfully
    bool thread_complete_success;
};

/**
 * Start a thread which sleeps @param wait_to_obtain_ms number of milliseconds, then obtains the
 * mutex in @param mutex, then holds for @param wait_to_release_ms milliseconds, then releases.
 * The start_thread_obtaining_mutex function should only start the thread and should not block
 * for the thread to complete.
 * The start_thread_obtaining_mutex function should use dynamic memory allocation for thread_data
 * structure passed into the thread.  The number of threads active should be limited only by the
 * amount of available memory.
 * The thread started should return a pointer to the thread_data structure when it exits, which can be used
 * to free memory as well as to check thread_complete_success for successful exit.
 * If a thread was started successfully @param thread should be filled with the pthread_create thread ID
 * corresponding to the thread which was started.
 * @return true if the thread could be started, false if a failure occurred.
 */
bool start_thread_obtaining_mutex(pthread_t *thread, pthread_mutex_t *mutex,
                                  int wait_to_obtain_ms, int wait_to_release_ms);

#endif // THREADING_H
