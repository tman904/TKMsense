# $OpenBSD: dot.profile,v 1.9 2010/12/13 12:54:31 millert Exp $
#
# sh/ksh initialization

PATH=/sbin:/usr/sbin:/bin:/usr/bin:/usr/X11R6/bin:/usr/local/sbin:/usr/local/bin
export PATH
: ${HOME='/root'}
export HOME
umask 022

case "$-" in
*i*)    # interactive shell
	if [ -x /usr/bin/tset ]; then
		if [ X"$XTERM_VERSION" = X"" ]; then
			
		eval `/usr/bin/tset -sQ '-munknown:?vt220' $TERM`
		
		#run TKMsense
		/usr/sbin/TKMsense_V0.0.3.sh
		else
			eval `/usr/bin/tset -IsQ '-munknown:?vt220' $TERM`

		#run TKMsense 
		/usr/sbin/TKMsense_V0.0.3.sh
		fi
	fi
	;;
esac
