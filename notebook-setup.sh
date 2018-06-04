#A file to copy configs into a users home directory before notebook startup
#
#
if [ ! -d /home/jovyan/work/custom/lib ]
  then
    mkdir -p /home/jovyan/work/custom/lib 
fi
if [ ! -d /home/jovyan/work/custom/bin ]
  then
    mkdir -p /home/jovyan/work/custom/bin 
fi

/usr/sbin/sshd 
