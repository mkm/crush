env = Environment(LIBS = ['rt', 'readline'],
                  LIBPATH = '.')

crush = env.Program('crush', Glob('*.d') + Glob('*.c'))
