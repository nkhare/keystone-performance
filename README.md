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
  - 

4. Create Rally container
  - 

5. Setup Keystone for given scenario  
  - Start the keystone container 
    - docker run -i -t keystone  /bin/bash
  - Setup Keystone for specific scenario, like following would setup
    keystone with V2 apis
  - cd /opt/keystone-performance/
  - sh keystoneSetupMySqlDefaultV2.sh
