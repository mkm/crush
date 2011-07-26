env = Environment(LIBS = ['rt', 'readline'],
                  LIBPATH = '.')

destdir = ARGUMENTS.get('destdir', '/usr')

crush = env.Program('crush', Glob('*.d') + Glob('*.c'))
env.Install(destdir + '/bin', crush)
env.Alias('install', destdir)
