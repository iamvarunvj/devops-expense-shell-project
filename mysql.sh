#!/bin/bash

LOGS_FOLDER="/var/log/expense"
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME-$TIMESTAMP.log"
mkdir -p $LOGS_FOLDER

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
N="\e[0m"
Y="\e[33m"

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo -e "$R Please run this script with root priveleges $N" | tee -a $LOG_FILE
        exit 1
    fi
}

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 is...$R FAILED $N"  | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 is... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
}

echo "Script started executing at: $(date)" | tee -a $LOG_FILE

CHECK_ROOT

dnf list installed mysql-server &>>$LOG_FILE
if [ $? -ne 0 ]
then
    echo -e "mysql-server not installed going to install it" | tee -a $LOG_FILE
    dnf install mysql-server -y &>>$LOG_FILE
    VALIDATE $? "Installing MySQL Server"
else
    echo -e "$Y MySQL server is installed already $N" | tee -a $LOG_FILE
fi

systemctl enable mysqld &>>$LOG_FILE
VALIDATE $? "Enabled MySQL Server"

systemctl start mysqld &>>$LOG_FILE
VALIDATE $? "Started MySQL Server"

mysql -h mysql.iamdevops.fun -u root -pExpenseApp@1 -e 'show databases;' &>>$LOG_FILE
if [ $? -ne 0 ]
then
    echo "MySQL root password is not setup, setting now"
    mysql_secure_installation --set-root-pass ExpenseApp@1 &>>$LOG_FILE
    VALIDATE $? "Setting up MySQL Root Password "
else
    echo -e "MySQL root password is already setup..$Y SKIPPING $N" | tee -a $LOG_FILE
fi