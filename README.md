keystone-performance
====================

Keystone Performance work

Using Docker images (On Fedora)
====================
1. Install docker 
  - yum install docker-io -y

2. Clone this repository
  - git clone https://github.com/nkhare/keystone-performance.git
  - cd keystone-performance

3. Create the Keystone container 
  - docker build -t keystone - < DockerfileKeystoneMySqlDefault 

4. Create Rally container
  - docker build -t Rally - < DockerfileRally

5. Setup Keystone for given scenario  
  - Start the keystone container 
    - docker run -i -t keystone  /bin/bash
  - Setup Keystone for specific scenario, like following would setup
    keystone with V2 apis. Run following inside the container
    - cd /opt/keystone-performance/
    - sh keystoneSetupMySqlDefaultV2.sh
  - Get the IP address of container 
    - From container 
      - ip addr | grep inet | grep eth0 | awk -F" " '{print $2}'| sed -e 's/\/.*$//'
    - From hostmachine 
      - docker inspect -format='{{.NetworkSettings.IPAddress}}' <CONTAINER ID>

6. Run the benchmark using Rally
  - Work in progress to run benchmark when subset of processes are
    running on openstack setup 
    - https://blueprints.launchpad.net/rally/+spec/single-service-support 
  - Till then to check connectivity b/w Rally and Keystone. On the Rally
    container.
    - docker run -i -t Rally  /bin/bash 
    - cd /opt/rally
    - python -i -m rally.osclients 
    >>> clients = Clients("admin", "test", "demo","http://\<IP of keystone container \>:5000/v2.0")
    >>> kclient = clients.get_keystone_client()
    >>> kclient.users.list()
