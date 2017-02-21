name              "supervisor"
maintainer        "BuyerQuest, Inc."
maintainer_email  "itops@buyerquest.com"
license           "Apache 2.0"
description       "Installs supervisor and provides resources to configure services; this is a fork of the supervisor cookbook from Noah Kantrowitz <noah@coderanger.net> which seems to no longer be maintained"
version           "0.5.0"

recipe "supervisor", "Installs and configures supervisord"

depends "python"

%w{ ubuntu debian redhat centos fedora amazon smartos raspbian }.each do |os|
  supports os
end
