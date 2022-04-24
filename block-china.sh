#!/bin/bash

unknown_os ()
{
  echo "Unfortunately, your operating system distribution and version are not supported by this script."
  echo
  echo "You can override the OS detection by setting os= and dist= prior to running this script."
  echo "You can find a list of supported OSes and distributions on our website: https://packagecloud.io/docs#os_distro_version"
  echo
  echo "For example, to force Ubuntu Trusty: os=ubuntu dist=trusty ./script.sh"
  echo
  echo "Please email support@packagecloud.io and let us know if you run into any issues."
  exit 1
}

detect_os ()
{
  if [[ ( -z "${os}" ) && ( -z "${dist}" ) ]]; then
    # some systems dont have lsb-release yet have the lsb_release binary and
    # vice-versa
    if [ -e /etc/lsb-release ]; then
      . /etc/lsb-release

      if [ "${ID}" = "raspbian" ]; then
        os=${ID}
        dist=`cut --delimiter='.' -f1 /etc/debian_version`
      else
        os=${DISTRIB_ID}
        dist=${DISTRIB_CODENAME}

        if [ -z "$dist" ]; then
          dist=${DISTRIB_RELEASE}
        fi
      fi

    elif [ `which lsb_release 2>/dev/null` ]; then
      dist=`lsb_release -c | cut -f2`
      os=`lsb_release -i | cut -f2 | awk '{ print tolower($1) }'`

    elif [ -e /etc/debian_version ]; then
      # some Debians have jessie/sid in their /etc/debian_version
      # while others have '6.0.7'
      os=`cat /etc/issue | head -1 | awk '{ print tolower($1) }'`
      if grep -q '/' /etc/debian_version; then
        dist=`cut --delimiter='/' -f1 /etc/debian_version`
      else
        dist=`cut --delimiter='.' -f1 /etc/debian_version`
      fi

    else
      unknown_os
    fi
  fi

  if [ -z "$dist" ]; then
    unknown_os
  fi

  # remove whitespace from OS and dist name
  os="${os// /}"
  dist="${dist// /}"

  echo "Detected operating system as $os/$dist."
}

detect_version_id () {
  # detect version_id and round down float to integer
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    version_id=${VERSION_ID%%.*}
  elif [ -f /usr/lib/os-release ]; then
    . /usr/lib/os-release
    version_id=${VERSION_ID%%.*}
  else
    version_id="1"
  fi
}


ipset_check ()
{
  echo "Checking for ipset..."
  if command -v ipset > /dev/null; then
    echo "Detected ipset..."
  else
    echo "Installing ipset..."
    apt-get install -q -y ipset
    if [ "$?" -ne "0" ]; then
      echo "Unable to install ipset ! Your base system has a problem; please check your default OS's package repositories because ipset should work."
      echo "Repository installation aborted."
      exit 1
    fi
  fi
}

# MAIN
# --------------------------------------
ipset_check 

# Create the ipset list
ipset -N china hash:net

# remove any old list that might exist from previous runs of this script
rm /tmp/cn.zone

# Pull the latest IP set for China
wget -P /tmp http://www.ipdeny.com/ipblocks/data/countries/cn.zone 

# Add each IP address from the downloaded list into the ipset 'china'
for i in $(cat /tmp/cn.zone ); do ipset -A china $i; done

# Restore iptables
/sbin/iptables-restore < /etc/iptables.firewall.rules
