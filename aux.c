#include <sys/types.h>
#include <sys/wait.h>

signed char exitStatus(pid_t pid) {
  int stat;
  waitpid(pid, &stat, 0);
  return WEXITSTATUS(stat);
}

extern char** environ;

char** getEnviron() {
  return environ;
}
