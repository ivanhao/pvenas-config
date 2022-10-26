#!/bin/bash
#############--Proxmox VE Tools--##########################
#  Author : 龙天ivan
#  Mail: ivanhao1984@qq.com
#  Version: v1.0.1
#  Github: https://github.com/ivanhao/pvenas-config
########################################################

#js whiptail --title "Success" --msgbox "c" 10 60
if [ `export|grep 'LC_ALL'|wc -l` = 0 ];then
    if [ `grep "LC_ALL" /etc/profile|wc -l` = 0 ];then
        echo "export LC_ALL='en_US.UTF-8'" >> /etc/profile
    fi
fi
if [ `grep "alias ll" /etc/profile|wc -l` = 0 ];then
    echo "alias ll='ls -alh'" >> /etc/profile
    echo "alias sn='snapraid'" >> /etc/profile
fi
source /etc/profile
#    "a" "Config apt source." \
#    "a" "配置apt国内源" \
#-----------------functions--start------------------#
diskMgr(){
    whiptail --title " disk manager "
}

mergerfs(){
#-------------dataFolder--main---------------
if [ $L = "en" ];then
    OPTION=$(whiptail --title " PveNas-Config   Version : 1.0.1 " --menu "data folder config(mergerfs):" 25 60 15 \
    "a" "add disk or folder." \
    "b" "del disk or folder." \
    3>&1 1>&2 2>&3)
else
    OPTION=$(whiptail --title " PveNas-Config   Version : 1.0.1 " --menu "数据文件夹管理(mergerfs)：" 25 60 15 \
    "a" "添加硬盘、文件夹" \
    "b" "删除硬盘、文件夹" \
    3>&1 1>&2 2>&3)
fi
exitstatus=$?
if [ $exitstatus = 0 ]; then
    case "$OPTION" in
    a | A )
        echo "a"
        addMergerfs(){
            h=$(cat /etc/fstab |grep mergerfs|awk -F ":" '{print NF}')
            h=`expr $h + 20`
            fd=$(cat /etc/fstab |grep mergerfs|awk '{print $1}'|awk -F ":" '{for(i=1;i<=NF;i++){print $i;}}')
            x=$(whiptail --title "Add mergerfs folder" --inputbox "
Exist folders:
已有的目录：
-------------------------------------------------------
$(cat /etc/fstab |grep mergerfs|awk '{print $1}'|awk -F ":" '{for(i=1;i<=NF;i++){print $i;}}')
-------------------------------------------------------
Mount info:
挂载详情：
-------------------------------------------------------
$(df -h|grep -vE '/run|/var'|grep mergerfs|awk '{print $6"  Size:"$2" | Used:"$3" | Avail:"$4" | Use%:"$5" |"}')
-------------------------------------------------------
Input folder path(like /root):
输入文件夹的路径(只需要输入/root类似的路径):
" $h 60 "" 3>&1 1>&2 2>&3)
            exitstatus=$?
            if [ $exitstatus = 0 ]; then
                while [ ! -d $x ]
                do
                    whiptail --title "Success" --msgbox "Path not exist!
路径不存在！
                    " 10 60
                    addMergerfs
                done
                while [ `echo $fd|grep ${x}|wc -l` != 0 ]
                do
                    whiptail --title "Success" --msgbox "Path configed!
路径已配置！
                    " 10 60
                    addMergerfs
                done
                if [ `echo $fd|grep ${x}|wc -l` = 0 ];then
                    fdNew=$(cat /etc/fstab |grep mergerfs|awk '{print $1}')
                    fdNew=$fdNew":"${x}" /DATA fuse.mergerfs defaults,allow_other,minfreespace=1M,fsname=mergerfs,use_ino 0 0"
                    #echo $fdNew > fdNew.txt

                    umount /DATA
                    #　如果首次添加数据盘，进行数据迁移 --v1.0.4
                    if [ `echo $fd|grep '/media'|wc -l` = 0 ];then
                        systemctl stop docker
                        umount /DATA
                        rsync -a /media/ ${x}/
                        rm -rf /media/*
                        fdNew=${x}" /DATA fuse.mergerfs defaults,allow_other,minfreespace=1M,fsname=mergerfs,use_ino 0 0"
                    fi
                    sed -i '/mergerfs/d' /etc/fstab
                    echo $fdNew >> /etc/fstab
                    mount -a
                    #chmod -R 777 ${x}
                    #chmod -R 777 /DATA
                    chgrp -R samba ${x}
                    chmod -R g+w ${x}
                    chgrp -R samba /DATA
                    chmod -R g+w /DATA
                    whiptail --title "Success" --msgbox "
Configed!
配置成功！
                    " 10 60
                    whiptail --title "Success" --msgbox "
Please reboot to apply change!
请重启系统让配置生效！
                    " 10 60
                    #--2.3.0 add group
                else
                    whiptail --title "Success" --msgbox "Already configed！
已经配置过了！
                    " 10 60
                fi
                addMergerfs
            else
                mergerfs
            fi
}
        addMergerfs
        ;;
    b )
#Size | Used | Avail | Use% | Mounted on
        delMergerfs(){
            fd=$(cat /etc/fstab |grep mergerfs|awk '{print $1}'|awk -F ":" '{for(i=1;i<=NF;i++){print $i;}}')
            count=$(echo $fd|wc -l)
            h=$(cat /etc/fstab |grep mergerfs|awk -F ":" '{print NF}')
            h=`expr $h + 20`
            x=$(whiptail --title "Del mergerfs folder" --inputbox "
Exist folders:
已有的目录：
-------------------------------------------------------
$(cat /etc/fstab |grep mergerfs|awk '{print $1}'|awk -F ":" '{for(i=1;i<=NF;i++){print $i;}}')
-------------------------------------------------------
Mount info:
挂载详情：
-------------------------------------------------------
$(df -h|grep -vE '/run|/var'|grep mergerfs|awk '{print $6"  Size:"$2" | Used:"$3" | Avail:"$4" | Use%:"$5" |"}')
-------------------------------------------------------
Input folder path(like /root):
输入文件夹的路径(只需要输入/root类似的路径):
" $h 60 "" 3>&1 1>&2 2>&3)
        exitstatus=$?
        if [ $exitstatus = 0 ]; then
            if [ $count != 1 ];then
                while [ ! -d $x ]
                do
                    whiptail --title "Success" --msgbox "Path not exist!
路径不存在！
                    " 10 60
                    delMergerfs
                done
                echo $fd > ./fd.txt
                while [ `echo $fd|grep ${x}|wc -l` = 0 ]
                do
                    whiptail --title "Success" --msgbox "Path not exist!
路径不存在！
                    " 10 60
                    delMergerfs
                done
                if [ `echo $fd|grep ${x}|wc -l` != 0 ];then
                    #fdNew=$(cat /etc/fstab |grep mergerfs|awk '{print $1}')
                    #fdNew=$(sed 's/${x}//g' $fd)
                    #fdNew=$fdNew":"${x}" /media fuse.mergerfs defaults,allow_other,minfreespace=1M,fsname=mergerfs,use_ino 0 0"
                    fdNew=""
                    #for(i=1;i<=${#fd[*]};i++)
                    for i in $fd;do
                        if [ $i != ${x} ];then
                            fdNew=$i":"$fdNew
                        fi
                    done
                    fdNew=$(echo $fdNew|sed 's/:$//g')
                    echo $fdNew > fdNew.txt
                    fdNew=$fdNew" /DATA fuse.mergerfs defaults,allow_other,minfreespace=1M,fsname=mergerfs,use_ino 0 0"
                    sed -i '/mergerfs/d' /etc/fstab
                    echo $fdNew >> /etc/fstab
                    umount /DATA
                    mount -a
                    chmod -R 777 /DATA
                    whiptail --title "Success" --msgbox "
Configed!
配置成功！
                    " 10 60
                    #--2.3.0 add group
                else
                    whiptail --title "Success" --msgbox "Already configed！
已经配置过了！
                    " 10 60
                fi
                delMergerfs
            else
                whiptail --title "warning" --msgbox "Only one folder,can not delete!
只有一个文件夹了，无法再删除！" 10 60
                mergerfs
            fi
        else
            mergerfs
        fi
}
        delMergerfs

        ;;
    esac
else
    main
fi
#-------------dataFolder--main--end------------


}

chSamba(){
    smbp(){
    m=$(whiptail --title "Password Box" --passwordbox "
    Enter samba user 'admin' password:
    请输入samba用户admin的密码：
                    " 10 60 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        while [ true ]
        do
            if [[ ! `echo $m|grep "^[0-9a-zA-Z.-@]*$"` ]] || [[ $m = '^M' ]];then
                whiptail --title "Warnning" --msgbox "
    Wrong format!!!   input again:
    密码格式不对！！！请重新输入：
                " 10 60
                smbp
            else
                break
            fi
        done
    fi
    }

#config samba
        addSmbRecycle(){
            if(whiptail --title "Yes/No" --yesno "enable recycle?
开启回收站？" 10 60 )then
                if [ ! -f '/etc/samba/smb.conf' ];then
                    whiptail --title "Warnning" --msgbox "You should install samba first!
    请先安装samba！" 10 60
                else
                    if [ `sed -n "/\[$2\]/,/$2 end/p" /etc/samba/smb.conf|egrep '^recycle'|wc -l` != 0 ];then
                        whiptail --title "Warnning" --msgbox "Already configed!  已经配置过了。" 10 60
                        smbRecycle
                    else
                        cat << EOF > ./recycle
# $2--recycle-start--
vfs object = recycle
recycle:repository = $1/.deleted
recycle:keeptree = Yes
recycle:versions = Yes
recycle:maxsixe = 0
recycle:exclude = *.tmp
# $2--recycle-end--
EOF
                        #n=`sed '/\['$2'\]/' /etc/samba/smb.conf -n|sed -n '$p'`
                        cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
                        sed -i '/\['$2'\]/r ./recycle' /etc/samba/smb.conf
                        rm ./recycle
#                        cat << EOF >> /etc/samba/smb.conf
#[$2-recycle]
#comment = All
#browseable = yes
#path = $1/.deleted
#guest ok = no
#read only = no
#create mask = 0750
#directory mask = 0750
#;  $2-recycle end
#EOF
                        systemctl restart smbd
                        whiptail --title "Success" --msgbox "Done.
    配置完成" 10 60
                    fi
                fi
            else
                continue
            fi
        }
        delSmbRecycle(){
            if [ ! -f '/etc/samba/smb.conf' ];then
                whiptail --title "Warnning" --msgbox "You should install samba first!
请先安装samba！" 10 60
            else
                if [ `sed -n "/\[$1\]/,/$1 end/p" /etc/samba/smb.conf|egrep '^recycle'|wc -l` = 0 ];then
                    whiptail --title "Warnning" --msgbox "Already configed!  已经配置过了。" 10 60
                    smbRecycle
                else
                    cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
                    sed -i '/.*'$1'.*recycle.*start/,/.*'$1'.*end/d' /etc/samba/smb.conf
                    sed "/\[${1}\-recycle\]/,/${n}\-recycle end/d" /etc/samba/smb.conf -i
                    systemctl restart smbd
                    whiptail --title "Success" --msgbox "Done.
配置完成" 10 60
                fi
            fi
        }

clear
#$(grep -E "^\[[0-9a-zA-Z.-]*\]$|^path" /etc/samba/smb.conf|awk 'NR>3{print $0}'|sed 's/path/        path/'|grep -v '-recycle')
if [ $L = "en" ];then
    OPTION=$(whiptail --title " PveTools   Version : 2.3.0 " --menu "Config samba:" 25 60 15 \
    "a" "Install samba and config user." \
    "b" "Add folder to share." \
    "c" "Delete folder to share." \
    "d" "Config recycle" \
    "q" "Main menu." \
    3>&1 1>&2 2>&3)
else
    OPTION=$(whiptail --title " PveTools   Version : 2.3.0 " --menu "配置samba:" 25 60 15 \
    "a" "安装配置samba并配置好samba用户" \
    "b" "添加共享文件夹" \
    "c" "取消共享文件夹" \
    "d" "配置回收站" \
    "q" "返回主菜单" \
    3>&1 1>&2 2>&3)
fi
if [ $1 ];then
    OPTION=a
fi
exitstatus=$?
if [ $exitstatus = 0 ]; then
    case "$OPTION" in
    a | A )
        #if [ `grep samba /etc/group|wc -l` = 0 ];then
            if (whiptail --title "Yes/No Box" --yesno "set samba and admin user for samba?
安装samba并配置admin为samba用户？
                " 10 60);then
                apt -y install samba
                groupadd samba
                useradd -g samba -M -s /sbin/nologin admin
                smbp
                echo -e "$m\n$m"|smbpasswd -a admin
                service smbd restart
                echo -e "已成功配置好samba，请记好samba用户admin的密码！"
                whiptail --title "Success" --msgbox "
已成功配置好samba，请记好samba用户admin的密码！
                " 10 60
            fi
        #else
        #    whiptail --title "Success" --msgbox "Already configed samba.
#已配置过samba，没什么可做的!
#            " 10 60
#        fi
        if [ ! $1 ];then
            chSamba
        fi
        ;;
    b | B )
       # echo -e "Exist share folders:"
       # echo -e "已有的共享目录："
       # echo "`grep "^\[[0-9a-zA-Z.-]*\]$" /etc/samba/smb.conf|awk 'NR>3{print $0}'`"
       # echo -e "Input share folder path:"
       # echo -e "输入共享文件夹的路径:"
       addFolder(){
        h=`grep "^\[[0-9a-zA-Z.-]*\]$" /etc/samba/smb.conf|awk 'NR>3{print $0}'|wc -l`
        if [ $h -lt 3 ];then
            let h=$h*15
        else
            let h=$h*5
        fi
        x=$(whiptail --title "Add Samba Share folder" --inputbox "
Exist share folders:
已有的共享目录：
----------------------------------------
$(grep -Ev "-recycle|.deleted$" /etc/samba/smb.conf|grep -E "^\[[0-9a-zA-Z.-]*\]$|^path"|sed 's/path/        path/'|awk 'NR>3{print $0}')
----------------------------------------
Input share folder path(like /root):
输入共享文件夹的路径(只需要输入/root类似的路径):
" $h 60 "" 3>&1 1>&2 2>&3)
        exitstatus=$?
        if [ $exitstatus = 0 ]; then
            while [ ! -d $x ]
            do
                whiptail --title "Success" --msgbox "Path not exist!
路径不存在！
                " 10 60
                addFolder
            done
            while [ `grep "path \= ${x}$" /etc/samba/smb.conf|wc -l` != 0 ]
            do
                whiptail --title "Success" --msgbox "Path exist!
路径已存在！
                " 10 60
                addFolder
            done
            n=`echo $x|grep -o "[a-zA-Z0-9.-]*$"`
            while [ `grep "^\[${n}\]$" /etc/samba/smb.conf|wc -l` != 0 ]
            do
                n=$(whiptail --title "Samba Share folder" --inputbox "
Input share name:
输入共享名称：
    " 10 60 "" 3>&1 1>&2 2>&3)
                exitstatus=$?
                if [ $exitstatus = 0 ]; then
                    while [ `grep "^\[${n}\]$" /etc/samba/smb.conf|wc -l` != 0 ]
                    do
                        whiptail --title "Success" --msgbox "Name exist!
名称已存在！
                        " 10 60
                        addFolder
                    done
                fi
            done
            oldgrp=`ls -l $x|awk 'NR==2{print $4}'`
            if [ `grep "${x}$" /etc/samba/smb.conf|wc -l` = 0 ];then
                cat << EOF >> /etc/samba/smb.conf
[$n]
comment = All
browseable = yes
path = $x
guest ok = no
read only = no
create mask = 0750
directory mask = 0750
; oldgrp $oldgrp
;  $n end
EOF
                whiptail --title "Success" --msgbox "
Configed!
配置成功！
                " 10 60
                #--2.3.0 add group
                chgrp -R samba $x
                chmod -R g+w $x
                addSmbRecycle $x $n
                service smbd restart
            else
                whiptail --title "Success" --msgbox "Already configed！
已经配置过了！
                " 10 60
            fi
            addFolder
        else
            chSamba
        fi
}
        addFolder
        ;;
    c )
        delFolder(){
        h=`grep "^\[[0-9a-zA-Z.-]*\]$" /etc/samba/smb.conf|awk 'NR>3{print $0}'|wc -l`
        if [ $h -lt 3 ];then
            let h=$h*15
        else
            let h=$h*5
        fi
        n=$(whiptail --title "Remove Samba Share folder" --inputbox "
Exist share folders:
已有的共享目录：
----------------------------------------
$(grep -Ev "-recycle|.deleted$" /etc/samba/smb.conf|grep -E "^\[[0-9a-zA-Z.-]*\]$|^path"|sed 's/path/        path/'|awk 'NR>3{print $0}')
----------------------------------------
Input share folder name(type words in []):
输入共享文件夹的名称(只需要输入[]中的名字):
        " $h 60 "" 3>&1 1>&2 2>&3)
        exitstatus=$?
        if [ $exitstatus = 0 ]; then
            while [ `grep "^\[${n}\]$" /etc/samba/smb.conf|wc -l` = 0 ]
            do
                whiptail --title "Success" --msgbox "
Name not exist!:
名称不存在！:
                " 10 60
                delFolder
            done
            if [ `grep "^\[${n}\]$" /etc/samba/smb.conf|wc -l` != 0 ];then
                oldgrp=`sed -n "/\[${n}\]/,/${n} end/p" /etc/samba/smb.conf |grep oldgrp|awk '{print $3}'`
                x=`grep -E "^path = [0-9a-zA-Z/-.]*${n}" /etc/samba/smb.conf|awk '{print $3}'`
                if [ $oldgrp ];then
                    chgrp -R $oldgrp $x
                fi
                sed "/\[${n}\]/,/${n} end/d" /etc/samba/smb.conf -i
                sed "/\[${n}-recycle\]/,/${n}-recycle end/d" /etc/samba/smb.conf -i
                whiptail --title "Success" --msgbox "
Configed!
配置成功！
                " 10 60
                service smbd restart
            fi
            delFolder
        else
            chSamba
        fi
    }
        delFolder
        ;;
    d )
        smbRecycle(){
            if [ $L = "en" ];then
                x=$(whiptail --title " PveTools   Version : 2.3.0 " --menu "Config samba recycle:" 12 60 4 \
                "a" "Enable samba recycle." \
                "b" "Disable samba recycle." \
                "c" "Clear recycle." \
                3>&1 1>&2 2>&3)
            else
                x=$(whiptail --title " PveTools   Version : 2.3.0 " --menu "配置samba回收站！" 12 60 4 \
                "a" "开启samba回收站。" \
                "b" "关闭samba回收站。" \
                "c" "清空samba回收站。" \
                3>&1 1>&2 2>&3)
            fi
            exitstatus=$?
            if [ $exitstatus = 0 ]; then
                case "$x" in
                    a )
                        enSmbRecycle(){
                            h=`grep "^\[[0-9a-zA-Z.-]*\]$" /etc/samba/smb.conf|awk 'NR>3{print $0}'|wc -l`
                            if [ $h -lt 3 ];then
                                let h=$h*15
                            else
                                let h=$h*5
                            fi
                            n=$(whiptail --title "Remove Samba recycle" --inputbox "
Exist share folders:
已有的共享目录：
----------------------------------------
$(grep -Ev "-recycle|.deleted$" /etc/samba/smb.conf|grep -E "^\[[0-9a-zA-Z.-]*\]$|^path"|sed 's/path/        path/'|awk 'NR>3{print $0}')
----------------------------------------
Input share folder name(type words in []):
输入共享文件夹的名称(只需要输入[]中的名字):
                            " $h 60 "" 3>&1 1>&2 2>&3)
                            exitstatus=$?
                            if [ $exitstatus = 0 ]; then
                                while [ `grep "^\[${n}\]$" /etc/samba/smb.conf|wc -l` = 0 ]
                                do
                                    whiptail --title "Success" --msgbox "
Name not exist!:
名称不存在！:
                                    " 10 60
                                    enSmbRecycle
                                done
                                if [ `grep "^\[${n}\]$" /etc/samba/smb.conf|wc -l` != 0 ];then
                                    if [ `sed -n "/\[${n}\]/,/${n} end/p" /etc/samba/smb.conf|egrep '^recycle'|wc -l` != 0 ];then
                                        whiptail --title "Warnning" --msgbox "Already configed!  已经配置过了。" 10 60
                                        smbRecycle
                                    else
                                        x=`sed -n "/\[${n}\]/,/${n} end/p" /etc/samba/smb.conf|grep path|awk '{print $3}'`
                                        addSmbRecycle $x $n
                                        service smbd restart
                                    fi
                                fi
                                disSmbRecycle
                            else
                                smbRecycle
                            fi
                        }
                        enSmbRecycle
                        ;;
                    b )
                        disSmbRecycle(){
                            h=`grep "^\[[0-9a-zA-Z.-]*\]$" /etc/samba/smb.conf|awk 'NR>3{print $0}'|wc -l`
                            if [ $h -lt 3 ];then
                                let h=$h*15
                            else
                                let h=$h*5
                            fi
                            n=$(whiptail --title "Remove Samba recycle" --inputbox "
Exist share folders:
已有的共享目录：
----------------------------------------
$(grep -Ev "-recycle|.deleted$" /etc/samba/smb.conf|grep -E "^\[[0-9a-zA-Z.-]*\]$|^path"|sed 's/path/        path/'|awk 'NR>3{print $0}')
----------------------------------------
Input share folder name(type words in []):
输入共享文件夹的名称(只需要输入[]中的名字):
                            " $h 60 "" 3>&1 1>&2 2>&3)
                            exitstatus=$?
                            if [ $exitstatus = 0 ]; then
                                while [ `grep "^\[${n}\]$" /etc/samba/smb.conf|wc -l` = 0 ]
                                do
                                    whiptail --title "Success" --msgbox "
Name not exist!:
名称不存在！:
                                    " 10 60
                                    disSmbRecycle
                                done
                                x=`sed -n "/\[${n}\]/,/${n} end/p" /etc/samba/smb.conf|grep path|awk '{print $3}'`
                                if [ `ls $x/.deleted/|wc -l` != 0 ];then
                                    if(whiptail --title "Warnning" --yesno "recycle not empty, you should clear it first.continue?
回收站中存在文件，建议先清空，是否确认要继续？" 10 60);then
                                        if [ `grep "^\[${n}\]$" /etc/samba/smb.conf|wc -l` != 0 ];then
                                            delSmbRecycle $n
                                            service smbd restart
                                        fi
                                        disSmbRecycle
                                    else
                                        disSmbRecycle
                                    fi
                                fi
                            else
                                smbRecycle
                            fi
                        }
                        disSmbRecycle
                        ;;
                    c )
                        checkClearSmb(){
                            c=$(whiptail --title "Clear Samba recycle" --inputbox "
you can disable recycle to clear it.
clear recycle may cause data lose,pvetools will not response for that,do you agree?
type 'YesIdo' to continue:
你可以先取消回收站再手工清空。
工具清空samba回收站不可逆，pvetools不会对此操作负责，是否同意？
如果确认要清空，请输入'YesIdo'继续：" 20 60 "" 3>&1 1>&2 2>&3)
                            exitstatus=$?
                            if [ $exitstatus = 0 ]; then
                                while [ $c != 'YesIdo' ]
                                do
                                    whiptail --title "Success" --msgbox "
Woring words,try again:
输入错误，请重试:
                                    " 10 60
                                    checkClearSmb
                                done
                            else
                                continue
                            fi
                        }
                        clearSmbRecycle(){
                            h=`grep "^\[[0-9a-zA-Z.-]*\]$" /etc/samba/smb.conf|awk 'NR>3{print $0}'|wc -l`
                            if [ $h -lt 3 ];then
                                let h=$h*15
                            else
                                let h=$h*5
                            fi
                            n=$(whiptail --title "Clear Samba recycle" --inputbox "
Exist share folders:
已有的共享目录：
----------------------------------------
$(grep -Ev "-recycle|.deleted$" /etc/samba/smb.conf|grep -E "^\[[0-9a-zA-Z.-]*\]$|^path"|sed 's/path/        path/'|awk 'NR>3{print $0}')
----------------------------------------
Input share folder name(type words in []):
输入共享文件夹的名称(只需要输入[]中的名字):
                            " $h 60 "" 3>&1 1>&2 2>&3)
                            exitstatus=$?
                            if [ $exitstatus = 0 ]; then
                                while [ `grep "^\[${n}\]$" /etc/samba/smb.conf|wc -l` = 0 ]
                                do
                                    whiptail --title "Success" --msgbox "
Name not exist!:
名称不存在！:
                                    " 10 60
                                    clearSmbRecycle
                                done
                                x=`sed -n "/\[${n}\]/,/${n} end/p" /etc/samba/smb.conf|grep path|awk '{print $3}'`
                                if [ `ls -a $x/.deleted/|wc -l` -gt 2 ];then
                                    if(whiptail --title "Warnning" --yesno "recycle not empty,continue?
回收站中存在文件，是否确认要继续？" 10 60);then
                                        checkClearSmb
                                        whiptail --title "Success" --msgbox "ok." 10 60
                                    else
                                        clearSmbRecycle
                                    fi
                                else
                                    whiptail --title "Success" --msgbox "Already empty.回收站是空的，不需要清空。" 10 60
                                fi
                            else
                                smbRecycle
                            fi
                        }
                        clearSmbRecycle
                        ;;
                esac
            else
                chSamba
            fi
        }
        smbRecycle
        ;;

    q )
        main
        ;;
    esac
else
    chSamba
fi
}
        #"a" "Install nfs server." \
        #"a" "安装NFS服务器。" \
chNFS(){
    if [ $L = "en" ];then
        x=$(whiptail --title " PveTools   Version : 2.3.0 " --menu "NFS:" 25 60 15 \
        "b" "add nfs folder." \
        "c" "delete nfs folder." \
        3>&1 1>&2 2>&3)
    else
        x=$(whiptail --title " PveTools   Version : 2.3.0 " --menu "NFS:" 25 60 15 \
        "b" "添加nfs文件夹" \
        "c" "删除nfs文件夹" \
        3>&1 1>&2 2>&3)
    fi
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        case "$x" in
        a )
            if(whiptail --title "Yes/No" --yesno "Comfirm?
是否安装？" 10 60)then
                apt-get install nfs-kernel-server
                whiptail --title "OK" --msgbox "Complete.If you use zfs use 'zfs set sharenfs=on <zpool> to enable NFS.'
安装配置完成。如果你使用zfs，执行'zfs set sharenfs=on <zpool>来开启NFS。" 10 60
            else
                chNFS
            fi
            ;;
        b )
            addNfs(){
            h=$(cat /etc/exports|grep -E '^/'|wc -l)
            h=`expr $h + 20`
            fd=$(cat /etc/exports|grep -E '^/'|awk '{print $1}')
            x=$(whiptail --title "Add nfs folder" --inputbox "
Exist folders:
已有的目录：
-------------------------------------------------------
$(cat /etc/exports|grep -E '^/'|awk '{print $1}')
-------------------------------------------------------
Input folder path(like /root):
输入文件夹的路径(只需要输入/root类似的路径):
" $h 60 "" 3>&1 1>&2 2>&3)
            exitstatus=$?
            if [ $exitstatus = 0 ]; then
                while [ ! -d $x ]
                do
                    whiptail --title "Success" --msgbox "Path not exist!
路径不存在！
                    " 10 60
                    addNfs
                done
                while [ `echo $fd|grep ${x}|wc -l` != 0 ]
                do
                    whiptail --title "Success" --msgbox "Path configed!
路径已配置！
                    " 10 60
                    addNfs
                done
                if [ `echo $fd|grep ${x}|wc -l` = 0 ];then
                    echo "${x} *(rw,sync,no_root_squash,insecure)" >> /etc/exports
                    systemctl restart nfs-server
                    whiptail --title "Success" --msgbox "
Configed!
配置成功！
                    " 10 60
                    #--2.3.0 add group
                else
                    whiptail --title "Success" --msgbox "Already configed！
已经配置过了！
                    " 10 60
                fi
                addNfs
            else
                chNFS
            fi
}
            addNfs
            ;;
        c )
            delNfs(){
            h=$(cat /etc/exports|grep -E '^/'|wc -l)
            h=`expr $h + 20`
            fd=$(cat /etc/exports|grep -E '^/'|awk '{print $1}')
            x=$(whiptail --title "Del nfs folder" --inputbox "
Exist folders:
已有的目录：
-------------------------------------------------------
$(cat /etc/exports|grep -E '^/'|awk '{print $1}')
-------------------------------------------------------
Input folder path(like /root):
输入文件夹的路径(只需要输入/root类似的路径):
" $h 60 "" 3>&1 1>&2 2>&3)
            exitstatus=$?
            if [ $exitstatus = 0 ]; then
                while [ ! -d $x ]
                do
                    whiptail --title "Success" --msgbox "Path not exist!
路径不存在！
                    " 10 60
                    delNfs
                done
                while [ `echo $fd|grep ${x}|wc -l` = 0 ]
                do
                    whiptail --title "Success" --msgbox "Path not exist!
路径不存在！
                    " 10 60
                    delNfs
                done
                if [ `echo $fd|grep ${x}|wc -l` != 0 ];then
                    fdn=$(echo ${x}|sed 's/\//\./g')
                    sed -i "/$fdn\ /d" /etc/exports
                    systemctl restart nfs-server
                    whiptail --title "Success" --msgbox "
Configed!
配置成功！
                    " 10 60
                    #--2.3.0 add group
                else
                    whiptail --title "Success" --msgbox "Already configed！
已经配置过了！
                    " 10 60
                fi
                delNfs
            else
                chNFS
            fi
}
        delNfs
            ;;
        esac
    fi


}
sambaOrNfs(){
    if [ $L = "en" ];then
        x=$(whiptail --title " PveTools   Version : 2.3.0 " --menu "Samba or NFS:" 25 60 15 \
        "a" "samba" \
        "b" "NFS" \
        3>&1 1>&2 2>&3)
    else
        x=$(whiptail --title " PveTools   Version : 2.3.0 " --menu "Samba or NFS:" 25 60 15 \
        "a" "samba" \
        "b" "NFS" \
        3>&1 1>&2 2>&3)
    fi
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        case "$x" in
        a )
            chSamba
            ;;
        b )
            chNFS
        esac
    fi


}



main(){
clear
if [ $L = "en" ];then
    OPTION=$(whiptail --title " pvenas-config   Version : 1.0.1 " --menu "
Please choose:" 25 60 15 \
    "b" "config samba or NFS." \
    "c" "Disk manager." \
    "d" "Data folder manager." \
    "u" "Upgrade this script to new version." \
    "L" "Change Language." \
    3>&1 1>&2 2>&3)
else
    OPTION=$(whiptail --title " pvenas-config   Version : 1.0.1 " --menu "
请选择相应的配置：" 25 60 15 \
    "b" "配置samba或NFS" \
    "c" "磁盘管理工具" \
    "d" "数据文件夹管理(mergerfs)" \
    "u" "升级该脚本到最新版本" \
    "L" "Change Language" \
    3>&1 1>&2 2>&3)
fi
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        case "$OPTION" in
        a )
            chSource
            main
            ;;
        b )
            sambaOrNfs
            main
            ;;
        c )
            diskMgr
            main
            ;;
        d )
            mergerfs
            main
            ;;
        u )
            git pull
            echo "Now go to main interface:"
            echo "即将回主界面。。。"
            echo "3"
            sleep 1
            echo "2"
            sleep 1
            echo "1"
            sleep 1
            ./pvenas-config.sh
            ;;
        L )
            if (whiptail --title "Yes/No Box" --yesno "Change Language?
修改语言？" 10 60);then
                if [ $L = "zh" ];then
                    L="en"
                else
                    L="zh"
                fi
                main
                #main $L
            fi
            ;;
        exit | quit | q )
            exit
            ;;
        esac
    else
        exit
    fi
}
#----------------------functions--end------------------#
#if [ `export|grep "zh_CN"|wc -l` = 0 ];then
#    L="en"
#else
#    L="zh"
#fi
if (whiptail --title "Language" --yes-button "中文" --no-button "English"  --yesno "Choose Language:
选择语言：" 10 60) then
    L="zh"
else
    L="en"
fi
main
