#!/bin/bash
#======================================
#
# Install New Relic PHP module
#
#======================================
. /etc/cloud-env.sh
if [[ -z $NewRelicLicenseKey ]] || [[ $NewRelicLicenseKey == "0000000000000000000000000000000000000000" ]]; then
	echo "NewRelic License Key Not Provided...Exiting..."
	exit 1
else
	NR_REPO="http://yum.newrelic.com/pub/newrelic/el5/x86_64/newrelic-repo-5-3.noarch.rpm"
	NPI_INSTALL_URL="https://download.newrelic.com/npi/release/install-npi-linux-redhat-x64.sh)"
	export NR_INSTALL_SILENT=true
	export NR_INSTALL_KEY=${NewRelicLicenseKey}
	# environment variables for NPI -- New Relic Plugin Installer
	export LICENSE_KEY=${NewRelicLicenseKey}
	export UNATTENDED=true
	# function to install some helpful utilities
	install_stuff() {
		yum -y --enablerepo=epel install crudini
	}
	# function to install newrelic yum repo and use yum to install packages
	install_new_relic() {
		rpm -Uvh ${NR_REPO}
		yum -y install newrelic-php5
		newrelic-install install
		yum -y install newrelic-sysmond
		bash -c "$(curl -sSL ${NPI_INSTALL_URL})"
	}
	# function to locate and install configuration files for newrelic
	config_new_relic() {
		cp /etc/php.d/newrelic.ini /etc/php.d/newrelic.ini.orig
		if [ -r /opt/aws/bootstrap/newrelic.ini ]; then
			cp /opt/aws/bootstrap/newrelic.ini /etc/php.d/newrelic.ini
		else
			nrsysmond-config --set license_key=${NewRelicLicenseKey}
		fi
		crudini --set /etc/php.d/newrelic.ini newrelic newrelic.appname "${CodeFolder}_${CodeEnvironment}"
	}
	# function to restart newrelic and apache after newrelic.ini has been updated
	nrrestart() {
		# Commenting the line below so that httpd doesn't actually start until the end of the execution of all helper scripts.
		service httpd restart
		service newrelic-sysmond restart
	}
	## MAIN ##
	install_stuff
	install_new_relic
	config_new_relic
	nrrestart
fi
