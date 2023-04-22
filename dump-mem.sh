#!/bin/sh

# get all pid that the proc name matches
# except grep and this script itself
# $1: proc name strs
# return:
# pid if found
# -1 if not found
get_all_pids() {
	for proc in $1
	do
		local res=$(ps | grep $proc | grep -v grep | grep -v $0 | awk '{print $1}')
		if [ -z "$res" ]
		then
			echo -1
		else
			echo $res
		fi
	done
}

# dump all pss field of all pids
# $1: pids, ex. "[pid0]	[pid1]..."
dump_all_pss() {
	for pid in $1
	do
		if [ -d "/proc/$pid" ]
		then
			printf '%s\t' $(cat /proc/$pid/smaps_rollup | head -n3 | grep Pss | grep -Eo '[0-9]+')
		else
			printf '0\t'
		fi
	done
}

# append the mem usage vs timestamp to specific file
# $1: timestamp
# $2: mem usages [num1 num2 ...]
append_to_file(){
	echo -e "$2\t$3" >> pssdump.out
}

# clean the output files
# $1: proc name strs
clean_out(){
	rm pssdump.out
}

help(){
	echo "usage: $0 -m \"[str1] [str2] ... \""
}

while getopts ":hm:" option; do
	case $option in
		m)
			procs="$OPTARG";;
		h) #help
			help
			exit;;
		?)
			help
			exit;;
	esac
done

clean_out
pids=$(get_all_pids "$procs")
for proc in $procs
do
	printf '%s\t' "$proc" >> pssdump.out
done
printf '\n' >> pssdump.out

for pid in $pids
do
	printf '%s\t' "$pid" >> pssdump.out
done
printf '\n' >> pssdump.out

total_time=0
while true
do
	append_to_file $total_time "$(dump_all_pss "$pids")"
	sleep 1
	total_time=`expr $total_time + 1`
done
