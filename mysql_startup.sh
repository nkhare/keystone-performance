/usr/bin/mysqld_safe  &
until mysql -e 'select 1'; do sleep 1; done
wait
