## close_problems.sh


下記の条件に該当するトリガーの障害をクローズします.  
- トリガーが有効
- 手動クローズが有効
  
実行時のオプションは以下  
`close_problems.sh -h [Zabbixホスト] -u [Zabbixユーザー名] -p [Zabbixパスワード] -d [0以上の整数(n日前までの障害をクローズする)]`
  
Zabbix4.0.12で動作を確認しています.
