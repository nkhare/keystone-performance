/usr/bin/mysqld_safe  &
until mysql -e 'select 1'; do sleep 1; done
useradd keystone
openstack-db --init --service keystone -y --rootpw ""
keystone-manage pki_setup --keystone-user keystone --keystone-group keystone
mkdir -p /etc/keystone
#cp /opt/keystone/etc/keystone.conf.sample /etc/keystone/keystone.conf
export IP=$(ip addr | grep inet | grep eth0 | awk -F" " '{print $2}'| sed -e 's/\/.*$//')
export SERVICE_TOKEN=$(openssl rand -hex 10)
export SERVICE_ENDPOINT=http://$IP:35357/v2.0
echo $SERVICE_TOKEN > /tmp/ks_admin_token
openstack-config --set /etc/keystone/keystone.conf DEFAULT admin_token $SERVICE_TOKEN
keystone-all --config-file /etc/keystone/keystone.conf &
> ~/keystonerc_admin
echo "export OS_USERNAME=admin" >> ~/keystonerc_admin
echo "export OS_TENANT_NAME=admin" >> ~/keystonerc_admin
echo "export OS_PASSWORD=redhat" >> ~/keystonerc_admin
echo "export OS_AUTH_URL=http://$IP:35357/v2.0/" >> ~/keystonerc_admin
echo "export PS1='[\u@\h \W(keystone_admin)]\$ '" >> ~/keystonerc_admin
source ~/keystonerc_admin
sleep 2
keystone service-create --name keystone --type identity --description "Keystone Identity Service"
KEYSTONE_SERVICE_ID=$(keystone service-list | awk '/\ keystone\ / {print $2}')
keystone endpoint-create --service_id $KEYSTONE_SERVICE_ID --publicurl "http://$IP:5000/v2.0" --adminurl "http://$IP:35357/v2.0" --internalurl "http://$IP:5000/v2.0"
ADMIN_TOKEN=`cat /tmp/ks_admin_token`
keystone --token $ADMIN_TOKEN --endpoint http://$IP:35357/v2.0 user-create --name admin --pass redhat
keystone --token $ADMIN_TOKEN --endpoint http://$IP:35357/v2.0 role-create --name admin
keystone --token $ADMIN_TOKEN --endpoint http://$IP:35357/v2.0 tenant-create --name admin
keystone --token $ADMIN_TOKEN --endpoint http://$IP:35357/v2.0 user-role-add --user admin --role admin --tenant admin
keystone user-list
curl -s http://127.0.0.1:35357/v2.0/tokens -X 'POST'  -d '{"auth":{"passwordCredentials":{"username":"admin", "password":"redhat"}}}'  -H "Content-Type: application/json" | python -m json.tool
curl -s http://127.0.0.1:35357/v2.0/tokens -X 'POST'  -d '{"auth":{"passwordCredentials":{"username":"admin", "password":"redhat1"}}}'  -H "Content-Type: application/json" | python -m json.tool
wait

