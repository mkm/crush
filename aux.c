#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>

signed char exitStatus(pid_t pid) {
  int stat;
  waitpid(pid, &stat, 0);
  return WEXITSTATUS(stat);
}

int accessExecute(const char* path) {
  return access(path, X_OK);
}

extern char** environ;

char** getEnviron() {
  return environ;
}
