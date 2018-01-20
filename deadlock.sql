```sql``
1）用dba用户执行以下语句
select username,lockwait,status,machine,program from v$session where sid in
(select session_id from v$locked_object)
如果有输出的结果，则说明有死锁，且能看到死锁的机器是哪一台。字段说明：
Username：死锁语句所用的数据库用户；
Lockwait：死锁的状态，如果有内容表示被死锁。
Status： 状态，active表示被死锁
Machine： 死锁语句所在的机器。
Program： 产生死锁的语句主要来自哪个应用程序。
2）用dba用户执行以下语句，可以查看到被死锁的语句。
select sql_text from v$sql where hash_value in 
(select sql_hash_value from v$session where sid in
(select session_id from v$locked_object))

四、死锁的解决方法
     一般情况下，只要将产生死锁的语句提交就可以了，但是在实际的执行过程中。用户可
能不知道产生死锁的语句是哪一句。可以将程序关闭并重新启动就可以了。
　经常在Oracle的使用过程中碰到这个问题，所以也总结了一点解决方法。

1）查找死锁的进程：

sqlplus "/as sysdba" (sys/change_on_install)
SELECT s.username,l.OBJECT_ID,l.SESSION_ID,s.SERIAL#,
l.ORACLE_USERNAME,l.OS_USER_NAME,l.PROCESS 
FROM V$LOCKED_OBJECT l,V$SESSION S WHERE l.SESSION_ID=S.SID;

select A.SQL_TEXT, B.USERNAME, C.OBJECT_ID, C.SESSION_ID, 
       B.SERIAL#, C.ORACLE_USERNAME,C.OS_USER_NAME,C.Process,
       ''''||C.Session_ID||','||B.SERIAL#||''''
from v$sql A, v$session B, v$locked_object C
where A.HASH_VALUE = B.SQL_HASH_VALUE and
B.SID = C.Session_ID

2）kill掉这个死锁的进程：

　　alter system kill session ‘sid,serial#’; （其中sid=l.session_id）

      alter system kill session '710,35184'; （其中sid=l.session_id）

3）如果还不能解决：

select pro.spid from v$session ses,v$process pro where ses.sid=XX and ses.paddr=pro.addr;

　　其中sid用死锁的sid替换: exit
ps -ef|grep spid

　　其中spid是这个进程的进程号，kill掉这个Oracle进程

4.在OS上杀死这个进程（线程）：

1)在unix上，用root身份执行命令:

#kill -9 12345（即第3步查询出的spid）

2)在windows（unix也适用）用orakill杀死线程，orakill是oracle提供的一个可执行命令，语法为：

orakill sid thread

其中：

sid：表示要杀死的进程属于的实例名

thread：是要杀掉的线程号，即第3步查询出的spid。

例：c:>orakill orcl 12345

