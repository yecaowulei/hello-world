#!/bin/bash

Enter()
{
echo
printf "输入回车键继续..."
read -s Enter
echo
}

Chkfile()
{
if [ ! -f $1 ]
   then
        echo "ERR-0: 菜单文件 $1 不存在..."
        exit 1
fi
}

Chkinput()
{
if [ "x$2" = "xa" -o "x$2" = "xx" -o "x$2" = "xh" -o "x$2" = "xb" ]
   then
        return 0
fi
expr $2 + 0 >/dev/null 2>&1
if [ $? -ne 0 ]
   then
        return 1
fi
if [ $2 -le 0 -o $2 -gt `awk 'END{print NR}' $1` ]
   then
        return 2
fi
}

Tree()
{
menu=`expr $menu + 1`
local i=1
until [ $i -gt `awk 'END{print NR}' $1` ]
do

  echo $tree | awk '{for(i=1;i<="'$menu'";i++)if($i==1){printf "│  "}else{printf "    "}}'

  if [ $verbose -eq 1 ]
     then
          text=`awk -F"$MENUCHAR" 'NR=="'$i'"{if($2!~/'$MENUTYPE'/){print $1"     "$2}else{print $1}}' $1`
     else
          text=`awk -F"$MENUCHAR" 'NR=="'$i'"{print $1}' $1`
  fi

  if [ $i -eq `awk 'END{print NR}' $1` ]
     then
         echo "└─$text"
         tree=`echo $tree | awk '{for(i=1;i<=NF;i++){if(i==("'$menu'"+1))$i=0}}END{print $0}'`
     else
         echo "├─$text"
         tree=`echo $tree | awk '{for(i=1;i<=NF;i++){if(i==("'$menu'")+1)$i=1}}END{print $0}'`
  fi
  run=`awk -F"$MENUCHAR" 'NR=="'$i'"{print $2}' $1`
  if [ "`echo $run | awk -F"." '{print $NF}'`" = "$MENUTYPE" ]
     then
          tree="$tree 1"
          Tree $MENUPATH/$run
  fi
  i=`expr $i + 1`
done
menu=`expr $menu - 1`
}

Menu()
{

menu=`expr $menu + 1`

while true

do

if [ "x$input" = "xx" ]
   then
        exit
fi

clear

echo
echo "You can choose followed options:"
echo
echo "  ────────────────────────────"
echo
awk -F"$MENUCHAR" 'NF>1{printf "   "NR". ";if($2~/'$MENUTYPE'$/){printf "+"}else{printf ""}printf $1"\n"}' $1
#awk -F"$MENUCHAR" 'NF>1{printf "   "NR". ";if($2~/'$MENUTYPE'$/){printf "+ "}else{printf "* "}printf $1"\n\n"}' $1

echo
echo "  ────────────────────────────"
echo

if [ $menu -gt 1 ]
   then
       echo "   b Back     --- 返回上一级菜单"
#       echo
fi
echo "   h Help     --- 帮助信息"
echo "   x Exit     --- 退出"
echo

printf "Input your choice: "
read input
echo

Chkinput $1 "$input"
if [ $? -ne 0 ]
   then
        com=`echo $input | awk '{print $1}'`
        which $com >/dev/null 2>&1
        if [ $? -ne 0 ]
        then
             echo "ERR-1: 输入错误，请重新输入..."
        else
             eval $input
        fi
        Enter
        continue
fi

case "$input" in

      b) if [ $menu -ne 1 ]
            then
                 menu=`expr $menu - 1`
                 return
         fi
         ;;

      h) echo "                帮助信息"
         echo "───────────────────────"
         echo
         echo "    输入序号打开相应菜单/执行语句或脚本"
         echo
         echo "    序号后显示 + 号表示是有下级菜单"
         echo
         echo "    b 返回上一级菜单"
         echo "    h 显示帮助信息"
         echo "    x 退出" 
         echo
         echo "───────────────────────"
         Enter
         ;;

      x) exit
         ;;

      *) run=`awk -F"$MENUCHAR" 'NR=="'$input'"{print $2}' $1`
         if [ "`echo $run | awk -F"." '{print $NF}'`" = "$MENUTYPE" ]
            then
                 if [ ! -f $MENUPATH/$run ]
                    then
                         echo "ERR-0: 菜单文件 $MENUPATH/$run 不存在..."
                         Enter
                    else
                         Menu $MENUPATH/$run
                 fi
            else
                 eval $run
                 Enter
         fi
         ;;
esac

done

}


#================================#
#            M A I N             #
#================================#

MENUPATH=/root/git_project/hello-world/shell              # 默认菜单文件存放路径
MENUTYPE=menu                           # 菜单文件后缀名
MENUFILE=$MENUPATH/TOOL.$MENUTYPE       # 默认打开的菜单文件
MENUCHAR=%                              # 默认菜单文件分隔符


menu=0 # 第几级菜单
tree=0 # 默认不显示菜单树形图
verbose=0 # 默认菜单树形图不显示详细菜单信息

while getopts vtc:f:h OPTION
do
        case $OPTION in

                t)
                   tree=1
                   ;;
                v)
                   verbose=1
                   ;;
                f)
                   MENUFILE=$MENUPATH/`echo $OPTARG | sed "s/\.$MENUTYPE$//"`.$MENUTYPE
                   ;;
                h)
                   echo
                   echo "帮助信息"
                   echo
                   echo "Usage: `basename $0` [-t[-v]] [-h] [-c char] [-f file]"
                   echo
                   echo "-t, --Tree      显示菜单树形图"
                   echo
                   echo "-v, --Verbose   显示详细菜单树形图，需跟-t参数一起使用"
                   echo
                   echo "-c char         指定菜单文件中的分隔符"
                   echo
                   echo "-f file         打开指定菜单文件"
                   echo
                   echo "-h, --Help      显示帮助信息"
                   echo
                   exit
                   ;;
                *)
                   echo "请尝试执行\"`basename $0` -h\"来获取更多信息。"
                   exit 1
                   ;;
        esac
done

if [ $tree -eq 1 ]
   then
        Chkfile $MENUFILE
        tree=0
        echo
        echo "菜单列表"
        Tree $MENUFILE
   else
        Chkfile $MENUFILE
        Menu $MENUFILE
fi
