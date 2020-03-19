## close_problems.sh

Zabbix APIにより,  
手動クローズが有効になっているトリガーに関連する障害をクローズします.  
  
実行時のオプションは以下  
`close_problems.sh -h [Zabbixホスト] -u [Zabbixユーザー名] -p [Zabbixパスワード] -d [0以上の整数]`
  
例えば,
`close_problems.sh -h www.zexample.com -u zuser -p zpass -d 1`
と指定することで、ホスト名www.zexample.comのZabbixサーバーにzuserでログインし,  
ちょうど１日前より以前に発生した障害をクローズします.  
  
cronで週に１回程度仕掛けることで,  
snmpトラップやログファイル監視など復旧条件を設けていない障害が大量に溜まり,
ダッシュボードが表示不可能になることを防ぐのに使用しています.  
  
BashとPythonのみで記載しており,Zabbix4.0.12で動作を確認しています.
