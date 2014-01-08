# start Mysql
/usr/bin/mysqld_safe  &
until mysql -e 'select 1'; do sleep 1; done

# Setup keystone 
useradd keystone

## Copy the configuration files to /etc and change sql/database configuration.
mkdir -p /etc/keystone
cp -r /opt/keystone/etc/* /etc/keystone/
cp /opt/keystone/etc/keystone.conf.sample /etc/keystone/keystone.conf
openstack-config --set /etc/keystone/keystone.conf database connection mysql://root:@localhost/keystone

## Initialize Keystone database  
openstack-db --init --service keystone -y --rootpw ""

## Setup for PKI tokens
keystone-manage pki_setup --keystone-user keystone --keystone-group keystone
 
export IP=$(ip addr | grep inet | grep eth0 | awk -F" " '{print $2}'| sed -e 's/\/.*$//')
export SERVICE_TOKEN=$(openssl rand -hex 10)
export SERVICE_ENDPOINT=http://$IP:35357/v2.0
echo $SERVICE_TOKEN > /tmp/ks_admin_token

## Setup admin token
openstack-config --set /etc/keystone/keystone.conf DEFAULT admin_token $SERVICE_TOKEN

## Start Keystone 
keystone-all --config-file /etc/keystone/keystone.conf &

sleep 5 

## Create Keystone service 
keystone service-create --name keystone --type identity --description "Keystone Identity Service"

> ~/keystonerc_admin
echo "export OS_USERNAME=admin" >> ~/keystonerc_admin
echo "export OS_TENANT_NAME=admin" >> ~/keystonerc_admin
echo "export OS_PASSWORD=test" >> ~/keystonerc_admin
echo "export OS_AUTH_URL=http://$IP:35357/v2.0/" >> ~/keystonerc_admin
echo "export PS1='[\u@\h \W(keystone_admin)]\$ '" >> ~/keystonerc_admin
source ~/keystonerc_admin

## Create Keystone endpoints 
KEYSTONE_SERVICE_ID=$(keystone service-list | awk '/\ keystone\ / {print $2}')
keystone endpoint-create --service_id $KEYSTONE_SERVICE_ID --publicurl "http://$IP:5000/v2.0" --adminurl "http://$IP:35357/v2.0" --internalurl "http://$IP:5000/v2.0"
ADMIN_TOKEN=`cat /tmp/ks_admin_token`

## Create admin user, role and tenant
keystone --token $ADMIN_TOKEN --endpoint http://$IP:35357/v2.0 user-create --name admin --pass test
keystone --token $ADMIN_TOKEN --endpoint http://$IP:35357/v2.0 role-create --name admin
keystone --token $ADMIN_TOKEN --endpoint http://$IP:35357/v2.0 tenant-create --name admin
keystone --token $ADMIN_TOKEN --endpoint http://$IP:35357/v2.0 user-role-add --user admin --role admin --tenant admin

## Create demo tenant
keystone --token $ADMIN_TOKEN --endpoint http://$IP:35357/v2.0 tenant-create --name demo
keystone --token $ADMIN_TOKEN --endpoint http://$IP:35357/v2.0 user-role-add --user admin --role admin --tenant demo

# Test 
keystone user-list
curl -s http://127.0.0.1:35357/v2.0/tokens -X 'POST'  -d '{"auth":{"passwordCredentials":{"username":"admin", "password":"test"}}}'  -H "Content-Type: application/json" | python -m json.tool
curl -s http://127.0.0.1:35357/v2.0/tokens -X 'POST'  -d '{"auth":{"passwordCredentials":{"username":"admin", "password":"test1"}}}'  -H "Content-Type: application/json" | python -m json.tool
wait
