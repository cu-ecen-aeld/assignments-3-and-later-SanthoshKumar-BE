#include "systemcalls.h"
#include <stdlib.h>
#include <stdarg.h>
#include <unistd.h>
#include <sys/wait.h>
#include <fcntl.h>
#include <stdbool.h>

bool do_system(const char *cmd)
{
    if (!cmd) return false;
    int ret = system(cmd);
    if (ret == -1) return false;
    return WIFEXITED(ret) && WEXITSTATUS(ret) == 0;
}

bool do_exec(int count, ...)
{
    if (count < 1) return false;

    va_list args;
    va_start(args, count);

    char *command[count+1];
    for (int i = 0; i < count; i++) command[i] = va_arg(args, char *);
    command[count] = NULL;

    va_end(args);

    pid_t pid = fork();
    if (pid < 0) return false;
    if (pid == 0) {
        execv(command[0], command);
        _exit(1);  // execv failed
    }

    int status;
    if (waitpid(pid, &status, 0) == -1) return false;
    return WIFEXITED(status) && WEXITSTATUS(status) == 0;
}

bool do_exec_redirect(const char *outputfile, int count, ...)
{
    if (count < 1) return false;

    va_list args;
    va_start(args, count);

    char *command[count+1];
    for (int i = 0; i < count; i++) command[i] = va_arg(args, char *);
    command[count] = NULL;

    va_end(args);

    pid_t pid = fork();
    if (pid < 0) return false;
    if (pid == 0) {
        int fd = open(outputfile, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (fd < 0) _exit(1);
        if (dup2(fd, STDOUT_FILENO) < 0) _exit(1);
        close(fd);
        execv(command[0], command);
        _exit(1);
    }

    int status;
    if (waitpid(pid, &status, 0) == -1) return false;
    return WIFEXITED(status) && WEXITSTATUS(status) == 0;
}
