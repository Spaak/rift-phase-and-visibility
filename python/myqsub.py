# Copyright 2019 Eelke Spaak, Donders Institute, Nijmegen
# Licensed under GPLv3
#
# Use as:
#
# myqsub.qsub('walltime=01:00:00,mem=4gb', 'mymodule', 'myfunction', range(10), power=3)
#
# to execute mymodule.myfunction 10 times with arguments 0-9, and kwarg power=3.
# Multiple arguments are supported (each iterable needs to be of the same length),
# and multiple kwargs as well (kwargs are passed as-is to each job).
#
# 2nd example to understand multiple argument lists:
#
# myqsub.qsub('walltime=00:20:00,mem=4gb', 'mymodule', 'computeproduct', [1,2,3], [4,5,6])
#
# will launch computeproduct(1,4), computeproduct(2,5), and computeproduct(3,6).
#
# You can specify a logdir for stderr and stdout logs of the jobs, by default this
# is <userhome>/.pythonjobs/<timestamp>.
#
# Note myqsub.qsub does not capture job output. It is recommended to have all job output
# go via disk. The same goes for elaborate job input. myqsub.qsub will print job argumenst
# into text, so it's recommended to only use numbers (for kwargs, strings will work).

import os
from os.path import expanduser
import numpy as np
from datetime import datetime

def qsub(reqstring, module, fun, *args, logdir=None, **kwargs):
    nargs = len(args)
    njob = len(args[0])

    pythoncmd = 'python'

    batchid = datetime.now().strftime('%Y-%m-%dT%H:%M:%S')
    if logdir is None:
        logdir = expanduser('~/.pythonjobs/')
    batchdir = logdir + batchid
    os.mkdir(batchdir)

    for k, thisargs in enumerate(zip(*args)):
        argslist = ','.join([str(x) for x in thisargs])
        pythonscript = 'import os; os.chdir(\'{}\'); from {} import {}; kwargs={}; {}({}, **kwargs)'.format(os.getcwd(), module,
            fun, kwargs, fun, argslist)

        # escape the python script so that ' is output correctly by echo
        pythonscript = pythonscript.replace("'", "'\\''")
        pythoncmd = 'python -c "{}"'.format(pythonscript)

        # log files
        logfile = '{}/j{}_{}'.format(batchdir, thisargs[0], fun)

        # note the -V which ensures the child job inherits the proper environment
        qsubcmd = 'qsub -o /dev/null -e /dev/null -V -l {} -N j{}_{}'.format(
            reqstring, thisargs[0], fun)

        # make sure each process gets its own Theano compiledir
        # (not very efficient, but unfortunately necessary)
        # this is only relevant if you're using Theano, and should be harmless otherwise
        theano_flags = 'base_compiledir=$TMPDIR/theanocompile-{}'.format(str(round(np.random.rand()*1e9)))

        fullcmd = 'echo \'export THEANO_FLAGS="{}"; {} >{}.out 2>{}.err\' | {}'.format(
            theano_flags, pythoncmd, logfile, logfile, qsubcmd)

        os.system(fullcmd)
        # print(fullcmd)
